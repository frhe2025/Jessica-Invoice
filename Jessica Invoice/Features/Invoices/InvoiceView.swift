//
//  InvoiceView.swift
//  Jessica Invoice
//
//  📁 ERSÄTT BEFINTLIG FIL I: Features/Invoices/
//  Enhanced iOS 26 Design with Liquid Glass
//

import SwiftUI

struct InvoiceView: View {
    @EnvironmentObject var companyManager: CompanyManager
    @EnvironmentObject var invoiceViewModel: InvoiceViewModel
    @StateObject private var dashboardViewModel = CompanyDashboardViewModel()
    
    @State private var showingNewInvoice = false
    @State private var animationPhase: CGFloat = 0
    @State private var statisticsAnimationDelay: Double = 0
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 28) {
                        // Hero Section with Liquid Glass
                        heroSection
                        
                        // Company Context Indicator
                        if let company = companyManager.selectedCompany {
                            companyContextSection(company: company)
                        }
                        
                        // Quick Statistics Dashboard
                        statisticsSection(geometry: geometry)
                        
                        // Primary Actions
                        primaryActionsSection(geometry: geometry)
                        
                        // Recent Activity
                        if !dashboardViewModel.recentInvoices.isEmpty {
                            recentActivitySection
                        }
                        
                        // Smart Suggestions & Alerts
                        smartSuggestionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
            .liquidGlassBackground(.invoice)
            .navigationBarHidden(true)
            .refreshable {
                await refreshDashboardData()
            }
            .onAppear {
                setupInitialData()
                startHeroAnimation()
            }
            .onChange(of: companyManager.selectedCompany) { _, newCompany in
                if let company = newCompany {
                    Task {
                        await loadCompanyData(company)
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewInvoice) {
            NewInvoiceView()
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        LiquidGlassCard.prominent {
            VStack(spacing: 24) {
                // Animated Icon with Liquid Effect
                ZStack {
                    // Pulsing background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .blue.opacity(0.3),
                                    .cyan.opacity(0.2),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(1.0 + sin(animationPhase) * 0.1)
                        .blur(radius: 20)
                    
                    // Main icon
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                
                // Hero Text
                VStack(spacing: 12) {
                    Text("Skapa Professionella Fakturor")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Snabbt, enkelt och helt anpassat för ditt företag")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
        }
        .scaleEffect(1.0 + sin(animationPhase * 0.5) * 0.02)
    }
    
    // MARK: - Company Context Section
    private func companyContextSection(company: Company) -> some View {
        LiquidGlassCard.interactive {
            HStack(spacing: 16) {
                // Company Avatar with Liquid Animation
                ZStack {
                    Circle()
                        .fill(companyGradient(for: company))
                        .frame(width: 48, height: 48)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .clear, .white.opacity(0.3)],
                                startPoint: UnitPoint(x: animationPhase, y: 0),
                                endPoint: UnitPoint(x: 1 + animationPhase, y: 1)
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 48, height: 48)
                    
                    Text(company.name.prefix(2).uppercased())
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                // Company Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Fakturerar som")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if company.isPrimaryCompany {
                            primaryCompanyBadge
                        }
                    }
                    
                    Text(company.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // Switch Company Hint
                switchCompanyHint
            }
            .padding(20)
        }
    }
    
    // MARK: - Statistics Section
    private func statisticsSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            // Section Header
            LiquidSectionHeader(
                title: "Översikt",
                subtitle: "Statistik för \(companyManager.selectedCompany?.name ?? "företag")",
                icon: "chart.bar.fill"
            )
            
            // Statistics Grid
            let columns = Array(
                repeating: GridItem(.flexible(), spacing: 16),
                count: geometry.size.width > 700 ? 4 : 2
            )
            
            LazyVGrid(columns: columns, spacing: 16) {
                LiquidStatCard(
                    title: "Totalt Fakturerat",
                    value: formatCurrency(dashboardViewModel.invoiceStatistics.totalInvoiced),
                    change: "+12.5%",
                    isPositive: true,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue,
                    animationDelay: 0.0
                )
                
                LiquidStatCard(
                    title: "Betalt",
                    value: formatCurrency(dashboardViewModel.invoiceStatistics.totalPaid),
                    change: formatPercentage(dashboardViewModel.invoiceStatistics.paymentRate),
                    isPositive: true,
                    icon: "checkmark.circle.fill",
                    color: .green,
                    animationDelay: 0.1
                )
                
                LiquidStatCard(
                    title: "Utestående",
                    value: formatCurrency(dashboardViewModel.invoiceStatistics.totalOutstanding),
                    change: "\(dashboardViewModel.invoiceStatistics.invoiceCount - dashboardViewModel.invoiceStatistics.paidCount) st",
                    isPositive: false,
                    icon: "clock.fill",
                    color: .orange,
                    animationDelay: 0.2
                )
                
                LiquidStatCard(
                    title: "Förfallna",
                    value: formatCurrency(dashboardViewModel.invoiceStatistics.totalOverdue),
                    change: "\(dashboardViewModel.invoiceStatistics.overdueCount) st",
                    isPositive: false,
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    animationDelay: 0.3
                )
            }
        }
    }
    
    // MARK: - Primary Actions Section
    private func primaryActionsSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            LiquidSectionHeader(
                title: "Skapa Faktura",
                subtitle: "Välj hur du vill komma igång"
            )
            
            let columns = Array(
                repeating: GridItem(.flexible(), spacing: 16),
                count: geometry.size.width > 700 ? 3 : 1
            )
            
            LazyVGrid(columns: columns, spacing: 16) {
                // Primary Action - New Invoice
                LiquidActionCard(
                    title: "Ny Faktura",
                    subtitle: "Skapa från början",
                    icon: "plus.circle.fill",
                    color: .blue,
                    style: .primary
                ) {
                    createNewInvoice()
                }
                
                // Secondary Action - Use Template
                LiquidActionCard(
                    title: "Använd Mall",
                    subtitle: "Snabbare skapande",
                    icon: "doc.badge.plus",
                    color: .green,
                    style: .secondary
                ) {
                    // Template action
                }
                
                // Tertiary Action - Quick Invoice
                LiquidActionCard(
                    title: "Snabbfaktura",
                    subtitle: "Minimal information",
                    icon: "bolt.fill",
                    color: .orange,
                    style: .tertiary
                ) {
                    // Quick invoice action
                }
            }
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            LiquidSectionHeader(
                title: "Senaste Aktivitet",
                actionTitle: "Visa alla",
                action: { /* Navigate to history */ }
            )
            
            LiquidGlassCard.adaptive {
                VStack(spacing: 0) {
                    ForEach(Array(dashboardViewModel.recentInvoices.prefix(3).enumerated()), id: \.element.id) { index, invoice in
                        LiquidInvoiceRow(invoice: invoice) {
                            editInvoice(invoice)
                        }
                        
                        if index < min(2, dashboardViewModel.recentInvoices.count - 1) {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Smart Suggestions Section
    private var smartSuggestionsSection: some View {
        VStack(spacing: 16) {
            ForEach(generateSmartSuggestions(), id: \.id) { suggestion in
                LiquidSuggestionCard(suggestion: suggestion)
            }
        }
    }
    
    // MARK: - Helper Components
    private var primaryCompanyBadge: some View {
        Text("PRIMÄR")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(.blue.opacity(0.15))
            )
            .foregroundStyle(.blue)
    }
    
    private var switchCompanyHint: some View {
        VStack(spacing: 2) {
            Image(systemName: "arrow.up.arrow.down")
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            Text("Byt")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
    
    // MARK: - Helper Functions
    private func companyGradient(for company: Company) -> LinearGradient {
        LinearGradient(
            colors: [.blue, .cyan, .indigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        String(format: "%.0f kr", amount)
    }
    
    private func formatPercentage(_ rate: Double) -> String {
        String(format: "%.1f%%", rate * 100)
    }
    
    private func createNewInvoice() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        showingNewInvoice = true
    }
    
    private func editInvoice(_ invoice: Invoice) {
        // Navigate to edit invoice
    }
    
    private func setupInitialData() {
        if let company = companyManager.selectedCompany {
            Task {
                await loadCompanyData(company)
            }
        }
    }
    
    private func loadCompanyData(_ company: Company) async {
        await dashboardViewModel.loadDashboardData(for: company)
    }
    
    private func refreshDashboardData() async {
        if let company = companyManager.selectedCompany {
            await loadCompanyData(company)
        }
    }
    
    private func startHeroAnimation() {
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
    
    private func generateSmartSuggestions() -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Overdue invoices warning
        if dashboardViewModel.invoiceStatistics.overdueCount > 0 {
            suggestions.append(
                SmartSuggestion(
                    type: .warning,
                    title: "Förfallna Fakturor",
                    message: "Du har \(dashboardViewModel.invoiceStatistics.overdueCount) fakturor som behöver åtgärd",
                    actionTitle: "Hantera förfallna",
                    action: { /* Handle overdue */ }
                )
            )
        }
        
        // First invoice encouragement
        if dashboardViewModel.invoiceStatistics.invoiceCount == 0 {
            suggestions.append(
                SmartSuggestion(
                    type: .info,
                    title: "Välkommen!",
                    message: "Skapa din första faktura för att komma igång",
                    actionTitle: "Skapa första fakturan",
                    action: { createNewInvoice() }
                )
            )
        }
        
        return suggestions
    }
}

// MARK: - Supporting Views and Data Structures

// MARK: - Liquid Section Header
struct LiquidSectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(.blue.gradient)
                    }
                    
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                if let actionTitle = actionTitle, let action = action {
                    Button(actionTitle, action: action)
                        .liquidButtonStyle(variant: .ghost, size: .small)
                }
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Liquid Stat Card
struct LiquidStatCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String
    let color: Color
    let animationDelay: Double
    
    @State private var animationPhase: CGFloat = 0
    @State private var isVisible = false
    
    var body: some View {
        LiquidGlassCard.interactive {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and change indicator
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color.gradient)
                    
                    Spacer()
                    
                    changeIndicator
                }
                
                // Main value
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                // Title
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(16)
        }
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0)
        .onAppear {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.8)
                .delay(animationDelay)
            ) {
                isVisible = true
            }
        }
    }
    
    private var changeIndicator: some View {
        HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption)
            Text(change)
                .font(.caption)
        }
        .foregroundStyle(isPositive ? .green : .red)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background((isPositive ? .green : .red).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Liquid Action Card
struct LiquidActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let style: ActionCardStyle
    let action: () -> Void
    
    enum ActionCardStyle {
        case primary, secondary, tertiary
    }
    
    var body: some View {
        Button(action: action) {
            LiquidGlassCard(
                style: cardStyle,
                depth: .medium
            ) {
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(iconBackground)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: icon)
                            .font(.system(size: 28))
                            .foregroundStyle(iconForeground)
                    }
                    
                    // Text
                    VStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(24)
            }
        }
        .liquidButtonStyle(variant: .ghost, size: .large)
    }
    
    private var cardStyle: LiquidGlassStyle {
        switch style {
        case .primary: return .prominent
        case .secondary: return .adaptive
        case .tertiary: return .minimal
        }
    }
    
    private var iconBackground: Color {
        switch style {
        case .primary: return color.opacity(0.2)
        case .secondary: return color.opacity(0.1)
        case .tertiary: return .clear
        }
    }
    
    private var iconForeground: Color {
        color.gradient
    }
}

// MARK: - Liquid Invoice Row
struct LiquidInvoiceRow: View {
    let invoice: Invoice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Status indicator
                statusIndicator
                
                // Invoice info
                invoiceInfo
                
                Spacer()
                
                // Amount and date
                amountInfo
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
    
    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(invoice.status.color.opacity(0.15))
                .frame(width: 40, height: 40)
            
            Image(systemName: invoice.status.icon)
                .font(.subheadline)
                .foregroundStyle(invoice.status.color)
        }
    }
    
    private var invoiceInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(invoice.client.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Text(invoice.formattedNumber)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var amountInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(String(format: "%.0f kr", invoice.total))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(invoice.date.invoiceTimeString)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Smart Suggestion Card
struct LiquidSuggestionCard: View {
    let suggestion: SmartSuggestion
    
    var body: some View {
        LiquidGlassCard.interactive {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: suggestion.type.icon)
                    .font(.title2)
                    .foregroundStyle(suggestion.type.color)
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(suggestion.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Action button
                if let actionTitle = suggestion.actionTitle {
                    Button(actionTitle) {
                        suggestion.action?()
                    }
                    .liquidButtonStyle(variant: .secondary, size: .small)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Smart Suggestion Model
struct SmartSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    enum SuggestionType {
        case info, warning, success
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .success: return .green
            }
        }
    }
}

// MARK: - Company Dashboard ViewModel
@MainActor
class CompanyDashboardViewModel: ObservableObject {
    @Published var invoiceStatistics = InvoiceStatistics(
        totalInvoiced: 0, totalPaid: 0, totalOutstanding: 0,
        totalOverdue: 0, invoiceCount: 0, paidCount: 0, overdueCount: 0
    )
    @Published var recentInvoices: [Invoice] = []
    @Published var isLoading = false
    
    func loadDashboardData(for company: Company) async {
        isLoading = true
        
        // Simulate loading data
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Mock data - replace with actual data loading
        invoiceStatistics = InvoiceStatistics(
            totalInvoiced: 125000,
            totalPaid: 98000,
            totalOutstanding: 27000,
            totalOverdue: 5500,
            invoiceCount: 15,
            paidCount: 12,
            overdueCount: 2
        )
        
        recentInvoices = [] // Load actual recent invoices
        isLoading = false
    }
}

// MARK: - Invoice Statistics
struct InvoiceStatistics {
    let totalInvoiced: Double
    let totalPaid: Double
    let totalOutstanding: Double
    let totalOverdue: Double
    let invoiceCount: Int
    let paidCount: Int
    let overdueCount: Int
    
    var paymentRate: Double {
        guard invoiceCount > 0 else { return 0 }
        return Double(paidCount) / Double(invoiceCount)
    }
}

#Preview {
    InvoiceView()
        .environmentObject(CompanyManager())
        .environmentObject(InvoiceViewModel())
}
