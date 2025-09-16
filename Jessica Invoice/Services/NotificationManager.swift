//
//  NotificationManager.swift
//  Jessica Invoice
//  🔧 FIXED - Protocol compliance issues resolved
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isEnabled = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Permission Handling
    func requestPermissions() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                isEnabled = granted
            }
            await checkAuthorizationStatus()
        } catch {
            print("❌ Notification permission error: \(error)")
        }
    }
    
    func checkAuthorizationStatus() {
        Task {
            let settings = await center.notificationSettings()
            await MainActor.run {
                authorizationStatus = settings.authorizationStatus
                isEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Badge Management
    func updateBadgeCount() async {
        guard isEnabled else { return }
        
        let pendingRequests = await center.pendingNotificationRequests()
        let badgeCount = pendingRequests.count
        
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = badgeCount
        }
    }
    
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - Invoice Notifications
    func scheduleInvoiceReminder(
        for invoice: Invoice,
        daysBefore: Int = 3
    ) async {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Faktura förfaller snart"
        content.body = "Faktura \(invoice.invoiceNumber) från \(invoice.customer.name) förfaller om \(daysBefore) dagar"
        content.categoryIdentifier = "INVOICE_REMINDER"
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        // Calculate notification date
        let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBefore,
            to: invoice.dueDate
        ) ?? Date()
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: notificationDate
            ),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "invoice_reminder_\(invoice.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("✅ Scheduled reminder for invoice \(invoice.invoiceNumber)")
        } catch {
            print("❌ Failed to schedule reminder: \(error)")
        }
    }
    
    func scheduleOverdueNotification(for invoice: Invoice) async {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Försenad faktura"
        content.body = "Faktura \(invoice.invoiceNumber) från \(invoice.customer.name) är nu försenad"
        content.categoryIdentifier = "OVERDUE_INVOICE"
        content.sound = .defaultCritical
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: invoice.dueDate
            ),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "overdue_\(invoice.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("✅ Scheduled overdue notification for invoice \(invoice.invoiceNumber)")
        } catch {
            print("❌ Failed to schedule overdue notification: \(error)")
        }
    }
    
    func cancelInvoiceNotifications(for invoiceId: UUID) async {
        let identifiers = [
            "invoice_reminder_\(invoiceId.uuidString)",
            "overdue_\(invoiceId.uuidString)"
        ]
        
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Cancelled notifications for invoice \(invoiceId)")
    }
    
    // MARK: - Bulk Operations
    func scheduleRemindersForAllPendingInvoices() async {
        // This would typically load invoices from data manager
        // For now, we'll just clear existing notifications
        await clearAllNotifications()
    }
    
    func clearAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        clearBadge()
        print("🧹 Cleared all notifications")
    }
    
    // MARK: - Notification Actions
    private func setupNotificationActions() {
        // View Invoice Action
        let viewAction = UNNotificationAction(
            identifier: "VIEW_INVOICE",
            title: "Visa faktura",
            options: [.foreground]
        )
        
        // Mark as Paid Action
        let markPaidAction = UNNotificationAction(
            identifier: "MARK_PAID",
            title: "Markera som betald",
            options: []
        )
        
        // Invoice Reminder Category
        let reminderCategory = UNNotificationCategory(
            identifier: "INVOICE_REMINDER",
            actions: [viewAction, markPaidAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Overdue Invoice Category
        let overdueCategory = UNNotificationCategory(
            identifier: "OVERDUE_INVOICE",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([reminderCategory, overdueCategory])
    }
}

// MARK: - UNUserNotificationCenterDelegate (FIXED - Protocol compliance)
extension NotificationManager: @preconcurrency UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            await handleNotificationResponse(response)
        }
        completionHandler()
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "VIEW_INVOICE":
            await handleViewInvoiceAction(notificationId: identifier)
        case "MARK_PAID":
            await handleMarkPaidAction(notificationId: identifier)
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            await handleDefaultAction(notificationId: identifier)
        default:
            break
        }
    }
    
    private func handleViewInvoiceAction(notificationId: String) async {
        print("📱 View invoice action for: \(notificationId)")
        // Navigate to invoice detail view
    }
    
    private func handleMarkPaidAction(notificationId: String) async {
        print("💰 Mark paid action for: \(notificationId)")
        // Update invoice status to paid
    }
    
    private func handleDefaultAction(notificationId: String) async {
        print("👆 Default action for: \(notificationId)")
        // Default behavior when notification is tapped
    }
}

// MARK: - Supporting Types
extension Invoice {
    var isOverdue: Bool {
        status != .paid && status != .cancelled && dueDate < Date()
    }
    
    var daysToDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
}

// MARK: - Mock Invoice for Preview/Testing
#if DEBUG
extension Invoice {
    static var sampleInvoice: Invoice {
        Invoice(
            invoiceNumber: "2025-001",
            customer: Customer(
                name: "Test AB",
                organizationNumber: "556123-4567",
                address: Address(
                    street: "Testgatan 1",
                    postalCode: "123 45",
                    city: "Stockholm",
                    country: "Sverige"
                )
            ),
            issueDate: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            items: [
                InvoiceItem(
                    description: "Test tjänst",
                    quantity: 1,
                    unitPrice: 1000,
                    vatRate: 25
                )
            ]
        )
    }
}
#endif
