//
//  InvoiceView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16 v1.
//

import SwiftUI

struct InvoiceView: View {
    @EnvironmentObject var invoiceViewModel: InvoiceViewModel
    @State private var showingNewInvoice = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 48, weight: .light))
                                .foregroundStyle(.blue.gradient)
                            
                            Text("Skapa Faktura")
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                            
                            Text("Skapa professionella fakturor snabbt och enkelt")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 32)
                        
                        // Statistics Cards
                        if !invoiceViewModel.invoices.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: geometry.size.width > 700 ? 4 : 2), spacing: 16) {
                                StatisticCard(
                                    title: "Totalt fakturerat",
                                    value: String(format: "%.0f kr", invoiceViewModel.totalInvoiced),
                                    icon: "chart.bar.fill",
                                    color: .blue
                                )
                                
                                StatisticCard(
                                    title: "Betalt",
                                    value: String(format: "%.0f kr", invoiceViewModel.totalPaid),
                                    icon: "checkmark.circle.fill",
                                    color: .green
                                )
                                
                                StatisticCard(
                                    title: "Utestående",
                                    value: String(format: "%.0f kr", invoiceViewModel.totalOutstanding),
                                    icon: "clock.fill",
                                    color: .orange
                                )
                                
                                StatisticCard(
                                    title: "Förfallet",
                                    value: String(format: "%.0f kr", invoiceViewModel.totalOverdue),
                                    icon: "exclamationmark.triangle.fill",
                                    color: .red
                                )
                            }
                        }
                        
                        // Action Cards
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: geometry.size.width > 700 ? 2 : 1), spacing: 16) {
                            // New Invoice Card
                            Button {
                                invoiceViewModel.createNewInvoice()
                            } label: {
                                GlassCard {
                                    VStack(spacing: 12) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.blue)
                                        
                                        Text("Ny Faktura")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        Text("Skapa en ny faktura från början")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(24)
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Template Card
                            Button {
                                // Template action
                            } label: {
                                GlassCard {
                                    VStack(spacing: 12) {
                                        Image(systemName: "doc.badge.plus")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.green)
                                        
                                        Text("Använd Mall")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        Text("Skapa från befintlig mall")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(24)
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        
                        // Recent Invoices
                        if !invoiceViewModel.recentInvoices.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Senaste Fakturor")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    NavigationLink("Visa alla") {
                                        // Navigate to history tab
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                }
                                
                                GlassCard {
                                    VStack(spacing: 0) {
                                        ForEach(Array(invoiceViewModel.recentInvoices.enumerated()), id: \.element.id) { index, invoice in
                                            InvoiceRowView(invoice: invoice) {
                                                // Edit invoice action
                                                invoiceViewModel.currentInvoice = invoice
                                                invoiceViewModel.isEditingInvoice = true
                                            }
                                            
                                            if index < invoiceViewModel.recentInvoices.count - 1 {
                                                Divider()
                                                    .padding(.leading, 16)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        
                        // Overdue Invoices Alert
                        if !invoiceViewModel.overdueInvoices.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.red)
                                        
                                        Text("Förfallna Fakturor")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text("Du har \(invoiceViewModel.overdueInvoices.count) fakturor som har passerat förfallodatum.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    Button("Visa förfallna") {
                                        // Navigate to overdue invoices
                                    }
                                    .buttonStyle(SecondaryButtonStyle(color: .red))
                                }
                                .padding(20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.03), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
            .refreshable {
                invoiceViewModel.loadInvoices()
            }
        }
        .sheet(isPresented: $invoiceViewModel.isEditingInvoice) {
            if let invoice = invoiceViewModel.currentInvoice {
                NewInvoiceView(invoice: invoice)
            }
        }
        .onAppear {
            if invoiceViewModel.invoices.isEmpty {
                invoiceViewModel.loadInvoices()
            }
        }
    }
}

// MARK: - Statistic Card
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
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
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
    }
}

// MARK: - Invoice Row (renamed to avoid conflicts)
struct InvoiceRowView: View {
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

#Preview {
    InvoiceView()
        .environmentObject(InvoiceViewModel())
        .environmentObject(ProductViewModel())
        .environmentObject(SettingsViewModel())
}
