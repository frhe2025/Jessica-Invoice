//
//  NotificationManager.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isEnabled: Bool = false
    
    private let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        center.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestPermissions() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isEnabled = granted
                self?.checkAuthorizationStatus()
                
                if granted {
                    self?.setupNotificationCategories()
                    print("✅ Notification permissions granted")
                } else if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Categories
    private func setupNotificationCategories() {
        // Invoice Paid Category
        let markAsViewedAction = UNNotificationAction(
            identifier: "MARK_AS_VIEWED",
            title: "Markera som sedd",
            options: []
        )
        
        let viewInvoiceAction = UNNotificationAction(
            identifier: "VIEW_INVOICE",
            title: "Visa faktura",
            options: [.foreground]
        )
        
        let invoicePaidCategory = UNNotificationCategory(
            identifier: "INVOICE_PAID",
            actions: [markAsViewedAction, viewInvoiceAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Invoice Reminder Category
        let sendReminderAction = UNNotificationAction(
            identifier: "SEND_REMINDER",
            title: "Skicka påminnelse",
            options: [.foreground]
        )
        
        let markAsOverdueAction = UNNotificationAction(
            identifier: "MARK_OVERDUE",
            title: "Markera som förfallen",
            options: []
        )
        
        let invoiceReminderCategory = UNNotificationCategory(
            identifier: "INVOICE_REMINDER",
            actions: [sendReminderAction, markAsOverdueAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([invoicePaidCategory, invoiceReminderCategory])
    }
    
    // MARK: - Send Notifications
    func sendInvoicePaidNotification(_ invoice: Invoice) {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Faktura Betald! 💰"
        content.body = "Faktura \(invoice.formattedNumber) från \(invoice.client.name) har betalats. Belopp: \(String(format: "%.0f", invoice.total)) kr"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "INVOICE_PAID"
        content.userInfo = [
            "invoiceId": invoice.id.uuidString,
            "type": "invoice_paid"
        ]
        
        let request = UNNotificationRequest(
            identifier: "invoice_paid_\(invoice.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error sending paid notification: \(error.localizedDescription)")
            } else {
                print("✅ Invoice paid notification sent for \(invoice.formattedNumber)")
            }
        }
    }
    
    func scheduleInvoiceReminder(_ invoice: Invoice, daysBefore: Int = 3) {
        guard isEnabled else { return }
        
        let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBefore,
            to: invoice.dueDate
        ) ?? invoice.dueDate
        
        // Only schedule if the reminder date is in the future
        guard reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Faktura Förfaller Snart ⏰"
        content.body = "Faktura \(invoice.formattedNumber) till \(invoice.client.name) förfaller om \(daysBefore) dagar. Belopp: \(String(format: "%.0f", invoice.total)) kr"
        content.sound = .default
        content.categoryIdentifier = "INVOICE_REMINDER"
        content.userInfo = [
            "invoiceId": invoice.id.uuidString,
            "type": "invoice_reminder"
        ]
        
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "invoice_reminder_\(invoice.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling reminder: \(error.localizedDescription)")
            } else {
                print("✅ Invoice reminder scheduled for \(invoice.formattedNumber)")
            }
        }
    }
    
    func sendOverdueInvoiceNotification(_ invoice: Invoice) {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Faktura Förfallen! 🚨"
        content.body = "Faktura \(invoice.formattedNumber) från \(invoice.client.name) har passerat förfallodatum. Belopp: \(String(format: "%.0f", invoice.total)) kr"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "INVOICE_REMINDER"
        content.userInfo = [
            "invoiceId": invoice.id.uuidString,
            "type": "invoice_overdue"
        ]
        
        let request = UNNotificationRequest(
            identifier: "invoice_overdue_\(invoice.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error sending overdue notification: \(error.localizedDescription)")
            } else {
                print("✅ Overdue notification sent for \(invoice.formattedNumber)")
            }
        }
    }
    
    // MARK: - Bulk Notifications
    func scheduleRemindersForAllPendingInvoices() async {
        do {
            let invoices = try await DataManager.shared.loadInvoices()
            let pendingInvoices = invoices.filter { $0.status == .sent && !$0.isOverdue }
            
            for invoice in pendingInvoices {
                scheduleInvoiceReminder(invoice)
            }
            
            print("✅ Scheduled reminders for \(pendingInvoices.count) invoices")
        } catch {
            print("❌ Error scheduling bulk reminders: \(error.localizedDescription)")
        }
    }
    
    func sendDailyReportNotification(totalOutstanding: Double, overdueCount: Int) {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Daglig Rapport 📊"
        
        if overdueCount > 0 {
            content.body = "Du har \(overdueCount) förfallna fakturor. Utestående: \(String(format: "%.0f", totalOutstanding)) kr"
        } else {
            content.body = "Utestående fakturor: \(String(format: "%.0f", totalOutstanding)) kr"
        }
        
        content.sound = .default
        content.userInfo = ["type": "daily_report"]
        
        let request = UNNotificationRequest(
            identifier: "daily_report_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error sending daily report: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notification Management
    func cancelNotification(for invoiceId: UUID) {
        let identifiers = [
            "invoice_reminder_\(invoiceId.uuidString)",
            "invoice_paid_\(invoiceId.uuidString)",
            "invoice_overdue_\(invoiceId.uuidString)"
        ]
        
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        print("✅ All notifications cancelled")
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
    
    func getDeliveredNotifications() async -> [UNNotification] {
        return await center.deliveredNotifications()
    }
    
    // MARK: - Badge Management
    func updateBadgeCount() async {
        do {
            let invoices = try await DataManager.shared.loadInvoices()
            let overdueCount = invoices.filter { $0.isOverdue }.count
            
            UIApplication.shared.applicationIconBadgeNumber = overdueCount
        } catch {
            print("❌ Error updating badge count: \(error.localizedDescription)")
        }
    }
    
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - Settings
    func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "MARK_AS_VIEWED":
            handleMarkAsViewed(userInfo: userInfo)
            
        case "VIEW_INVOICE":
            handleViewInvoice(userInfo: userInfo)
            
        case "SEND_REMINDER":
            handleSendReminder(userInfo: userInfo)
            
        case "MARK_OVERDUE":
            handleMarkAsOverdue(userInfo: userInfo)
            
        case UNNotificationDefaultActionIdentifier:
            handleDefaultAction(userInfo: userInfo)
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handleMarkAsViewed(userInfo: [AnyHashable: Any]) {
        // Mark notification as viewed in analytics or local storage
        print("📱 Notification marked as viewed")
    }
    
    private func handleViewInvoice(userInfo: [AnyHashable: Any]) {
        guard let invoiceIdString = userInfo["invoiceId"] as? String,
              let invoiceId = UUID(uuidString: invoiceIdString) else { return }
        
        // Navigate to specific invoice
        NotificationCenter.default.post(
            name: .navigateToInvoice,
            object: invoiceId
        )
    }
    
    private func handleSendReminder(userInfo: [AnyHashable: Any]) {
        // Open send reminder view
        NotificationCenter.default.post(
            name: .sendInvoiceReminder,
            object: userInfo["invoiceId"]
        )
    }
    
    private func handleMarkAsOverdue(userInfo: [AnyHashable: Any]) {
        guard let invoiceIdString = userInfo["invoiceId"] as? String,
              let invoiceId = UUID(uuidString: invoiceIdString) else { return }
        
        Task { @MainActor in
            // Update invoice status to overdue
            // This would typically be done through the InvoiceViewModel
        }
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        let notificationType = userInfo["type"] as? String ?? ""
        
        switch notificationType {
        case "invoice_paid":
            NotificationCenter.default.post(name: .navigateToHistory, object: nil)
            
        case "invoice_reminder", "invoice_overdue":
            NotificationCenter.default.post(name: .navigateToHistory, object: nil)
            
        case "daily_report":
            NotificationCenter.default.post(name: .navigateToHistory, object: nil)
            
        default:
            break
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToInvoice = Notification.Name("navigateToInvoice")
    static let navigateToHistory = Notification.Name("navigateToHistory")
    static let sendInvoiceReminder = Notification.Name("sendInvoiceReminder")
}
