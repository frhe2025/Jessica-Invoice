//
//  CompanyDashboardView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI
import Charts

struct CompanyDashboardView: View {
    @EnvironmentObject var companyManager: CompanyManager
    @EnvironmentObject var invoiceViewModel: InvoiceViewModel
    @EnvironmentObject var productViewModel: ProductViewModel
    
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var showingCompanySelector = false
    @State private var selectedMetric: DashboardMetric = .revenue
    @State private var isRefreshing = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 24) {
                    dashboardHeader
                    metricsGrid(geometry: geometry)
                    revenueChartSection
                    quickActionsSection
                    recentActivitySection
                    insightsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .refreshable {
                await refreshData()
            }
        }
        .background(AnimatedGradientBackground.dashboard)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCompanySelector) {
            CompanySelectorSheet(
                companies: companyManager.companies,
                selectedCompany: $companyManager.activeCompany
            )
        }
        .onAppear {
            Task { await companyManager.loadDashboardData() }
        }
    }
    
    // MARK: - Header
    private var dashboardHeader: some View {
        LiquidGlassCard.prominent {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Översikt för \(companyManager.activeCompany?.name ?? "Välj företag")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    AdaptiveButton.icon("building.2", color: .blue) {
                        showingCompanySelector = true
                    }
                }
                timeFramePicker
            }
            .padding(20)
        }
    }
    
    private var timeFramePicker: some View {
        HStack(spacing: 8) {
            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                AdaptiveButton.pill(
                    timeFrame.displayName,
                    color: selectedTimeframe == timeFrame ? .blue : .secondary,
                    size: .small
                ) {
                    selectedTimeframe = timeFrame
                    companyManager.updateTimeframe(timeFrame)
                }
                .opacity(selectedTimeframe == timeFrame ? 1.0 : 0.7)
            }
        }
    }
    
    // MARK: - Metrics Grid
    private func metricsGrid(geometry: GeometryProxy) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: geometry.size.width > 700 ? 4 : 2)
        return LazyVGrid(columns: columns, spacing: 16) {
            MetricCard(
                title: "Totala intäkter",
                value: companyManager.dashboardData.totalRevenue.formattedCurrency,
                change: companyManager.dashboardData.revenueChange,
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                isSelected: selectedMetric == .revenue
            ) { selectedMetric = .revenue }
            MetricCard(
                title: "Aktiva fakturor",
                value: "\(companyManager.dashboardData.activeInvoices)",
                change: companyManager.dashboardData.invoiceChange,
                icon: "doc.text.fill",
                color: .blue,
                isSelected: selectedMetric == .invoices
            ) { selectedMetric = .invoices }
            MetricCard(
                title: "Utestående",
                value: companyManager.dashboardData.outstandingAmount.formattedCurrency,
                change: companyManager.dashboardData.outstandingChange,
                icon: "clock.arrow.circlepath",
                color: .orange,
                isSelected: selectedMetric == .outstanding
            ) { selectedMetric = .outstanding }
            MetricCard(
                title: "Förfallna",
                value: companyManager.dashboardData.overdueAmount.formattedCurrency,
                change: companyManager.dashboardData.overdueChange,
                icon: "exclamationmark.triangle.fill",
                color: .red,
                isSelected: selectedMetric == .overdue
            ) { selectedMetric = .overdue }
        }
    }
    
    // MARK: - Revenue Chart
    private var revenueChartSection: some View {
        LiquidGlassCard.adaptive {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Intäktsutveckling")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(selectedTimeframe.chartSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Menu {
                        ForEach(DashboardMetric.allCases, id: \.self) { metric in
                            Button(metric.displayName) {
                                selectedMetric = metric
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedMetric.displayName)
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                revenueChart
            }
            .padding(20)
        }
    }
    
    private var revenueChart: some View {
        Chart(companyManager.dashboardData.chartData) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Value", dataPoint.value)
            )
            .foregroundStyle(selectedMetric.color.gradient)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
            AreaMark(
                x: .value("Date", dataPoint.date),
                y: .value("Value", dataPoint.value)
            )
            .foregroundStyle(selectedMetric.color.opacity(0.1).gradient)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: selectedTimeframe.xAxisStride)) { _ in
                AxisGridLine().foregroundStyle(.secondary.opacity(0.3))
                AxisTick().foregroundStyle(.secondary)
                AxisValueLabel().font(.caption2).foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(.secondary.opacity(0.3))
                AxisTick().foregroundStyle(.secondary)
                AxisValueLabel().font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(height: 200)
        .animation(.easeInOut(duration: 0.5), value: selectedMetric)
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        LiquidGlassCard.adaptive {
            VStack(alignment: .leading, spacing: 16) {
                Text("Snabbåtgärder")
                    .font(.headline)
                    .fontWeight(.semibold)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    QuickActionCard(
                        title: "Ny faktura",
                        icon: "doc.badge.plus",
                        color: .blue,
                        description: "Skapa en ny faktura"
                    ) { invoiceViewModel.createNewInvoice() }
                    QuickActionCard(
                        title: "Lägg till produkt",
                        icon: "cart.badge.plus",
                        color: .green,
                        description: "Ny produkt eller tjänst"
                    ) { productViewModel.createNewProduct() }
                    QuickActionCard(
                        title: "Skicka påminnelse",
                        icon: "envelope.arrow.triangle.branch",
                        color: .orange,
                        description: "Påminn om betalning"
                    ) { }
                    QuickActionCard(
                        title: "Rapport",
                        icon: "chart.bar.doc.horizontal",
                        color: .purple,
                        description: "Generera rapport"
                    ) { }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        LiquidGlassCard.adaptive {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Senaste aktivitet")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    AdaptiveButton.ghost("Visa alla") { }
                }
                Group {
                    if companyManager.dashboardData.recentActivities.isEmpty {
                        ActivityEmptyState()
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(companyManager.dashboardData.recentActivities.enumerated()), id: \.element.id) { index, activity in
                                ActivityRow(activity: activity)
                                if index < companyManager.dashboardData.recentActivities.count - 1 {
                                    Divider().padding(.leading, 44)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Insights
    private var insightsSection: some View {
        LiquidGlassCard.adaptive {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("Insikter")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                LazyVStack(spacing: 12) {
                    ForEach(companyManager.dashboardData.insights, id: \.id) { insight in
                        InsightCard(insight: insight)
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Helper Methods
    private func refreshData() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await companyManager.refreshDashboardData()
        isRefreshing = false
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let change: Double?
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LiquidGlassCard(
                style: isSelected ? .prominent : .adaptive,
                depth: isSelected ? .deep : .medium
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(color)
                        Spacer()
                        if let change = change {
                            ChangeIndicator(change: change)
                        }
                    }
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(16)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Change Indicator
struct ChangeIndicator: View {
    let change: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                .font(.caption2)
            Text("\(abs(change), specifier: "%.1f")%")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(change >= 0 ? .green : .red)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill((change >= 0 ? Color.green : Color.red).opacity(0.1))
        )
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                    Spacer()
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let activity: DashboardActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activity.type.color.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: activity.type.icon)
                        .font(.caption)
                        .foregroundStyle(activity.type.color)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(activity.timestamp.relativeString)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Activity Empty State
struct ActivityEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("Ingen aktivitet än")
                .font(.subheadline)
                .fontWeight(.medium)
            Text("Aktivitet visas här när du börjar fakturera")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: DashboardInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.type.icon)
                .font(.title3)
                .foregroundStyle(insight.type.color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(insight.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if insight.hasAction {
                AdaptiveButton.pill("Se mer", color: insight.type.color, size: .small) {
                    insight.action?()
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(insight.type.color.opacity(0.05))
                .stroke(insight.type.color.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Company Selector Sheet
struct CompanySelectorSheet: View {
    let companies: [Company]
    @Binding var selectedCompany: Company?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(companies, id: \.id) { company in
                CompanyRow(
                    company: company,
                    isSelected: selectedCompany?.id == company.id
                ) {
                    selectedCompany = company
                    dismiss()
                }
            }
            .navigationTitle("Välj företag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Stäng") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CompanyRow: View {
    let company: Company
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(company.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(company.organizationNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// OBS: Om du får redeclaration error på denna extension, TA BORT DEN!
// private extension Date {
//     var relativeString: String {
//         let formatter = RelativeDateTimeFormatter()
//         formatter.unitsStyle = .short
//         return formatter.localizedString(for: self, relativeTo: Date())
//     }
// }

#Preview {
    CompanyDashboardView()
        .environmentObject(CompanyManager())
        .environmentObject(InvoiceViewModel())
        .environmentObject(ProductViewModel())
}
