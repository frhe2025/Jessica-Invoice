//
//  ContentView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//  Updated with iOS 26 Liquid Glass Navigation
//

import SwiftUI

struct ContentView: View {
    @StateObject private var companyManager = CompanyManager()
    @EnvironmentObject var invoiceViewModel: InvoiceViewModel
    @EnvironmentObject var productViewModel: ProductViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    @State private var selectedTab = 0
    @State private var showingCompanyDashboard = false
    @State private var navigationPath = NavigationPath()
    
    // Notification handling
    @State private var showingNotificationBadge = false
    
    var body: some View {
        LiquidNavigationContainer(
            navigationBar: currentNavigationBar,
            tabBar: liquidTabBar,
            showsNavBar: shouldShowNavigationBar,
            showsTabBar: true
        ) {
            NavigationStack(path: $navigationPath) {
                ZStack {
                    // Background with liquid glass effects
                    currentBackground
                    
                    // Main content
                    TabView(selection: $selectedTab) {
                        // Dashboard Tab
                        CompanyDashboardView()
                            .environmentObject(companyManager)
                            .tag(0)
                        
                        // Invoice Tab
                        InvoiceView()
                            .tag(1)
                        
                        // Products Tab
                        ProductsView()
                            .tag(2)
                        
                        // History Tab
                        HistoryView()
                            .tag(3)
                        
                        // Settings Tab
                        SettingsView()
                            .tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedTab)
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
        }
        .tint(.blue)
        .preferredColorScheme(settingsViewModel.enableDarkMode ? .dark : nil)
        .onAppear {
            setupNotificationHandling()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToInvoice)) { notification in
            if let invoiceId = notification.object as? UUID {
                navigateToInvoice(invoiceId)
            }
        }
        .sheet(isPresented: $showingCompanyDashboard) {
            CompanyDashboardView()
                .environmentObject(companyManager)
        }
    }
    
    // MARK: - Navigation Bar
    @ViewBuilder
    private var currentNavigationBar: LiquidNavigationBar? {
        switch selectedTab {
        case 0:
            LiquidNavigationBar(
                title: "Dashboard",
                subtitle: companyManager.activeCompany?.name,
                trailingActions: [
                    .share { shareCompanyReport() },
                    .more { showMoreOptions() }
                ],
                tintColor: .blue
            )
        case 1:
            LiquidNavigationBar(
                title: "Faktura",
                subtitle: "Skapa och hantera fakturor",
                trailingActions: [
                    NavigationAction(
                        systemImage: "plus.circle.fill",
                        color: .blue,
                        action: { invoiceViewModel.createNewInvoice() }
                    )
                ],
                tintColor: .blue
            )
        case 2:
            LiquidNavigationBar(
                title: "Produkter",
                subtitle: "\(productViewModel.totalProducts) aktiva produkter",
                trailingActions: [
                    NavigationAction(
                        systemImage: "plus.circle.fill",
                        color: .green,
                        action: { productViewModel.createNewProduct() }
                    )
                ],
                tintColor: .green
            )
        case 3:
            LiquidNavigationBar(
                title: "Historik",
                subtitle: "\(invoiceViewModel.invoices.count) fakturor totalt",
                trailingActions: [
                    .share { shareInvoiceHistory() }
                ],
                tintColor: .orange
            )
        case 4:
            LiquidNavigationBar(
                title: "Inställningar",
                subtitle: settingsViewModel.company.name,
                tintColor: .purple
            )
        default:
            nil
        }
    }
    
    // MARK: - Tab Bar
    private var liquidTabBar: LiquidTabBar {
        LiquidTabBar(
            selectedTab: $selectedTab,
            tintColor: currentTintColor,
            tabs: [
                TabItem(
                    title: "Dashboard",
                    icon: "chart.bar.xaxis",
                    badge: showingNotificationBadge ? "!" : nil
                ),
                TabItem(
                    title: "Faktura",
                    icon: "doc.text",
                    badge: invoiceViewModel.overdueInvoices.isEmpty ? nil : "\(invoiceViewModel.overdueInvoices.count)"
                ),
                TabItem(
                    title: "Produkter",
                    icon: "cart",
                    badge: nil
                ),
                TabItem(
                    title: "Historik",
                    icon: "clock.arrow.circlepath"
                ),
                TabItem(
                    title: "Inställningar",
                    icon: "gearshape"
                )
            ]
        )
    }
    
    // MARK: - Background
    @ViewBuilder
    private var currentBackground: some View {
        switch selectedTab {
        case 0:
            AnimatedGradientBackground.dashboard
        case 1:
            AnimatedGradientBackground.invoice
        case 2:
            AnimatedGradientBackground.products
        case 3:
            AnimatedGradientBackground.history
        case 4:
            AnimatedGradientBackground.settings
        default:
            AnimatedGradientBackground.dashboard
        }
    }
    
    // MARK: - Computed Properties
    private var currentTintColor: Color {
        switch selectedTab {
        case 0: return .blue
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        case 4: return .purple
        default: return .blue
        }
    }
    
    private var shouldShowNavigationBar: Bool {
        // Hide navigation bar for certain views if needed
        return true
    }
    
    // MARK: - Navigation
    private func destinationView(for destination: NavigationDestination) -> some View {
        Group {
            switch destination {
            case .invoiceDetail(let invoice):
                InvoiceDetailView(invoice: invoice)
            case .newInvoice(let invoice):
                NewInvoiceView(invoice: invoice)
            case .productDetail(let product):
                AddProductView(product: product)
            case .companySettings:
                CompanySettingsView()
                    .environmentObject(companyManager)
            }
        }
    }
    
    private func navigateToInvoice(_ invoiceId: UUID) {
        guard let invoice = invoiceViewModel.invoices.first(where: { $0.id == invoiceId }) else { return }
        
        selectedTab = 1 // Switch to invoice tab
        navigationPath.append(NavigationDestination.invoiceDetail(invoice))
    }
    
    // MARK: - Actions
    private func shareCompanyReport() {
        // Generate and share company report
        Task {
            do {
                let reportData = try await companyManager.generateCompanyReport()
                // Present share sheet
            } catch {
                print("Error generating report: \(error)")
            }
        }
    }
    
    private func shareInvoiceHistory() {
        // Export invoice history
        Task {
            do {
                let historyData = try await invoiceViewModel.exportInvoiceHistory()
                // Present share sheet
            } catch {
                print("Error exporting history: \(error)")
            }
        }
    }
    
    private func showMoreOptions() {
        // Show action sheet with more options
    }
    
    private func setupNotificationHandling() {
        // Setup notification observers
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            updateNotificationBadge()
        }
    }
    
    private func updateNotificationBadge() {
        showingNotificationBadge = !invoiceViewModel.overdueInvoices.isEmpty
    }
}

// MARK: - Navigation Destinations
enum NavigationDestination: Hashable {
    case invoiceDetail(Invoice)
    case newInvoice(Invoice?)
    case productDetail(Product)
    case companySettings
}

// MARK: - Company Settings View
struct CompanySettingsView: View {
    @EnvironmentObject var companyManager: CompanyManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Company selector
                    if companyManager.companies.count > 1 {
                        CompanySelectorCard()
                    }
                    
                    // Quick stats
                    CompanyStatsGrid()
                    
                    // Company management
                    CompanyManagementSection()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(AnimatedGradientBackground.settings)
            .navigationTitle("Företagsinställningar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AdaptiveButton.ghost("Stäng") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CompanySelectorCard: View {
    @EnvironmentObject var companyManager: CompanyManager
    
    var body: some View {
        LiquidGlassContainer.primary {
            VStack(alignment: .leading, spacing: 16) {
                Text("Aktivt företag")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let activeCompany = companyManager.activeCompany {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activeCompany.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(activeCompany.organizationNumber)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        AdaptiveButton.secondary("Växla") {
                            // Show company picker
                        }
                    }
                } else {
                    Text("Inget företag valt")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
    }
}

struct CompanyStatsGrid: View {
    @EnvironmentObject var companyManager: CompanyManager
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            StatCard(
                title: "Totala intäkter",
                value: companyManager.dashboardData.totalRevenue.formattedCurrency,
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            StatCard(
                title: "Aktiva fakturor",
                value: "\(companyManager.dashboardData.activeInvoices)",
                icon: "doc.text.fill",
                color: .blue
            )
            
            StatCard(
                title: "Produkter",
                value: "12", // This should come from ProductViewModel
                icon: "cart.fill",
                color: .orange
            )
            
            StatCard(
                title: "Företag",
                value: "\(companyManager.companies.count)",
                icon: "building.2.fill",
                color: .purple
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        LiquidGlassContainer.subtle {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
    }
}

struct CompanyManagementSection: View {
    @EnvironmentObject var companyManager: CompanyManager
    
    var body: some View {
        LiquidGlassContainer.subtle {
            VStack(alignment: .leading, spacing: 16) {
                Text("Företagshantering")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    ManagementActionRow(
                        title: "Lägg till företag",
                        icon: "plus.circle.fill",
                        color: .green
                    ) {
                        // Add company action
                    }
                    
                    ManagementActionRow(
                        title: "Redigera företag",
                        icon: "pencil.circle.fill",
                        color: .blue
                    ) {
                        // Edit company action
                    }
                    
                    ManagementActionRow(
                        title: "Exportera data",
                        icon: "square.and.arrow.up.fill",
                        color: .orange
                    ) {
                        // Export data action
                    }
                    
                    if companyManager.companies.count > 1 {
                        ManagementActionRow(
                            title: "Ta bort företag",
                            icon: "minus.circle.fill",
                            color: .red
                        ) {
                            // Delete company action
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

struct ManagementActionRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        AdaptiveButton.ghost(title, icon: icon, color: color, action: action)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Extensions for CompanyManager
extension CompanyManager {
    func generateCompanyReport() async throws -> Data {
        // Generate comprehensive company report
        let reportData = CompanyReportData(
            company: activeCompany ?? Company(),
            dashboardData: dashboardData,
            generatedAt: Date()
        )
        
        return try JSONEncoder().encode(reportData)
    }
}

extension InvoiceViewModel {
    func exportInvoiceHistory() async throws -> Data {
        let historyData = InvoiceHistoryData(
            invoices: invoices,
            exportedAt: Date(),
            totalCount: invoices.count
        )
        
        return try JSONEncoder().encode(historyData)
    }
}

struct CompanyReportData: Codable {
    let company: Company
    let dashboardData: DashboardData
    let generatedAt: Date
}

struct InvoiceHistoryData: Codable {
    let invoices: [Invoice]
    let exportedAt: Date
    let totalCount: Int
}

#Preview {
    ContentView()
        .environmentObject(InvoiceViewModel())
        .environmentObject(ProductViewModel())
        .environmentObject(SettingsViewModel())
}
