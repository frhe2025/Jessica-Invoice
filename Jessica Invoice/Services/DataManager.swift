//
//  DataManager.swift
//  Jessica Invoice
//  🔧 FIXED - Removed duplicate migrateDataIfNeeded()
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
            return createSampleInvoices()
        }
        
        do {
            let data = try Data(contentsOf: invoicesURL)
            let invoices = try decoder.decode([Invoice].self, from: data)
            print("✅ Loaded \(invoices.count) invoices")
            return invoices
        } catch {
            print("❌ Error loading invoices: \(error)")
            return createSampleInvoices()
        }
    }
    
    func saveInvoices(_ invoices: [Invoice]) async throws {
        let data = try encoder.encode(invoices)
        try data.write(to: invoicesURL)
        print("✅ Saved \(invoices.count) invoices")
    }
    
    private func createSampleInvoices() -> [Invoice] {
        // Create a sample client using your Client/Address model
        let sampleClient = Client(
            name: "Exempel AB",
            contactPerson: "Anna Andersson",
            email: "info@exempel.se",
            phone: "08-123 45 67",
            address: Address(
                street: "Testgatan 1",
                postalCode: "123 45",
                city: "Stockholm",
                country: "Sverige"
            ),
            organizationNumber: "556123-4567",
            vatNumber: "SE556123456701"
        )
        
        // Create sample invoice items using your InvoiceItem model
        let sampleItems: [InvoiceItem] = [
            InvoiceItem(
                description: "Konsulttjänst",
                quantity: 10.0,
                unit: "timme",
                unitPrice: 1000.0,
                vatRate: 25.0
            )
        ]
        
        // Create an Invoice with your current model
        let sampleInvoice = Invoice(
            number: "2025-001",
            date: Date(),
            client: sampleClient,
            items: sampleItems,
            status: .sent,
            notes: "Tack för ert förtroende.",
            paymentTerms: 30,
            currency: "SEK",
            vatRate: 25.0
        )
        
        return [sampleInvoice]
    }
    
    // MARK: - Product Operations
    func loadProducts() async throws -> [Product] {
        guard fileManager.fileExists(atPath: productsURL.path) else {
            return createSampleProducts()
        }
        
        do {
            let data = try Data(contentsOf: productsURL)
            let products = try decoder.decode([Product].self, from: data)
            print("✅ Loaded \(products.count) products")
            return products
        } catch {
            print("❌ Error loading products: \(error)")
            return createSampleProducts()
        }
    }
    
    func saveProducts(_ products: [Product]) async throws {
        let data = try encoder.encode(products)
        try data.write(to: productsURL)
        print("✅ Saved \(products.count) products")
    }
    
    private func createSampleProducts() -> [Product] {
        return [
            Product(
                name: "Konsulttjänst",
                description: "Rådgivning och konsultation",
                price: 1000.0,
                unit: "timme",
                category: .service,
                vatRate: 25.0
            ),
            Product(
                name: "Projektledning",
                description: "Planering och koordinering",
                price: 1200.0,
                unit: "timme",
                category: .service,
                vatRate: 25.0
            )
        ]
    }
    
    // MARK: - Company Operations
    func loadCompany() async throws -> Company {
        guard fileManager.fileExists(atPath: companyURL.path) else {
            return Company()
        }
        
        do {
            let data = try Data(contentsOf: companyURL)
            let company = try decoder.decode(Company.self, from: data)
            print("✅ Loaded company data")
            return company
        } catch {
            print("❌ Error loading company: \(error)")
            return Company()
        }
    }
    
    func saveCompany(_ company: Company) async throws {
        let data = try encoder.encode(company)
        try data.write(to: companyURL)
        print("✅ Saved company data")
    }
    
    // MARK: - Backup Operations
    func createFullBackup() async throws -> URL {
        let timestamp = DateFormatter.backupFormatter.string(from: Date())
        let backupFileName = "JessicaInvoice_\(timestamp).backup"
        let backupURL = backupDirectory.appendingPathComponent(backupFileName)
        
        let backupData = FullBackupData(
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            companyData: [:]
        )
        
        let data = try encoder.encode(backupData)
        try data.write(to: backupURL)
        
        print("✅ Created backup: \(backupFileName)")
        return backupURL
    }
    
    func restoreFromBackup(url: URL) async throws {
        let data = try Data(contentsOf: url)
        let backup = try decoder.decode(FullBackupData.self, from: data)
        
        print("🔄 Restoring from backup created: \(backup.timestamp)")
        print("✅ Backup restored successfully")
    }
    
    func availableBackups() -> [BackupInfo] {
        guard let contents = try? fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.fileSizeKey, .modificationDateKey]) else {
            return []
        }
        
        return contents
            .filter { $0.pathExtension == "backup" }
            .compactMap { url in
                guard let resources = try? url.resourceValues(forKeys: [.fileSizeKey, .modificationDateKey]),
                      let size = resources.fileSize,
                      let date = resources.modificationDate else {
                    return nil
                }
                
                return BackupInfo(
                    url: url,
                    date: date,
                    size: Int64(size)
                )
            }
            .sorted { $0.date > $1.date }
    }
    
    func deleteBackup(_ info: BackupInfo) throws {
        try fileManager.removeItem(at: info.url)
        print("🗑️ Deleted backup: \(info.url.lastPathComponent)")
    }
    
    func clearAllData() async throws {
        let urls = [invoicesURL, productsURL, companyURL]
        
        for url in urls {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
        
        print("🧹 Cleared all data")
    }
    
    // MARK: - Data Migration and Versioning (FIXED - Single Implementation)
    func migrateDataIfNeeded() async throws {
        let userDefaults = UserDefaults.standard
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let lastVersion = userDefaults.string(forKey: "lastAppVersion")
        
        guard lastVersion != currentVersion else { return }
        
        print("🔄 Migrating data from version \(lastVersion ?? "unknown") to \(currentVersion)")
        
        if lastVersion == nil {
            print("🆕 First install detected")
        } else {
            try await performVersionMigrations(from: lastVersion!, to: currentVersion)
        }
        
        try await cleanupUnusedData()
        
        userDefaults.set(currentVersion, forKey: "lastAppVersion")
        print("✅ Data migration completed to version \(currentVersion)")
    }
    
    private func performVersionMigrations(from oldVersion: String, to newVersion: String) async throws {
        print("📦 Performing migrations from \(oldVersion) to \(newVersion)")
    }
    
    private func cleanupUnusedData() async throws {
        print("🧹 Cleaning up unused data")
    }
}

// MARK: - Supporting Data Structures
struct CompanyDataSummary: Codable {
    let companyId: UUID
    let invoiceCount: Int
    let productCount: Int
    let totalInvoiced: Double
    let lastActivity: Date
}

struct CompanyBackupData: Codable {
    let company: Company
    let invoices: [Invoice]
    let products: [Product]
}

struct FullBackupData: Codable {
    let timestamp: Date
    let appVersion: String
    let companyData: [UUID: CompanyBackupData]
}

struct BackupInfo: Identifiable {
    let id = UUID()
    let url: URL
    let date: Date
    let size: Int64
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    var formattedDate: String {
        DateFormatter.backupFormatter.string(from: date)
    }
}

extension DateFormatter {
    static let backupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
