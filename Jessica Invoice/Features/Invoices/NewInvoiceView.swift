//
//  NewInvoiceView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

struct NewInvoiceView: View {
    @EnvironmentObject var invoiceViewModel: InvoiceViewModel
    @EnvironmentObject var productViewModel: ProductViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var invoice: Invoice
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingProductPicker = false
    @State private var showingClientForm = false
    
    init(invoice: Invoice = Invoice()) {
        _invoice = State(initialValue: invoice)
    }
    
    var isEditMode: Bool {
        invoiceViewModel.invoices.contains { $0.id == invoice.id }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Invoice Header
                    InvoiceHeaderSection(invoice: $invoice, showingClientForm: $showingClientForm)
                    
                    // Invoice Items
                    InvoiceItemsSection(
                        invoice: $invoice,
                        showingProductPicker: $showingProductPicker
                    )
                    
                    // Invoice Totals
                    InvoiceTotalsSection(invoice: invoice)
                    
                    // Invoice Settings
                    InvoiceSettingsSection(invoice: $invoice)
                    
                    // Notes
                    NotesSection(invoice: $invoice)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(GradientBackground.invoice)
            .navigationTitle(isEditMode ? "Redigera Faktura" : "Ny Faktura")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditMode ? "Uppdatera" : "Spara") {
                        saveInvoice()
                    }
                    .fontWeight(.semibold)
                    .disabled(invoice.items.isEmpty || invoice.client.name.isEmpty)
                    .loadingButton(isLoading: isLoading)
                }
            }
            .sheet(isPresented: $showingProductPicker) {
                ProductPickerView(selectedItems: $invoice.items)
            }
            .sheet(isPresented: $showingClientForm) {
                ClientFormView(client: $invoice.client)
            }
            .errorAlert(isPresented: $showingError, error: InvoiceError(message: errorMessage ?? ""))
        }
    }
    
    private func saveInvoice() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await invoiceViewModel.saveInvoice(invoice)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Invoice Header Section
struct InvoiceHeaderSection: View {
    @Binding var invoice: Invoice
    @Binding var showingClientForm: Bool
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Fakturahuvud")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                // Invoice Number and Date
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fakturanummer")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        TextField("Fakturanummer", text: $invoice.number)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Datum")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        DatePicker("", selection: $invoice.date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                // Client Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Kund")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button("Redigera") {
                            showingClientForm = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                    
                    if invoice.client.name.isEmpty {
                        Button {
                            showingClientForm = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.blue)
                                Text("Lägg till kund")
                                    .foregroundStyle(.blue)
                                Spacer()
                            }
                            .padding(16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(invoice.client.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            if !invoice.client.contactPerson.isEmpty {
                                Text("Att: \(invoice.client.contactPerson)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if !invoice.client.address.street.isEmpty {
                                Text(invoice.client.address.formatted)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if !invoice.client.email.isEmpty {
                                Text(invoice.client.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Invoice Items Section
struct InvoiceItemsSection: View {
    @Binding var invoice: Invoice
    @Binding var showingProductPicker: Bool
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Artiklar")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button {
                        showingProductPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Lägg till")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                    .buttonStyle(SecondaryButtonStyle(color: .blue))
                }
                
                if invoice.items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        
                        Text("Inga artiklar tillagda")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button("Lägg till artiklar") {
                            showingProductPicker = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(32)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(invoice.items.enumerated()), id: \.element.id) { index, item in
                            InvoiceItemRow(
                                item: Binding(
                                    get: { invoice.items[index] },
                                    set: { invoice.items[index] = $0 }
                                ),
                                onDelete: {
                                    invoice.items.remove(at: index)
                                }
                            )
                            
                            if index < invoice.items.count - 1 {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Invoice Item Row
struct InvoiceItemRow: View {
    @Binding var item: InvoiceItem
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Beskrivning", text: $item.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Antal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("0", value: $item.quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enhet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("st", text: $item.unit)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pris")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("0", value: $item.unitPrice, format: .currency(code: "SEK"))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Totalt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "%.0f kr", item.total))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Invoice Totals Section
struct InvoiceTotalsSection: View {
    let invoice: Invoice
    
    var body: some View {
        GlassCard {
            VStack(alignment: .trailing, spacing: 12) {
                HStack {
                    Text("Totaler")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Exkl. moms:")
                        Spacer()
                        Text(String(format: "%.0f kr", invoice.subtotal))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Moms (\(String(format: "%.0f", invoice.vatRate))%):")
                        Spacer()
                        Text(String(format: "%.0f kr", invoice.vatAmount))
                            .fontWeight(.medium)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("ATT BETALA:")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                        Text(String(format: "%.0f kr", invoice.total))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                }
                .font(.subheadline)
            }
            .padding(20)
        }
    }
}

// MARK: - Invoice Settings Section
struct InvoiceSettingsSection: View {
    @Binding var invoice: Invoice
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Inställningar")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Betalningsvillkor")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Picker("Betalningsvillkor", selection: $invoice.paymentTerms) {
                            Text("14 dagar").tag(14)
                            Text("30 dagar").tag(30)
                            Text("60 dagar").tag(60)
                            Text("90 dagar").tag(90)
                        }
                        .pickerStyle(.menu)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Förfallodatum")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(invoice.dueDate.displayFormat)
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Valuta")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Picker("Valuta", selection: $invoice.currency) {
                            Text("SEK").tag("SEK")
                            Text("EUR").tag("EUR")
                            Text("USD").tag("USD")
                        }
                        .pickerStyle(.menu)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Moms %")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("25", value: $invoice.vatRate, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Notes Section
struct NotesSection: View {
    @Binding var invoice: Invoice
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Anmärkningar")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextField(
                    "Lägg till anmärkningar eller betalningsvillkor...",
                    text: $invoice.notes,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)
        }
    }
}

// MARK: - Supporting Views and Errors
struct InvoiceError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

#Preview {
    NewInvoiceView()
        .environmentObject(InvoiceViewModel())
        .environmentObject(ProductViewModel())
}