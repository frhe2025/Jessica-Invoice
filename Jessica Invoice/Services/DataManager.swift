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

//
//  DataManager Extensions for Multi-Company Support
//  📁 LÄGG TILL I SLUTET AV BEFINTLIG FIL: Services/DataManager.swift
//

import Foundation

// MARK: - Multi-Company Extensions for DataManager

extension DataManager {
    
    // MARK: - Company URLs
    
    private var companiesURL: URL {
        documentsDirectory.appendingPathComponent("companies.json")
    }
    
    private func companyDataDirectory(for companyId: UUID) -> URL {
        let companyDir = documentsDirectory
            .appendingPathComponent("Companies")
            .appendingPathComponent(companyId.uuidString)
        
        // Ensure directory exists
        try? fileManager.createDirectory(at: companyDir, withIntermediateDirectories: true)
        return companyDir
    }
    
    private func invoicesURL(for company: Company) -> URL {
        companyDataDirectory(for: company.id).appendingPathComponent("invoices.json")
    }
    
    private func productsURL(for company: Company) -> URL {
        companyDataDirectory(for: company.id).appendingPathComponent("products.json")
    }
    
    // MARK: - Company Operations
    
    func loadCompanies() async throws -> [Company] {
        // Check if we need to migrate from old single company format
        if !fileManager.fileExists(atPath: companiesURL.path) {
            return try await migrateFromLegacyFormat()
        }
        
        do {
            let data = try Data(contentsOf: companiesURL)
            let companies = try decoder.decode([Company].self, from: data)
            print("✅ Loaded \(companies.count) companies")
            return companies
        } catch {
            print("❌ Error loading companies: \(error)")
            // If loading fails, create default companies
            return createDefaultCompanies()
        }
    }
    
    func saveCompanies(_ companies: [Company]) async throws {
        do {
            let data = try encoder.encode(companies)
            try data.write(to: companiesURL)
            print("✅ Saved \(companies.count) companies")
            
            // Create backup
            try await createCompaniesBackup(companies)
        } catch {
            print("❌ Error saving companies: \(error)")
            throw DataError.savingFailed("companies")
        }
    }
    
    // MARK: - Company-Specific Data Operations
    
    func loadInvoices(for company: Company) async throws -> [Invoice] {
        let invoicesPath = invoicesURL(for: company)
        
        guard fileManager.fileExists(atPath: invoicesPath.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: invoicesPath)
            let invoices = try decoder.decode([Invoice].self, from: data)
            print("✅ Loaded \(invoices.count) invoices for \(company.name)")
            return invoices
        } catch {
            print("❌ Error loading invoices for \(company.name): \(error)")
            throw DataError.loadingFailed("company invoices")
        }
    }
    
    func saveInvoices(_ invoices: [Invoice], for company: Company) async throws {
        let invoicesPath = invoicesURL(for: company)
        
        do {
            let data = try encoder.encode(invoices)
            try data.write(to: invoicesPath)
            print("✅ Saved \(invoices.count) invoices for \(company.name)")
            
            // Create backup
            try await createInvoicesBackup(invoices, for: company)
        } catch {
            print("❌ Error saving invoices for \(company.name): \(error)")
            throw DataError.savingFailed("company invoices")
        }
    }
    
    func loadProducts(for company: Company) async throws -> [Product] {
        let productsPath = productsURL(for: company)
        
        guard fileManager.fileExists(atPath: productsPath.path) else {
            return createDefaultProducts(for: company)
        }
        
        do {
            let data = try Data(contentsOf: productsPath)
            let products = try decoder.decode([Product].self, from: data)
            print("✅ Loaded \(products.count) products for \(company.name)")
            return products
        } catch {
            print("❌ Error loading products for \(company.name): \(error)")
            throw DataError.loadingFailed("company products")
        }
    }
    
    func saveProducts(_ products: [Product], for company: Company) async throws {
        let productsPath = productsURL(for: company)
        
        do {
            let data = try encoder.encode(products)
            try data.write(to: productsPath)
            print("✅ Saved \(products.count) products for \(company.name)")
        } catch {
            print("❌ Error saving products for \(company.name): \(error)")
            throw DataError.savingFailed("company products")
        }
    }
    
    // MARK: - Data Existence Checks
    
    func hasDataForCompany(_ company: Company) async throws -> Bool {
        let invoices = try await loadInvoices(for: company)
        let products = try await loadProducts(for: company)
        return !invoices.isEmpty || !products.isEmpty
    }
    
    func getDataSummaryForCompany(_ company: Company) async throws -> CompanyDataSummary {
        let invoices = try await loadInvoices(for: company)
        let products = try await loadProducts(for: company)
        
        return CompanyDataSummary(
            companyId: company.id,
            invoiceCount: invoices.count,
            productCount: products.filter { $0.isActive }.count,
            totalInvoiced: invoices.reduce(0) { $0 + $1.total },
            lastActivity: max(
                invoices.map { $0.date }.max() ?? Date.distantPast,
                products.map { $0.createdDate }.max() ?? Date.distantPast
            )
        )
    }
    
    // MARK: - Migration from Legacy Format
    
    private func migrateFromLegacyFormat() async throws -> [Company] {
        print("🔄 Migrating from legacy single-company format...")
        
        var companies: [Company] = []
        
        // Check if old company file exists
        if fileManager.fileExists(atPath: companyURL.path) {
            do {
                let data = try Data(contentsOf: companyURL)
                var legacyCompany = try decoder.decode(Company.self, from: data)
                legacyCompany.isPrimaryCompany = true
                
                companies.append(legacyCompany)
                
                // Migrate invoices and products for this company
                try await migrateInvoicesForCompany(legacyCompany)
                try await migrateProductsForCompany(legacyCompany)
                
                // Remove old files after successful migration
                try fileManager.removeItem(at: companyURL)
                if fileManager.fileExists(atPath: invoicesURL.path) {
                    try fileManager.removeItem(at: invoicesURL)
                }
                if fileManager.fileExists(atPath: productsURL.path) {
                    try fileManager.removeItem(at: productsURL)
                }
                
                print("✅ Migrated legacy company: \(legacyCompany.name)")
            } catch {
                print("❌ Error migrating legacy company: \(error)")
            }
        }
        
        // If no companies after migration, create defaults
        if companies.isEmpty {
            companies = createDefaultCompanies()
        }
        
        // Save the migrated companies
        try await saveCompanies(companies)
        
        print("✅ Migration completed with \(companies.count) companies")
        return companies
    }
    
    private func migrateInvoicesForCompany(_ company: Company) async throws {
        if fileManager.fileExists(atPath: invoicesURL.path) {
            let data = try Data(contentsOf: invoicesURL)
            let invoices = try decoder.decode([Invoice].self, from: data)
            try await saveInvoices(invoices, for: company)
            print("✅ Migrated \(invoices.count) invoices for \(company.name)")
        }
    }
    
    private func migrateProductsForCompany(_ company: Company) async throws {
        if fileManager.fileExists(atPath: productsURL.path) {
            let data = try Data(contentsOf: productsURL)
            let products = try decoder.decode([Product].self, from: data)
            try await saveProducts(products, for: company)
            print("✅ Migrated \(products.count) products for \(company.name)")
        }
    }
    
    // MARK: - Default Data Creation
    
    private func createDefaultCompanies() -> [Company] {
        return [
            Company(
                name: "Jessica Consulting AB",
                organizationNumber: "559999-9999",
                vatNumber: "SE559999999901",
                address: Address(
                    street: "Storgatan 1",
                    postalCode: "123 45",
                    city: "Stockholm",
                    country: "Sverige"
                ),
                email: "jessica@consulting.se",
                phone: "08-123 45 67",
                website: "www.jessicaconsulting.se",
                isPrimaryCompany: true
            ),
            Company(
                name: "Jessica Design Studio",
                organizationNumber: "558888-8888",
                vatNumber: "SE558888888801",
                address: Address(
                    street: "Designgatan 5",
                    postalCode: "118 20",
                    city: "Stockholm",
                    country: "Sverige"
                ),
                email: "jessica@designstudio.se",
                phone: "08-987 65 43",
                website: "www.jessicadesign.se",
                isPrimaryCompany: false
            )
        ]
    }
    
    private func createDefaultProducts(for company: Company) -> [Product] {
        let defaultVatRate = company.defaultVatRate
        
        return [
            Product(
                name: "Webbutveckling",
                description: "Frontend och backend utveckling",
                price: 1200,
                unit: "timme",
                category: .development,
                vatRate: defaultVatRate
            ),
            Product(
                name: "UI/UX Design",
                description: "Användarupplevelse och gränssnitt",
                price: 1000,
                unit: "timme",
                category: .design,
                vatRate: defaultVatRate
            ),
            Product(
                name: "Konsultation",
                description: "Teknisk rådgivning",
                price: 1500,
                unit: "timme",
                category: .consultation,
                vatRate: defaultVatRate
            ),
            Product(
                name: "Hosting",
                description: "Webbhotell och domän",
                price: 299,
                unit: "månad",
                category: .service,
                vatRate: defaultVatRate
            )
        ]
    }
    
    // MARK: - Enhanced Backup System
    
    private func createCompaniesBackup(_ companies: [Company]) async throws {
        let timestamp = DateFormatter.backupFormatter.string(from: Date())
        let backupURL = backupDirectory.appendingPathComponent("companies_backup_\(timestamp).json")
        
        let data = try encoder.encode(companies)
        try data.write(to: backupURL)
        
        // Clean old company backups (keep last 5)
        try cleanOldBackups(prefix: "companies_backup_", keepCount: 5)
        
        print("✅ Created companies backup: \(backupURL.lastPathComponent)")
    }
    
    private func createInvoicesBackup(_ invoices: [Invoice], for company: Company) async throws {
        let timestamp = DateFormatter.backupFormatter.string(from: Date())
        let companyBackupDir = backupDirectory.appendingPathComponent(company.id.uuidString)
        
        try fileManager.createDirectory(at: companyBackupDir, withIntermediateDirectories: true)
        
        let backupURL = companyBackupDir.appendingPathComponent("invoices_backup_\(timestamp).json")
        let data = try encoder.encode(invoices)
        try data.write(to: backupURL)
        
        print("✅ Created invoices backup for \(company.name): \(backupURL.lastPathComponent)")
    }
    
    private func cleanOldBackups(prefix: String, keepCount: Int) throws {
        let backupFiles = try fileManager.contentsOfDirectory(at: backupDirectory,
                                                             includingPropertiesForKeys: [.creationDateKey],
                                                             options: .skipsHiddenFiles)
            .filter { $0.lastPathComponent.hasPrefix(prefix) }
            .sorted { url1, url2 in
                let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate
                let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate
                return (date1 ?? Date.distantPast) > (date2 ?? Date.distantPast)
            }
        
        // Remove old backups, keeping the most recent ones
        for backup in backupFiles.dropFirst(keepCount) {
            try fileManager.removeItem(at: backup)
        }
    }
    
    // MARK: - Advanced Backup and Restore
    
    func createFullBackup() async throws -> URL {
        let timestamp = DateFormatter.backupFormatter.string(from: Date())
        let backupURL = backupDirectory.appendingPathComponent("full_backup_\(timestamp).json")
        
        let companies = try await loadCompanies()
        var companyData: [UUID: CompanyBackupData] = [:]
        
        for company in companies {
            let invoices = try await loadInvoices(for: company)
            let products = try await loadProducts(for: company)
            
            companyData[company.id] = CompanyBackupData(
                company: company,
                invoices: invoices,
                products: products
            )
        }
        
        let fullBackup = FullBackupData(
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            companyData: companyData
        )
        
        let data = try encoder.encode(fullBackup)
        try data.write(to: backupURL)
        
        print("✅ Created full backup: \(backupURL.lastPathComponent)")
        return backupURL
    }
    
    func restoreFromFullBackup(_ backupURL: URL) async throws {
        do {
            let data = try Data(contentsOf: backupURL)
            let backup = try decoder.decode(FullBackupData.self, from: data)
            
            // Extract companies
            let companies = backup.companyData.values.map { $0.company }
            try await saveCompanies(companies)
            
            // Restore data for each company
            for (companyId, data) in backup.companyData {
                let company = data.company
                try await saveInvoices(data.invoices, for: company)
                try await saveProducts(data.products, for: company)
            }
            
            print("✅ Restored from full backup: \(backupURL.lastPathComponent)")
        } catch {
            print("❌ Error restoring from backup: \(error)")
            throw DataError.restoreFailed
        }
    }
    
    func getAvailableBackups() -> [BackupInfo] {
        guard let backupFiles = try? fileManager.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        
        return backupFiles.compactMap { url in
            guard url.lastPathComponent.hasPrefix("full_backup_"),
                  let resourceValues = try? url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey]) else {
                return nil
            }
            
            return BackupInfo(
                url: url,
                date: resourceValues.creationDate ?? Date.distantPast,
                size: Int64(resourceValues.fileSize ?? 0)
            )
        }.sorted { $0.date > $1.date }
    }
    
    // MARK: - Data Cleanup
    
    func deleteCompanyData(_ company: Company) async throws {
        let companyDir = companyDataDirectory(for: company.id)
        
        if fileManager.fileExists(atPath: companyDir.path) {
            try fileManager.removeItem(at: companyDir)
            print("✅ Deleted data directory for company: \(company.name)")
        }
    }
    
    func cleanupUnusedData() async throws {
        let companies = try await loadCompanies()
        let activeCompanyIds = Set(companies.map { $0.id })
        
        // Get all company directories
        let companiesDir = documentsDirectory.appendingPathComponent("Companies")
        guard fileManager.fileExists(atPath: companiesDir.path) else { return }
        
        let companyDirs = try fileManager.contentsOfDirectory(
            at: companiesDir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        
        var cleanedCount = 0
        
        for dir in companyDirs {
            guard let companyId = UUID(uuidString: dir.lastPathComponent) else { continue }
            
            if !activeCompanyIds.contains(companyId) {
                try fileManager.removeItem(at: dir)
                cleanedCount += 1
                print("🗑️ Cleaned up unused data for company: \(companyId)")
            }
        }
        
        print("✅ Cleanup completed. Removed \(cleanedCount) unused company directories")
    }
    
    // MARK: - Data Migration and Versioning
    
    func migrateDataIfNeeded() async throws {
        let userDefaults = UserDefaults.standard
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let lastVersion = userDefaults.string(forKey: "lastAppVersion")
        
        guard lastVersion != currentVersion else { return }
        
        print("🔄 Migrating data from version \(lastVersion ?? "unknown") to \(currentVersion)")
        
        // Perform version-specific migrations
        if lastVersion == nil {
            // First install
            print("🆕 First install detected")
        } else {
            // Add version-specific migrations here
            try await performVersionMigrations(from: lastVersion!, to: currentVersion)
        }
        
        // Cleanup unused data
        try await cleanupUnusedData()
        
        userDefaults.set(currentVersion, forKey: "lastAppVersion")
        print("✅ Data migration completed to version \(currentVersion)")
    }
    
    private func performVersionMigrations(from oldVersion: String, to newVersion: String) async throws {
        // Add specific migration logic here based on version numbers
        // For example:
        // if oldVersion.compare("1.0", options: .numeric) == .orderedAscending {
        //     // Migrate from pre-1.0 versions
        // }
        
        print("📦 Performing migrations from \(oldVersion) to \(newVersion)")
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
