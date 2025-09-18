//
//  CompanyManagementView.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-16.
//

//
//  CompanyManagementView.swift
//  📁 PLACERA I: Features/Settings/
//  Multi-Company Management with iOS 26 Liquid Glass
//

import SwiftUI

struct CompanyManagementView: View {
    @EnvironmentObject var companyManager: CompanyManager
    @State private var showingAddCompany = false
    @State private var showingDeleteConfirmation = false
    @State private var companyToDelete: Company?
    @State private var showingDataSummary = false
    @State private var companySummaries: [UUID: CompanyDataSummary] = [:]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Companies Overview
                    companiesOverviewSection
                    
                    // Companies List
                    companiesListSection
                    
                    // Management Actions
                    managementActionsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .settingsLiquidBackground()
            .navigationTitle("Företag")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddCompany = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .liquidButtonStyle(variant: .primary, size: .small)
                }
            }
            .sheet(isPresented: $showingAddCompany) {
                AddCompanyView()
            }
            .sheet(isPresented: $showingDataSummary) {
                DataSummaryView(summaries: companySummaries)
            }
            .alert("Ta bort företag", isPresented: $showingDeleteConfirmation, presenting: companyToDelete) { company in
                Button("Ta bort", role: .destructive) {
                    deleteCompany(company)
                }
                Button("Avbryt", role: .cancel) {}
            } message: { company in
                Text("Är du säker på att du vill ta bort \(company.name)? All data för detta företag kommer att raderas permanent.")
            }
            .onAppear {
                loadCompanySummaries()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        LiquidGlassCard.prominent {
            VStack(spacing: 20) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue.gradient)
                
                VStack(spacing: 8) {
                    Text("Hantera Företag")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Skapa och hantera flera företag för separat fakturering")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Companies Overview Section
    private var companiesOverviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Översikt")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Visa statistik") {
                    showingDataSummary = true
                }
                .liquidButtonStyle(variant: .ghost, size: .small)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                OverviewCard(
                    title: "Totala företag",
                    value: "\(companyManager.companies.count)",
                    icon: "building.2",
                    color: .blue
                )
                
                OverviewCard(
                    title: "Aktivt företag",
                    value: { let name = companyManager.selectedCompany?.name ?? "Inget"; return name.count > 10 ? String(name.prefix(10)) + "..." : name }(),
                    icon: "checkmark.circle",
                    color: .green
                )
                
                OverviewCard(
                    title: "Primärt företag",
                    value: { let name = companyManager.primaryCompany?.name ?? "Inget"; return name.count > 10 ? String(name.prefix(10)) + "..." : name }(),
                    icon: "star.circle",
                    color: .orange
                )
                
                OverviewCard(
                    title: "Status",
                    value: companyManager.hasMultipleCompanies ? "Multi-Company" : "Single Company",
                    icon: "gear",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Companies List Section
    private var companiesListSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Dina företag")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if companyManager.companies.isEmpty {
                emptyCompaniesState
            } else {
                VStack(spacing: 12) {
                    ForEach(companyManager.companies) { company in
                        CompanyManagementCard(
                            company: company,
                            isSelected: company.id == companyManager.selectedCompany?.id,
                            summary: companySummaries[company.id],
                            onSelect: {
                                companyManager.selectCompany(company)
                            },
                            onSetPrimary: {
                                Task {
                                    try await companyManager.setPrimaryCompany(company)
                                }
                            },
                            onEdit: {
                                // Navigate to edit company
                            },
                            onDelete: {
                                companyToDelete = company
                                showingDeleteConfirmation = true
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Management Actions Section
    private var managementActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Åtgärder")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ManagementActionRow(
                    title: "Lägg till nytt företag",
                    subtitle: "Skapa ett nytt företag för fakturering",
                    icon: "plus.circle",
                    color: .blue
                ) {
                    showingAddCompany = true
                }
                
                ManagementActionRow(
                    title: "Exportera företagsdata",
                    subtitle: "Exportera all data för säkerhetskopiering",
                    icon: "square.and.arrow.up",
                    color: .green
                ) {
                    exportCompanyData()
                }
                
                ManagementActionRow(
                    title: "Importera företag",
                    subtitle: "Importera företag från säkerhetskopia",
                    icon: "square.and.arrow.down",
                    color: .orange
                ) {
                    importCompanyData()
                }
                
                if companyManager.companies.count > 1 {
                    ManagementActionRow(
                        title: "Rensa oanvänd data",
                        subtitle: "Ta bort data för inaktiva företag",
                        icon: "trash.circle",
                        color: .red
                    ) {
                        cleanupUnusedData()
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyCompaniesState: some View {
        LiquidGlassCard.adaptive {
            VStack(spacing: 20) {
                Image(systemName: "building.2.crop.circle.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue.opacity(0.6))
                
                VStack(spacing: 8) {
                    Text("Inga företag ännu")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Lägg till ditt första företag för att komma igång med fakturering")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button("Skapa första företaget") {
                    showingAddCompany = true
                }
                .liquidButtonStyle(variant: .primary, size: .medium)
            }
            .padding(32)
        }
    }
    
    // MARK: - Helper Functions
    private func loadCompanySummaries() {
        Task {
            for company in companyManager.companies {
                // Fallback: build a minimal summary from available view models if DataManager lacks a direct API
                do {
                    let invoices = try await DataManager.shared.loadInvoices()
                    let products = try await DataManager.shared.loadProducts()
                    let companyInvoices = invoices // TODO: filter by company when association exists
                    let invoiceCount = companyInvoices.count
                    let productCount = products.count // TODO: filter by company when association exists
                    let totalInvoiced = companyInvoices.reduce(0) { $0 + $1.total }
                    let lastActivity = companyInvoices.sorted { $0.date > $1.date }.first?.date ?? Date.distantPast
                    let summary = CompanyDataSummary(
                        companyId: company.id,
                        invoiceCount: invoiceCount,
                        productCount: productCount,
                        totalInvoiced: totalInvoiced,
                        lastActivity: lastActivity
                    )
                    companySummaries[company.id] = summary
                } catch {
                    print("❌ Error loading summary for \(company.name): \(error)")
                }
            }
        }
    }
    
    private func deleteCompany(_ company: Company) {
        Task {
            do {
                try await companyManager.deleteCompany(company)
                companySummaries.removeValue(forKey: company.id)
            } catch {
                print("❌ Error deleting company: \(error)")
                // Show error alert
            }
        }
    }
    
    private func exportCompanyData() {
        Task {
            do {
                let backupURL = try await DataManager.shared.createFullBackup()
                // Share the backup file
                shareFile(url: backupURL)
            } catch {
                print("❌ Export error: \(error)")
            }
        }
    }
    
    private func importCompanyData() {
        // Implement import functionality
        print("Import company data - not implemented yet")
    }
    
    private func cleanupUnusedData() {
        Task {
            do {
                try await DataManager.shared.cleanupUnusedData()
                loadCompanySummaries() // Refresh summaries
            } catch {
                print("❌ Cleanup error: \(error)")
            }
        }
    }
    
    private func shareFile(url: URL) {
        // Implement file sharing
        print("Share file: \(url)")
    }
}

// MARK: - Supporting Views

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        LiquidGlassCard.adaptive {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                    Spacer()
                }
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
    }
}

struct CompanyManagementCard: View {
    let company: Company
    let isSelected: Bool
    let summary: CompanyDataSummary?
    let onSelect: () -> Void
    let onSetPrimary: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        LiquidGlassCard(
            style: isSelected ? .prominent : .adaptive,
            depth: isSelected ? .deep : .medium
        ) {
            VStack(spacing: 16) {
                // Header
                HStack(spacing: 16) {
                    // Company avatar
                    Circle()
                        .fill(companyGradient)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(company.name.prefix(2).uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        )
                    
                    // Company info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(company.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            
                            if company.isPrimaryCompany {
                                primaryBadge
                            }
                            
                            if isSelected {
                                selectedBadge
                            }
                        }
                        
                        Text(company.organizationNumber)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if !company.address.city.isEmpty {
                            Text("\(company.address.city), \(company.address.country)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Spacer()
                    
                    // Actions menu
                    Menu {
                        if !isSelected {
                            Button("Välj företag") {
                                onSelect()
                            }
                        }
                        
                        if !company.isPrimaryCompany {
                            Button("Sätt som primärt") {
                                onSetPrimary()
                            }
                        }
                        
                        Button("Redigera") {
                            onEdit()
                        }
                        
                        Divider()
                        
                        Button("Ta bort", role: .destructive) {
                            onDelete()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Company statistics
                if let summary = summary {
                    statisticsSection(summary: summary)
                }
            }
            .padding(20)
        }
    }
    
    private var companyGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .cyan, .indigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var primaryBadge: some View {
        Text("PRIMÄR")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.orange.opacity(0.15))
            .foregroundStyle(.orange)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var selectedBadge: some View {
        Text("VALD")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.green.opacity(0.15))
            .foregroundStyle(.green)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private func statisticsSection(summary: CompanyDataSummary) -> some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                StatItem(title: "Fakturor", value: "\(summary.invoiceCount)")
                Spacer()
                StatItem(title: "Produkter", value: "\(summary.productCount)")
                Spacer()
                StatItem(title: "Totalt", value: String(format: "%.0f kr", summary.totalInvoiced))
                Spacer()
                StatItem(title: "Senast", value: summary.lastActivity.invoiceTimeString)
            }
            .font(.caption)
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct ManagementActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            LiquidGlassCard.adaptive {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Data Summary View
struct DataSummaryView: View {
    let summaries: [UUID: CompanyDataSummary]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Statistics
                    overallStatisticsSection
                    
                    // Per-Company Statistics
                    perCompanyStatisticsSection
                }
                .padding(20)
            }
            .settingsLiquidBackground()
            .navigationTitle("Datastatistik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Stäng") {
                        dismiss()
                    }
                    .liquidButtonStyle(variant: .ghost, size: .small)
                }
            }
        }
    }
    
    private var overallStatisticsSection: some View {
        VStack(spacing: 16) {
            Text("Total översikt")
                .font(.headline)
                .fontWeight(.semibold)
            
            let totals = calculateTotals()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(title: "Totala fakturor", value: "\(totals.invoices)", color: .blue)
                StatCard(title: "Totala produkter", value: "\(totals.products)", color: .green)
                StatCard(title: "Total omsättning", value: String(format: "%.0f kr", totals.revenue), color: .orange)
                StatCard(title: "Aktiva företag", value: "\(summaries.count)", color: .purple)
            }
        }
    }
    
    private var perCompanyStatisticsSection: some View {
        VStack(spacing: 16) {
            Text("Per företag")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(summaries.values), id: \.companyId) { summary in
                CompanySummaryCard(summary: summary)
            }
        }
    }
    
    private func calculateTotals() -> (invoices: Int, products: Int, revenue: Double) {
        let totals = summaries.values.reduce((0, 0, 0.0)) { result, summary in
            (
                result.0 + summary.invoiceCount,
                result.1 + summary.productCount,
                result.2 + summary.totalInvoiced
            )
        }
        return totals
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        LiquidGlassCard.adaptive {
            VStack(spacing: 8) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
        }
    }
}

struct CompanySummaryCard: View {
    let summary: CompanyDataSummary
    
    var body: some View {
        LiquidGlassCard.adaptive {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Företag")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(summary.lastActivity.invoiceTimeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(summary.invoiceCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Fakturor")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("\(summary.productCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Produkter")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.0f kr", summary.totalInvoiced))
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Omsättning")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    CompanyManagementView()
        .environmentObject(CompanyManager())
}

