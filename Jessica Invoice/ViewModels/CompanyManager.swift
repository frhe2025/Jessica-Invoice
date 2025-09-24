//
//  CompanyManager.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import Foundation
import SwiftUI

@MainActor
class CompanyManager: ObservableObject {
    @Published var companies: [Company] = []
    @Published var activeCompany: Company?
    @Published var dashboardData: DashboardData = DashboardData()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Dashboard state
    @Published var selectedTimeframe: TimeFrame = .month
    @Published var lastUpdateTime: Date = Date()
    
    private let dataManager = DataManager.shared
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadCompanies()
        loadActiveCompany()
        setupNotifications()
    }
    
    // MARK: - Company Management
    func loadCompanies() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Load primary company
                let primaryCompany = try await dataManager.loadCompany()
                
                // Load additional companies from UserDefaults
                let additionalCompanies = loadAdditionalCompanies()
                
                self.companies = [primaryCompany] + additionalCompanies
                
                if activeCompany == nil {
                    activeCompany = companies.first
                }
                
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func saveCompany(_ company: Company) async throws {
        if let index = companies.firstIndex(where: { $0.id == company.id }) {
            companies[index] = company
        } else {
            companies.append(company)
        }
        
        // Save primary company to DataManager
        if company.id == companies.first?.id {
            try await dataManager.saveCompany(company)
        } else {
            // Save additional companies to UserDefaults
            saveAdditionalCompanies()
        }
        
        // Update active company if it's the one being saved
        if activeCompany?.id == company.id {
            activeCompany = company
        }
    }
    
    func deleteCompany(_ company: Company) async throws {
        guard companies.count > 1 else {
            throw CompanyManagerError.cannotDeleteLastCompany
        }
        
        companies.removeAll { $0.id == company.id }
        
        if activeCompany?.id == company.id {
            activeCompany = companies.first
        }
        
        saveAdditionalCompanies()
        await loadDashboardData()
    }
    
    func switchToCompany(_ company: Company) {
        activeCompany = company
        userDefaults.set(company.id.uuidString, forKey: "activeCompanyId")
        
        Task {
            await loadDashboardData()
        }
    }
    
    // MARK: - Dashboard Data
    func loadDashboardData() async {
        guard let activeCompany = activeCompany else { return }
        
        isLoading = true
        
        do {
            let invoices = try await dataManager.loadInvoices()
            let products = try await dataManager.loadProducts()
            
            // Filter data for active company if needed
            let companyInvoices = filterInvoicesForCompany(invoices, company: activeCompany)
            let companyProducts = filterProductsForCompany(products, company: activeCompany)
            
            // Generate dashboard data
            dashboardData = generateDashboardData(
                from: companyInvoices,
                products: companyProducts,
                timeframe: selectedTimeframe
            )
            
            lastUpdateTime = Date()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func refreshDashboardData() async {
        await loadDashboardData()
    }
    
    func updateTimeframe(_ timeframe: TimeFrame) {
        selectedTimeframe = timeframe
        Task {
            await loadDashboardData()
        }
    }
    
    // MARK: - Private Methods
    private func loadActiveCompany() {
        if let activeCompanyId = userDefaults.string(forKey: "activeCompanyId"),
           let uuid = UUID(uuidString: activeCompanyId) {
            activeCompany = companies.first { $0.id == uuid }
        }
    }
    
    private func loadAdditionalCompanies() -> [Company] {
        guard let data = userDefaults.data(forKey: "additionalCompanies"),
              let companies = try? JSONDecoder().decode([Company].self, from: data) else {
            return []
        }
        return companies
    }
    
    private func saveAdditionalCompanies() {
        let additionalCompanies = Array(companies.dropFirst())
        if let data = try? JSONEncoder().encode(additionalCompanies) {
            userDefaults.set(data, forKey: "additionalCompanies")
        }
    }
    
    private func filterInvoicesForCompany(_ invoices: [Invoice], company: Company) -> [Invoice] {
        // Treat invoices with nil companyId as belonging to the primary company for backward compatibility
        let primaryId = primaryCompany?.id
        return invoices.filter { inv in
            if let cid = inv.companyId { return cid == company.id }
            return company.id == primaryId
        }
    }
    
    private func filterProductsForCompany(_ products: [Product], company: Company) -> [Product] {
        // Treat products with nil companyId as belonging to the primary company for backward compatibility
        let primaryId = primaryCompany?.id
        return products.filter { prod in
            if let cid = prod.companyId { return cid == company.id }
            return company.id == primaryId
        }
    }
    
    private func generateDashboardData(from invoices: [Invoice], products: [Product], timeframe: TimeFrame) -> DashboardData {
        let dateRange = timeframe.dateRange
        let filteredInvoices = invoices.filter { dateRange.contains($0.date) }
        
        // Calculate metrics
        let totalRevenue = filteredInvoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.total }
        let activeInvoices = filteredInvoices.filter { $0.status == .sent }.count
        let outstandingAmount = filteredInvoices.filter { $0.status == .sent }.reduce(0) { $0 + $1.total }
        let overdueAmount = filteredInvoices.filter { $0.isOverdue }.reduce(0) { $0 + $1.total }
        
        // Calculate changes (comparing to previous period)
        let previousPeriodInvoices = getPreviousPeriodInvoices(invoices, timeframe: timeframe)
        let previousRevenue = previousPeriodInvoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.total }
        
        let revenueChange = calculatePercentageChange(current: totalRevenue, previous: previousRevenue)
        let invoiceChange = calculatePercentageChange(current: Double(activeInvoices), previous: Double(previousPeriodInvoices.count))
        
        // Generate chart data
        let chartData = generateChartData(from: filteredInvoices, timeframe: timeframe)
        
        // Generate activities
        let activities = generateRecentActivities(from: invoices)
        
        // Generate insights
        let insights = generateInsights(from: invoices, products: products)
        
        return DashboardData(
            totalRevenue: totalRevenue,
            activeInvoices: activeInvoices,
            outstandingAmount: outstandingAmount,
            overdueAmount: overdueAmount,
            revenueChange: revenueChange,
            invoiceChange: invoiceChange,
            outstandingChange: 0, // Implement if needed
            overdueChange: 0, // Implement if needed
            chartData: chartData,
            recentActivities: activities,
            insights: insights
        )
    }
    
    private func getPreviousPeriodInvoices(_ invoices: [Invoice], timeframe: TimeFrame) -> [Invoice] {
        let previousRange = timeframe.previousPeriodRange
        return invoices.filter { previousRange.contains($0.date) }
    }
    
    private func calculatePercentageChange(current: Double, previous: Double) -> Double {
        guard previous > 0 else { return 0 }
        return ((current - previous) / previous) * 100
    }
    
    private func generateChartData(from invoices: [Invoice], timeframe: TimeFrame) -> [ChartDataPoint] {
        let dateRange = timeframe.dateRange
        let calendar = Calendar.current
        
        var dataPoints: [ChartDataPoint] = []
        var currentDate = dateRange.lowerBound
        
        while currentDate <= dateRange.upperBound {
            let dayInvoices = invoices.filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
            let dayRevenue = dayInvoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.total }
            
            dataPoints.append(ChartDataPoint(date: currentDate, value: dayRevenue))
            
            currentDate = calendar.date(byAdding: timeframe.dateComponent, value: 1, to: currentDate) ?? currentDate
        }
        
        return dataPoints
    }
    
    private func generateRecentActivities(from invoices: [Invoice]) -> [DashboardActivity] {
        let recentInvoices = Array(invoices.sorted { $0.date > $1.date }.prefix(10))
        
        return recentInvoices.compactMap { invoice in
            let type: ActivityType
            switch invoice.status {
            case .draft:
                type = .invoiceCreated
            case .sent:
                type = .invoiceSent
            case .paid:
                type = .invoicePaid
            case .overdue:
                type = .invoiceOverdue
            case .cancelled:
                type = .invoiceCancelled
            }
            
            return DashboardActivity(
                id: invoice.id,
                type: type,
                title: "Faktura \(invoice.formattedNumber)",
                subtitle: invoice.client.name,
                timestamp: invoice.date
            )
        }
    }
    
    private func generateInsights(from invoices: [Invoice], products: [Product]) -> [DashboardInsight] {
        var insights: [DashboardInsight] = []
        
        // Overdue invoices insight
        let overdueInvoices = invoices.filter { $0.isOverdue }
        if !overdueInvoices.isEmpty {
            insights.append(DashboardInsight(
                type: .warning,
                title: "Förfallna fakturor",
                description: "Du har \(overdueInvoices.count) förfallna fakturor som behöver följas upp",
                hasAction: true,
                action: {
                    // Navigate to overdue invoices
                }
            ))
        }
        
        // Payment trends insight
        let thisMonthPaid = invoices.filter { $0.status == .paid && $0.date.isThisMonth }.count
        let lastMonthPaid = invoices.filter {
            $0.status == .paid && Calendar.current.isDate($0.date, equalTo: (Date().adding(.month, value: -1) ?? Date()), toGranularity: .month)
        }.count
        
        if thisMonthPaid > lastMonthPaid {
            insights.append(DashboardInsight(
                type: .success,
                title: "Bra betalningstrend",
                description: "Fler fakturor har betalats denna månad jämfört med förra månaden",
                hasAction: false
            ))
        }
        
        // Top products insight
        let topProducts = getTopSellingProducts(from: invoices, products: products)
        if let topProduct = topProducts.first {
            insights.append(DashboardInsight(
                type: .info,
                title: "Populäraste produkten",
                description: "\(topProduct.name) är din mest sålda produkt denna månad",
                hasAction: true,
                action: {
                    // Navigate to product details
                }
            ))
        }
        
        return insights
    }
    
    private func getTopSellingProducts(from invoices: [Invoice], products: [Product]) -> [Product] {
        let thisMonthInvoices = invoices.filter { $0.date.isThisMonth }
        let itemCounts = Dictionary(grouping: thisMonthInvoices.flatMap { $0.items }) { $0.description }
            .mapValues { $0.count }
        
        let sortedItems = itemCounts.sorted { $0.value > $1.value }
        
        return sortedItems.compactMap { (description, _) in
            products.first { $0.name == description }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .init("CompanyDataUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.loadDashboardData()
            }
        }
    }
    
    // MARK: - Company Creation
    func createNewCompany(name: String, organizationNumber: String) async throws -> Company {
        let newCompany = Company(
            name: name,
            organizationNumber: organizationNumber,
            address: Address(),
            email: "",
            phone: ""
        )
        
        try await saveCompany(newCompany)
        return newCompany
    }
    
    // MARK: - Validation
    func validateCompany(_ company: Company) -> [String] {
        var errors: [String] = []
        
        if company.name.isEmpty {
            errors.append("Företagsnamn är obligatoriskt")
        }
        
        if company.organizationNumber.isEmpty {
            errors.append("Organisationsnummer är obligatoriskt")
        } else if !isValidOrganizationNumber(company.organizationNumber) {
            errors.append("Ogiltigt organisationsnummer")
        }
        
        // Check for duplicate organization numbers
        if companies.contains(where: { $0.organizationNumber == company.organizationNumber && $0.id != company.id }) {
            errors.append("Organisationsnummer används redan av ett annat företag")
        }
        
        return errors
    }
    
    private func isValidOrganizationNumber(_ number: String) -> Bool {
        let pattern = "^\\d{6}-\\d{4}$|^\\d{10}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: number)
    }
}

// MARK: - Dashboard Data Models
struct DashboardData {
    let totalRevenue: Double
    let activeInvoices: Int
    let outstandingAmount: Double
    let overdueAmount: Double
    let revenueChange: Double?
    let invoiceChange: Double?
    let outstandingChange: Double?
    let overdueChange: Double?
    let chartData: [ChartDataPoint]
    let recentActivities: [DashboardActivity]
    let insights: [DashboardInsight]
    
    init(
        totalRevenue: Double = 0,
        activeInvoices: Int = 0,
        outstandingAmount: Double = 0,
        overdueAmount: Double = 0,
        revenueChange: Double? = nil,
        invoiceChange: Double? = nil,
        outstandingChange: Double? = nil,
        overdueChange: Double? = nil,
        chartData: [ChartDataPoint] = [],
        recentActivities: [DashboardActivity] = [],
        insights: [DashboardInsight] = []
    ) {
        self.totalRevenue = totalRevenue
        self.activeInvoices = activeInvoices
        self.outstandingAmount = outstandingAmount
        self.overdueAmount = overdueAmount
        self.revenueChange = revenueChange
        self.invoiceChange = invoiceChange
        self.outstandingChange = outstandingChange
        self.overdueChange = overdueChange
        self.chartData = chartData
        self.recentActivities = recentActivities
        self.insights = insights
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Activity Models
struct DashboardActivity: Identifiable {
    let id: UUID
    let type: ActivityType
    let title: String
    let subtitle: String
    let timestamp: Date
    
    init(id: UUID = UUID(), type: ActivityType, title: String, subtitle: String, timestamp: Date) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.timestamp = timestamp
    }
}

enum ActivityType {
    case invoiceCreated
    case invoiceSent
    case invoicePaid
    case invoiceOverdue
    case invoiceCancelled
    case productCreated
    case clientAdded
    
    var icon: String {
        switch self {
        case .invoiceCreated: return "doc.badge.plus"
        case .invoiceSent: return "paperplane.fill"
        case .invoicePaid: return "checkmark.circle.fill"
        case .invoiceOverdue: return "exclamationmark.triangle.fill"
        case .invoiceCancelled: return "xmark.circle.fill"
        case .productCreated: return "cart.badge.plus"
        case .clientAdded: return "person.badge.plus"
        }
    }
    
    var color: Color {
        switch self {
        case .invoiceCreated: return .blue
        case .invoiceSent: return .orange
        case .invoicePaid: return .green
        case .invoiceOverdue: return .red
        case .invoiceCancelled: return .gray
        case .productCreated: return .purple
        case .clientAdded: return .mint
        }
    }
}

// MARK: - Insight Models
struct DashboardInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let hasAction: Bool
    let action: (() -> Void)?
    
    init(type: InsightType, title: String, description: String, hasAction: Bool = false, action: (() -> Void)? = nil) {
        self.type = type
        self.title = title
        self.description = description
        self.hasAction = hasAction
        self.action = action
    }
}

enum InsightType {
    case success
    case warning
    case info
    case error
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .info: return .blue
        case .error: return .red
        }
    }
}

// MARK: - Time Frame
enum TimeFrame: CaseIterable {
    case week
    case month
    case quarter
    case year
    
    var displayName: String {
        switch self {
        case .week: return "Vecka"
        case .month: return "Månad"
        case .quarter: return "Kvartal"
        case .year: return "År"
        }
    }
    
    var dateRange: ClosedRange<Date> {
        let now = Date()
        switch self {
        case .week:
            return now.startOfWeek()...now.endOfWeek()
        case .month:
            return now.startOfMonth()...now.endOfMonth()
        case .quarter:
            let startOfQuarter = Calendar.current.dateInterval(of: .quarter, for: now)?.start ?? now.startOfYear()
            let endOfQuarter = Calendar.current.dateInterval(of: .quarter, for: now)?.end ?? now.endOfYear()
            return startOfQuarter...endOfQuarter
        case .year:
            return now.startOfYear()...now.endOfYear()
        }
    }
    
    var previousPeriodRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let range = dateRange
        
        switch self {
        case .week:
            let weeksBefore = calendar.date(byAdding: .weekOfYear, value: -1, to: range.lowerBound) ?? range.lowerBound
            let weeksBeforeEnd = calendar.date(byAdding: .weekOfYear, value: -1, to: range.upperBound) ?? range.upperBound
            return weeksBefore...weeksBeforeEnd
        case .month:
            let monthBefore = calendar.date(byAdding: .month, value: -1, to: range.lowerBound) ?? range.lowerBound
            let monthBeforeEnd = calendar.date(byAdding: .month, value: -1, to: range.upperBound) ?? range.upperBound
            return monthBefore...monthBeforeEnd
        case .quarter:
            let quarterBefore = calendar.date(byAdding: .month, value: -3, to: range.lowerBound) ?? range.lowerBound
            let quarterBeforeEnd = calendar.date(byAdding: .month, value: -3, to: range.upperBound) ?? range.upperBound
            return quarterBefore...quarterBeforeEnd
        case .year:
            let yearBefore = calendar.date(byAdding: .year, value: -1, to: range.lowerBound) ?? range.lowerBound
            let yearBeforeEnd = calendar.date(byAdding: .year, value: -1, to: range.upperBound) ?? range.upperBound
            return yearBefore...yearBeforeEnd
        }
    }
    
    var chartSubtitle: String {
        switch self {
        case .week: return "Senaste 7 dagarna"
        case .month: return "Denna månad"
        case .quarter: return "Detta kvartal"
        case .year: return "Detta år"
        }
    }
    
    var dateComponent: Calendar.Component {
        switch self {
        case .week, .month: return .day
        case .quarter: return .weekOfYear
        case .year: return .month
        }
    }
    
    var xAxisStride: Calendar.Component {
        switch self {
        case .week: return .day
        case .month: return .weekOfYear
        case .quarter: return .month
        case .year: return .quarter
        }
    }
}

// MARK: - Dashboard Metric
enum DashboardMetric: CaseIterable {
    case revenue
    case invoices
    case outstanding
    case overdue
    
    var displayName: String {
        switch self {
        case .revenue: return "Intäkter"
        case .invoices: return "Fakturor"
        case .outstanding: return "Utestående"
        case .overdue: return "Förfallna"
        }
    }
    
    var color: Color {
        switch self {
        case .revenue: return .green
        case .invoices: return .blue
        case .outstanding: return .orange
        case .overdue: return .red
        }
    }
}

// MARK: - Extensions
extension Double {
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "SEK"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "0 kr"
    }
}

// MARK: - Errors
enum CompanyManagerError: LocalizedError {
    case cannotDeleteLastCompany
    case companyNotFound
    case invalidCompanyData
    
    var errorDescription: String? {
        switch self {
        case .cannotDeleteLastCompany:
            return "Kan inte ta bort det sista företaget"
        case .companyNotFound:
            return "Företaget kunde inte hittas"
        case .invalidCompanyData:
            return "Ogiltiga företagsdata"
        }
    }
}

// MARK: - Compatibility Shims for Views
extension CompanyManager {
    // Alias used by some views
    var selectedCompany: Company? { activeCompany }
    
    // Convenience flags
    var hasMultipleCompanies: Bool { companies.count > 1 }
    
    // Primary company resolution
    var primaryCompany: Company? {
        if let explicit = companies.first(where: { $0.isPrimaryCompany }) { return explicit }
        return companies.first
    }
    
    // View-facing selectors
    func selectCompany(_ company: Company) {
        switchToCompany(company)
    }
    
    // Add company helper used by some sheets
    func addCompany(_ company: Company) async throws {
        try await saveCompany(company)
        await loadDashboardData()
    }
    
    // Mark a company as primary and persist ordering
    func setPrimaryCompany(_ company: Company) async throws {
        // Clear all primary flags
        for i in companies.indices { companies[i].isPrimaryCompany = false }
        // Set primary on the selected company
        if let index = companies.firstIndex(where: { $0.id == company.id }) {
            companies[index].isPrimaryCompany = true
        }
        // Keep primary first for convenience
        companies.sort { ($0.isPrimaryCompany ? 0 : 1) < ($1.isPrimaryCompany ? 0 : 1) }
        
        // Persist primary company using DataManager for the first company
        if let first = companies.first {
            try await dataManager.saveCompany(first)
        }
        
        // Update active company if needed
        if activeCompany == nil || activeCompany?.id == company.id {
            activeCompany = company
        }
        activeCompany = company
    }
}
