//
//  HistoryView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var invoiceViewModel: InvoiceViewModel
    @State private var showingFilters = false
    @State private var selectedDateRange: DateRange = .all
    @State private var showingInvoiceDetail = false
    @State private var selectedInvoice: Invoice?
    
    enum DateRange: String, CaseIterable {
        case all = "Alla"
        case thisMonth = "Denna månad"
        case last30Days = "Senaste 30 dagarna"
        case thisYear = "Detta år"
        case lastYear = "Förra året"
        
        var dateRange: ClosedRange<Date>? {
            switch self {
            case .all:
                return nil
            case .thisMonth:
                return Date.thisMonth
            case .last30Days:
                return Date.last30Days
            case .thisYear:
                return Date.thisYear
            case .lastYear:
                return Date.lastYear
            }
        }
    }
    
    var filteredInvoices: [Invoice] {
        var invoices = invoiceViewModel.filteredInvoices
        
        if let range = selectedDateRange.dateRange {
            invoices = invoices.filter { range.contains($0.date) }
        }
        
        return invoices
    }
    
    var totalAmount: Double {
        filteredInvoices.reduce(0) { $0 + $1.total }
    }
    
    var paidAmount: Double {
        filteredInvoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.total }
    }
    
    var outstandingAmount: Double {
        filteredInvoices.filter { $0.status == .sent }.reduce(0) { $0 + $1.total }
    }
    
    var overdueAmount: Double {
        filteredInvoices.filter { $0.isOverdue }.reduce(0) { $0 + $1.total }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.orange.gradient)
                        
                        Text("Fakturahistorik")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        
                        Text("Översikt av alla dina fakturor")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 32)
                    
                    // Statistics Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        HistoryStatCard(
                            title: "Totalt",
                            value: String(format: "%.0f kr", totalAmount),
                            icon: "chart.bar.fill",
                            color: .blue,
                            subtitle: "\(filteredInvoices.count) fakturor"
                        )
                        
                        HistoryStatCard(
                            title: "Betalt",
                            value: String(format: "%.0f kr", paidAmount),
                            icon: "checkmark.circle.fill",
                            color: .green,
                            subtitle: percentageString(paidAmount, of: totalAmount)
                        )
                        
                        HistoryStatCard(
                            title: "Utestående",
                            value: String(format: "%.0f kr", outstandingAmount),
                            icon: "clock.fill",
                            color: .orange,
                            subtitle: percentageString(outstandingAmount, of: totalAmount)
                        )
                        
                        HistoryStatCard(
                            title: "Förfallet",
                            value: String(format: "%.0f kr", overdueAmount),
                            icon: "exclamationmark.triangle.fill",
                            color: .red,
                            subtitle: percentageString(overdueAmount, of: totalAmount)
                        )
                    }
                    
                    // Search and Filter
                    GlassCard {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                
                                TextField("Sök fakturor...", text: $invoiceViewModel.searchText)
                                    .textFieldStyle(.plain)
                                
                                if !invoiceViewModel.searchText.isEmpty {
                                    Button {
                                        invoiceViewModel.searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Button {
                                    showingFilters.toggle()
                                } label: {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            
                            if showingFilters {
                                VStack(spacing: 12) {
                                    // Status Filter
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            StatusPill(
                                                title: "Alla",
                                                isSelected: invoiceViewModel.selectedStatus == nil
                                            ) {
                                                invoiceViewModel.selectedStatus = nil
                                            }
                                            
                                            ForEach(InvoiceStatus.allCases, id: \.self) { status in
                                                StatusPill(
                                                    title: status.displayName,
                                                    isSelected: invoiceViewModel.selectedStatus == status,
                                                    color: status.color
                                                ) {
                                                    invoiceViewModel.selectedStatus = invoiceViewModel.selectedStatus == status ? nil : status
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                    
                                    // Date Range Filter
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(DateRange.allCases, id: \.self) { range in
                                                DateRangePill(
                                                    title: range.rawValue,
                                                    isSelected: selectedDateRange == range
                                                ) {
                                                    selectedDateRange = range
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                    
                    // Invoice List or Empty State
                    if filteredInvoices.isEmpty {
                        HistoryEmptyState(
                            hasInvoices: !invoiceViewModel.invoices.isEmpty,
                            searchText: invoiceViewModel.searchText,
                            onClearFilters: {
                                invoiceViewModel.clearFilters()
                                selectedDateRange = .all
                            }
                        )
                    } else {
                        GlassCard {
                            VStack(spacing: 0) {
                                ForEach(Array(filteredInvoices.enumerated()), id: \.element.id) { index, invoice in
                                    HistoricalInvoiceRow(invoice: invoice) {
                                        selectedInvoice = invoice
                                        showingInvoiceDetail = true
                                    }
                                    
                                    if index < filteredInvoices.count - 1 {
                                        Divider()
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(GradientBackground.history)
            .navigationBarHidden(true)
            .refreshable {
                invoiceViewModel.loadInvoices()
            }
        }
        .searchable(text: $invoiceViewModel.searchText, prompt: "Sök fakturor...")
        .sheet(isPresented: $showingInvoiceDetail) {
            if let invoice = selectedInvoice {
                InvoiceDetailView(invoice: invoice)
            }
        }
        .onAppear {
            if invoiceViewModel.invoices.isEmpty {
                invoiceViewModel.loadInvoices()
            }
        }
    }
    
    private func percentageString(_ value: Double, of total: Double) -> String {
        guard total > 0 else { return "0%" }
        let percentage = (value / total) * 100
        return String(format: "%.0f%%", percentage)
    }
}

// MARK: - History Stat Card
struct HistoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                    Spacer()
                }
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Status Pill
struct StatusPill: View {
    let title: String
    let isSelected: Bool
    var color: Color = .orange
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? color.opacity(0.2) : .ultraThinMaterial)
                        .stroke(isSelected ? color.opacity(0.3) : .clear, lineWidth: 1)
                )
                .foregroundStyle(isSelected ? color : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Range Pill
struct DateRangePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? .blue.opacity(0.2) : .ultraThinMaterial)
                        .stroke(isSelected ? .blue.opacity(0.3) : .clear, lineWidth: 1)
                )
                .foregroundStyle(isSelected ? .blue : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Historical Invoice Row
struct HistoricalInvoiceRow: View {
    let invoice: Invoice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Circle()
                    .fill(invoice.status.color.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: invoice.status.icon)
                            .font(.title3)
                            .foregroundStyle(invoice.status.color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(invoice.client.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(invoice.formattedNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Text(invoice.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(invoice.status.color.opacity(0.1))
                            .foregroundStyle(invoice.status.color)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        Text(invoice.date.invoiceTimeString)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.0f kr", invoice.total))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    if invoice.isOverdue {
                        Text("Förfallen")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                    } else if invoice.status == .sent {
                        Text(invoice.dueDate.dueDateString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(invoice.date.displayFormat)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - History Empty State
struct HistoryEmptyState: View {
    let hasInvoices: Bool
    let searchText: String
    let onClearFilters: () -> Void
    
    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                if hasInvoices && !searchText.isEmpty {
                    // No search results
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("Inga fakturor hittades")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Försök med ett annat sökord eller ändra filtren")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                    
                    Button("Rensa filter") {
                        onClearFilters()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    // No invoices at all
                    Image(systemName: "doc.text.badge.plus")
                        .font(.system(size: 64))
                        .foregroundStyle(.orange.opacity(0.6))
                    
                    Text("Inga fakturor ännu")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("När du skapat din första faktura kommer den att visas här")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(40)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(InvoiceViewModel())
}
