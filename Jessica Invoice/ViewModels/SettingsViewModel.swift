//
//  SettingsViewModel.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var company: Company = Company()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasUnsavedChanges: Bool = false
    
    // App Settings
    @Published var enableNotifications: Bool = true {
        didSet { saveAppSettings() }
    }
    @Published var enableFaceID: Bool = false {
        didSet { saveAppSettings() }
    }
    @Published var enableDarkMode: Bool = false {
        didSet { saveAppSettings() }
    }
    @Published var preferredLanguage: String = "sv" {
        didSet { saveAppSettings() }
    }
    
    // Invoice Settings
    @Published var defaultInvoiceTemplate: String = "standard" {
        didSet { saveAppSettings() }
    }
    @Published var autoSaveInterval: Int = 300 {
        didSet { saveAppSettings() }
    }
    @Published var enableEmailReminders: Bool = true {
        didSet { saveAppSettings() }
    }
    @Published var reminderDaysBefore: Int = 3 {
        didSet { saveAppSettings() }
    }
    
    private let dataManager = DataManager.shared
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadCompanyData()
        loadAppSettings()
    }
    
    // MARK: - Company Data
    func loadCompanyData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let loadedCompany = try await dataManager.loadCompany()
                self.company = loadedCompany
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func saveCompanyData() async throws {
        try await dataManager.saveCompany(company)
        hasUnsavedChanges = false
    }
    
    func updateCompanyField<T>(_ keyPath: WritableKeyPath<Company, T>, value: T) {
        company[keyPath: keyPath] = value
        hasUnsavedChanges = true
    }
    
    // MARK: - App Settings
    private func loadAppSettings() {
        enableNotifications = userDefaults.bool(forKey: "enableNotifications")
        enableFaceID = userDefaults.bool(forKey: "enableFaceID")
        enableDarkMode = userDefaults.bool(forKey: "enableDarkMode")
        preferredLanguage = userDefaults.string(forKey: "preferredLanguage") ?? "sv"
        defaultInvoiceTemplate = userDefaults.string(forKey: "defaultInvoiceTemplate") ?? "standard"
        autoSaveInterval = userDefaults.integer(forKey: "autoSaveInterval") != 0 ?
                          userDefaults.integer(forKey: "autoSaveInterval") : 300
        enableEmailReminders = userDefaults.bool(forKey: "enableEmailReminders")
        reminderDaysBefore = userDefaults.integer(forKey: "reminderDaysBefore") != 0 ?
                           userDefaults.integer(forKey: "reminderDaysBefore") : 3
    }
    
    private func saveAppSettings() {
        userDefaults.set(enableNotifications, forKey: "enableNotifications")
        userDefaults.set(enableFaceID, forKey: "enableFaceID")
        userDefaults.set(enableDarkMode, forKey: "enableDarkMode")
        userDefaults.set(preferredLanguage, forKey: "preferredLanguage")
        userDefaults.set(defaultInvoiceTemplate, forKey: "defaultInvoiceTemplate")
        userDefaults.set(autoSaveInterval, forKey: "autoSaveInterval")
        userDefaults.set(enableEmailReminders, forKey: "enableEmailReminders")
        userDefaults.set(reminderDaysBefore, forKey: "reminderDaysBefore")
        
        // Apply settings immediately
        Task { await applySettings() }
    }
    
    private func applySettings() async {
        // Request notification permissions if enabled
        if enableNotifications {
            await NotificationManager.shared.requestPermissions()
        }
        
        // Apply dark mode setting
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = enableDarkMode ? .dark : .light
        }
    }
    
    // MARK: - Validation
    func validateCompany() -> [String] {
        var errors: [String] = []
        
        if company.name.isEmpty {
            errors.append("Företagsnamn saknas")
        }
        
        if company.organizationNumber.isEmpty {
            errors.append("Organisationsnummer saknas")
        } else if !isValidOrganizationNumber(company.organizationNumber) {
            errors.append("Organisationsnummer har fel format")
        }
        
        if company.address.street.isEmpty {
            errors.append("Gatuadress saknas")
        }
        
        if company.address.postalCode.isEmpty {
            errors.append("Postnummer saknas")
        } else if !isValidPostalCode(company.address.postalCode) {
            errors.append("Postnummer har fel format")
        }
        
        if company.address.city.isEmpty {
            errors.append("Stad saknas")
        }
        
        if !company.email.isEmpty && !isValidEmail(company.email) {
            errors.append("E-postadress har fel format")
        }
        
        if !company.vatNumber.isEmpty && !isValidVATNumber(company.vatNumber) {
            errors.append("VAT-nummer har fel format")
        }
        
        return errors
    }
    
    private func isValidOrganizationNumber(_ number: String) -> Bool {
        let pattern = "^\\d{6}-\\d{4}$|^\\d{10}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: number)
    }
    
    private func isValidPostalCode(_ code: String) -> Bool {
        let pattern = "^\\d{3}\\s?\\d{2}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: code)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func isValidVATNumber(_ vat: String) -> Bool {
        let pattern = "^SE\\d{12}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: vat)
    }
    
    // MARK: - Data Export/Import
    func exportAllData() async throws -> Data {
        let invoices = try await dataManager.loadInvoices()
        let products = try await dataManager.loadProducts()
        
        let exportData = ExportData(
            company: company,
            invoices: invoices,
            products: products,
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
        
        return try JSONEncoder().encode(exportData)
    }
    
    func importAllData(_ data: Data) async throws {
        let importData = try JSONDecoder().decode(ExportData.self, from: data)
        
        // Update company data
        company = importData.company
        
        // Save all data
        try await dataManager.saveCompany(company)
        try await dataManager.saveInvoices(importData.invoices)
        try await dataManager.saveProducts(importData.products)
        
        hasUnsavedChanges = false
    }
    
    // MARK: - App Reset
    func resetAllData() async throws {
        // Clear all stored data
        company = Company()
        try await dataManager.clearAllData()
        
        // Reset app settings to defaults
        userDefaults.removeObject(forKey: "enableNotifications")
        userDefaults.removeObject(forKey: "enableFaceID")
        userDefaults.removeObject(forKey: "enableDarkMode")
        userDefaults.removeObject(forKey: "preferredLanguage")
        userDefaults.removeObject(forKey: "defaultInvoiceTemplate")
        userDefaults.removeObject(forKey: "autoSaveInterval")
        userDefaults.removeObject(forKey: "enableEmailReminders")
        userDefaults.removeObject(forKey: "reminderDaysBefore")
        
        // Reload defaults
        loadAppSettings()
        hasUnsavedChanges = false
    }
    
    // MARK: - Backup & Restore
    func createBackup() async throws -> Data {
        return try await exportAllData()
    }
    
    func restoreFromBackup(_ data: Data) async throws {
        try await importAllData(data)
    }
    
    // MARK: - App Information
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Jessica Invoice"
    }
    
    // MARK: - Feature Flags
    var isPremiumUser: Bool {
        // This could be connected to in-app purchases
        userDefaults.bool(forKey: "isPremiumUser")
    }
    
    var hasCompletedOnboarding: Bool {
        userDefaults.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        userDefaults.set(true, forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Support Functions
    func generateSupportReport() -> String {
        let deviceInfo = """
        App: \(appName) v\(appVersion) (\(buildNumber))
        Device: \(UIDevice.current.model)
        iOS: \(UIDevice.current.systemVersion)
        Company Setup: \(company.hasCompletedSetup ? "Complete" : "Incomplete")
        Premium: \(isPremiumUser ? "Yes" : "No")
        Notifications: \(enableNotifications ? "Enabled" : "Disabled")
        """
        
        return deviceInfo
    }
    
    // MARK: - Privacy
    func clearAnalyticsData() {
        // Clear any analytics or tracking data
        userDefaults.removeObject(forKey: "analyticsOptIn")
        userDefaults.removeObject(forKey: "crashReportingOptIn")
    }
    
    var analyticsEnabled: Bool {
        get { userDefaults.bool(forKey: "analyticsOptIn") }
        set { userDefaults.set(newValue, forKey: "analyticsOptIn") }
    }
    
    var crashReportingEnabled: Bool {
        get { userDefaults.bool(forKey: "crashReportingOptIn") }
        set { userDefaults.set(newValue, forKey: "crashReportingOptIn") }
    }
}

// MARK: - Export Data Structure
struct ExportData: Codable {
    let company: Company
    let invoices: [Invoice]
    let products: [Product]
    let exportDate: Date
    let appVersion: String
}

