//
//  DataManager.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import Foundation

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // File URLs
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var invoicesURL: URL {
        documentsDirectory.appendingPathComponent("invoices.json")
    }
    
    private var productsURL: URL {
        documentsDirectory.appendingPathComponent("products.json")
    }
    
    private var companyURL: URL {
        documentsDirectory.appendingPathComponent("company.json")
    }
    
    private var backupDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("Backups")
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    private init() {
        setupEncoder()
    }
    
    private func setupEncoder() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }
    
    // MARK: - Data Loading
    func loadData() {
        Task {
            do {
                _ = try await loadCompany()
                _ = try await loadInvoices()
                _ = try await loadProducts()
                print("✅ All data loaded successfully")
            } catch {
                print("❌ Error loading data: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Invoice Operations
    func loadInvoices() async throws -> [Invoice] {
        guard fileManager.fileExists(atPath: invoicesURL.path) else {
            // Return sample data for first run
            return createSampleInvoices()
        }
        
        do {
            let data = try Data(contentsOf: invoicesURL)
            let invoices = try decoder.decode([Invoice].self, from: data)
            print("✅ Loaded \(invoices.count) invoices")
            return invoices
        } catch {
            print("❌ Error loading invoices: \(error)")
            throw DataError.loadingFailed("invoices")
        }
    }
    
    func saveInvoices(_ invoices: [Invoice]) async throws {
        do {
            let data = try encoder.encode(invoices)
            try data.write(to: invoicesURL)
            print("✅ Saved \(invoices.count) invoices")
            
            // Create automatic backup
            try await createBackup(invoices: invoices)
        } catch {
            print("❌ Error saving invoices: \(error)")
            throw DataError.savingFailed("invoices")
        }
    }
    
    // MARK: - Product Operations
    func loadProducts() async throws -> [Product] {
        guard fileManager.fileExists(atPath: productsURL.path) else {
            // Return sample data for first run
            return createSampleProducts()
        }
        
        do {
            let data = try Data(contentsOf: productsURL)
            let products = try decoder.decode([Product].self, from: data)
            print("✅ Loaded \(products.count) products")
            return products
        } catch {
            print("❌ Error loading products: \(error)")
            throw DataError.loadingFailed("products")
        }
    }
    
    func saveProducts(_ products: [Product]) async throws {
        do {
            let data = try encoder.encode(products)
            try data.write(to: productsURL)
            print("✅ Saved \(products.count) products")
        } catch {
            print("❌ Error saving products: \(error)")
            throw DataError.savingFailed("products")
        }
    }
    
    // MARK: - Company Operations
    func loadCompany() async throws -> Company {
        guard fileManager.fileExists(atPath: companyURL.path) else {
            // Return default company for first run
            return createDefaultCompany()
        }
        
        do {
            let data = try Data(contentsOf: companyURL)
            let company = try decoder.decode(Company.self, from: data)
            print("✅ Loaded company data")
            return company
        } catch {
            print("❌ Error loading company: \(error)")
            throw DataError.loadingFailed("company")
        }
    }
    
    func saveCompany(_ company: Company) async throws {
        do {
            let data = try encoder.encode(company)
            try data.write(to: companyURL)
            print("✅ Saved company data")
        } catch {
            print("❌ Error saving company: \(error)")
            throw DataError.savingFailed("company")
        }
    }
    
    // MARK: - Backup Operations
    private func createBackup(invoices: [Invoice]? = nil) async throws {
        let timestamp = DateFormatter.backupFormatter.string(from: Date())
        let backupURL = backupDirectory.appendingPathComponent("backup_\(timestamp).json")
        
        let backupData = BackupData(
            timestamp: Date(),
            invoices: invoices ?? (try await loadInvoices()),
            products: try await loadProducts(),
            company: try await loadCompany()
        )
        
        let data = try encoder.encode(backupData)
        try data.write(to: backupURL)
        
        // Clean old backups (keep last 10)
        try cleanOldBackups()
        
        print("✅ Created backup: \(backupURL.lastPathComponent)")
    }
    
    private func cleanOldBackups() throws {
        let backupFiles = try fileManager.contentsOfDirectory(at: backupDirectory,
                                                             includingPropertiesForKeys: [.creationDateKey],
                                                             options: .skipsHiddenFiles)
        
        let sortedBackups = backupFiles.sorted { url1, url2 in
            let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate
            let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate
            return (date1 ?? Date.distantPast) > (date2 ?? Date.distantPast)
        }
        
        // Remove old backups, keeping the 10 most recent
        for backup in sortedBackups.dropFirst(10) {
            try fileManager.removeItem(at: backup)
        }
    }
    
    func restoreFromBackup(_ backupURL: URL) async throws {
        do {
            let data = try Data(contentsOf: backupURL)
            let backup = try decoder.decode(BackupData.self, from: data)
            
            try await saveCompany(backup.company)
            try await saveInvoices(backup.invoices)
            try await saveProducts(backup.products)
            
            print("✅ Restored from backup: \(backupURL.lastPathComponent)")
        } catch {
            throw DataError.restoreFailed
        }
    }
    
    func getBackupFiles() -> [URL] {
        do {
            let backupFiles = try fileManager.contentsOfDirectory(at: backupDirectory,
                                                                 includingPropertiesForKeys: [.creationDateKey],
                                                                 options: .skipsHiddenFiles)
            
            return backupFiles.sorted { url1, url2 in
                let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate
                let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate
                return (date1 ?? Date.distantPast) > (date2 ?? Date.distantPast)
            }
        } catch {
            print("❌ Error getting backup files: \(error)")
            return []
        }
    }
    
    // MARK: - Data Migration
    func migrateDataIfNeeded() async throws {
        let userDefaults = UserDefaults.standard
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let lastVersion = userDefaults.string(forKey: "lastAppVersion")
        
        guard lastVersion != currentVersion else { return }
        
        // Perform migration based on version
        if lastVersion == nil {
            // First install - create sample data
            print("🔄 First install detected, creating sample data")
            let _ = try await loadInvoices() // This will create sample data
            let _ = try await loadProducts()
            let _ = try await loadCompany()
        }
        
        // Add more migrations here for future versions
        
        userDefaults.set(currentVersion, forKey: "lastAppVersion")
        print("✅ Data migration completed to version \(currentVersion)")
    }
    
    // MARK: - Data Cleanup
    func clearAllData() async throws {
        do {
            if fileManager.fileExists(atPath: invoicesURL.path) {
                try fileManager.removeItem(at: invoicesURL)
            }
            
            if fileManager.fileExists(atPath: productsURL.path) {
                try fileManager.removeItem(at: productsURL)
            }
            
            if fileManager.fileExists(atPath: companyURL.path) {
                try fileManager.removeItem(at: companyURL)
            }
            
            // Clear backups
            if fileManager.fileExists(atPath: backupDirectory.path) {
                try fileManager.removeItem(at: backupDirectory)
            }
            
            print("✅ All data cleared")
        } catch {
            throw DataError.clearingFailed
        }
    }
    
    // MARK: - Sample Data Creation
    private func createSampleInvoices() -> [Invoice] {
        let sampleClient1 = Client(
            name: "Acme AB",
            contactPerson: "Anna Andersson",
            email: "anna@acme.se",
            phone: "08-123 45 67",
            address: Address(
                street: "Storgatan 1",
                postalCode: "111 22",
                city: "Stockholm"
            ),
            organizationNumber: "556789-1234"
        )
        
        let sampleClient2 = Client(
            name: "TechCorp Solutions",
            contactPerson: "Erik Eriksson",
            email: "erik@techcorp.se",
            phone: "08-987 65 43",
            address: Address(
                street: "Teknikgatan 5",
                postalCode: "164 40",
                city: "Kista"
            ),
            organizationNumber: "559876-5432"
        )
        
        return [
            Invoice(
                number: "2025-001",
                date: Date(),
                client: sampleClient1,
                items: [
                    InvoiceItem(description: "Webbutveckling", quantity: 40, unit: "timmar", unitPrice: 1200),
                    InvoiceItem(description: "Design", quantity: 1, unit: "projekt", unitPrice: 5000)
                ],
                status: .sent
            ),
            Invoice(
                number: "2025-002",
                date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                client: sampleClient2,
                items: [
                    InvoiceItem(description: "Konsultation", quantity: 8, unit: "timmar", unitPrice: 1500)
                ],
                status: .paid
            )
        ]
    }
    
    private func createSampleProducts() -> [Product] {
        return [
            Product(name: "Webbutveckling", description: "Frontend och backend utveckling", price: 1200, unit: "timme", category: .development),
            Product(name: "UI/UX Design", description: "Användarupplevelse och gränssnitt", price: 1000, unit: "timme", category: .design),
            Product(name: "Konsultation", description: "Teknisk rådgivning", price: 1500, unit: "timme", category: .consultation),
            Product(name: "Hosting", description: "Webbhotell och domän", price: 299, unit: "månad", category: .service)
        ]
    }
    
    private func createDefaultCompany() -> Company {
        return Company(
            name: "Jessica AB",
            organizationNumber: "559999-9999",
            address: Address(
                street: "Storgatan 1",
                postalCode: "123 45",
                city: "Stockholm"
            ),
            email: "jessica@example.com",
            phone: "08-123 45 67"
        )
    }
}

// MARK: - Backup Data Structure
struct BackupData: Codable {
    let timestamp: Date
    let invoices: [Invoice]
    let products: [Product]
    let company: Company
}

// MARK: - Data Errors
enum DataError: LocalizedError {
    case loadingFailed(String)
    case savingFailed(String)
    case restoreFailed
    case clearingFailed
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let type):
            return "Kunde inte ladda \(type)"
        case .savingFailed(let type):
            return "Kunde inte spara \(type)"
        case .restoreFailed:
            return "Kunde inte återställa från backup"
        case .clearingFailed:
            return "Kunde inte rensa data"
        }
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let backupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
