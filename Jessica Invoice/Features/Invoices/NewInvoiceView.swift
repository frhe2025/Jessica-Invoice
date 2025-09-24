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
    
    @State private var invoice: Invoice
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingClientForm = false
    @State private var showingProductPicker = false
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: InvoiceItem?
    
    private let isEditMode: Bool
    
    init(invoice: Invoice? = nil) {
        if let existingInvoice = invoice {
            self._invoice = State(initialValue: existingInvoice)
            self.isEditMode = true
        } else {
            self._invoice = State(initialValue: Invoice())
            self.isEditMode = false
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with invoice number
                        InvoiceHeaderSection(invoice: $invoice, isEditMode: isEditMode)
                        
                        // Client selection
                        ClientSelectionSection(
                            client: $invoice.client,
                            showingClientForm: $showingClientForm
                        )
                        
                        // Invoice details
                        InvoiceDetailsSection(invoice: $invoice)
                        
                        // Items section
                        InvoiceItemsSection(
                            items: $invoice.items,
                            showingProductPicker: $showingProductPicker,
                            onDeleteItem: { item in
                                itemToDelete = item
                                showingDeleteAlert = true
                            }
                        )
                        
                        // Add items button
                        AddItemsButton(showingProductPicker: $showingProductPicker)
                        
                        // Totals section
                        InvoiceTotalsSection(invoice: invoice)
                        
                        // Notes section
                        InvoiceNotesSection(notes: $invoice.notes)
                        
                        // Action buttons
                        InvoiceActionButtons(
                            invoice: invoice,
                            isLoading: isLoading,
                            onSave: saveInvoice,
                            onCancel: { dismiss() }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
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
                    .disabled(isLoading || !canSave)
                    .loadingButton(isLoading: isLoading)
                }
            }
            .sheet(isPresented: $showingClientForm) {
                ClientFormView(client: $invoice.client)
            }
            .sheet(isPresented: $showingProductPicker) {
                ProductPickerView(selectedItems: $invoice.items)
            }
            .alert("Ta bort artikel", isPresented: $showingDeleteAlert) {
                Button("Ta bort", role: .destructive) {
                    if let item = itemToDelete {
                        invoice.items.removeAll { $0.id == item.id }
                    }
                }
                Button("Avbryt", role: .cancel) {
                    itemToDelete = nil
                }
            } message: {
                Text("Är du säker på att du vill ta bort denna artikel?")
            }
            .errorAlert(isPresented: $showingError, error: InvoiceFormError(message: errorMessage ?? ""))
        }
    }
    
    private var canSave: Bool {
        !invoice.client.name.isEmpty && !invoice.items.isEmpty
    }
    
    private func saveInvoice() {
        let validationErrors = invoiceViewModel.validateInvoice(invoice)
        if !validationErrors.isEmpty {
            errorMessage = validationErrors.joined(separator: "\n")
            showingError = true
            return
        }
        
        isLoading = true
        
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
    let isEditMode: Bool
    
    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fakturanummer")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        TextField("Automatisk", text: $invoice.number)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .textFieldStyle(.plain)
                            .disabled(isEditMode)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Status")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Menu {
                            ForEach(InvoiceStatus.allCases, id: \.self) { status in
                                Button(status.displayName) {
                                    invoice.status = status
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: invoice.status.icon)
                                    .font(.caption)
                                Text(invoice.status.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundStyle(invoice.status.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(invoice.status.color.opacity(0.1))
                                    .stroke(invoice.status.color.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                }
                
                if isEditMode {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Skapad")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(invoice.date.displayFormat)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Förfaller")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(invoice.dueDate.displayFormat)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Client Selection Section
struct ClientSelectionSection: View {
    @Binding var client: Client
    @Binding var showingClientForm: Bool
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Kund")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Redigera") {
                        showingClientForm = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
                
                if client.name.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.blue.opacity(0.6))
                        
                        Text("Ingen kund vald")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Lägg till kundinformation för att fortsätta")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Lägg till kund") {
                            showingClientForm = true
                        }
                        .buttonStyle(PrimaryButtonStyle(color: .blue))
                    }
                    .padding(.vertical, 16)
                } else {
                    // Client info display
                    VStack(alignment: .leading, spacing: 8) {
                        Text(client.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if !client.contactPerson.isEmpty {
                            Text("Att: \(client.contactPerson)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !client.address.street.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(client.address.street)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text("\(client.address.postalCode) \(client.address.city)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if !client.organizationNumber.isEmpty {
                            Text("Org.nr: \(client.organizationNumber)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Invoice Details Section
struct InvoiceDetailsSection: View {
    @Binding var invoice: Invoice
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Fakturauppgifter")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fakturadatum")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        DatePicker("", selection: $invoice.date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Betalningsvillkor")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Menu {
                            ForEach([14, 30, 60, 90], id: \.self) { days in
                                Button("\(days) dagar") {
                                    invoice.paymentTerms = days
                                    updateDueDate()
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(invoice.paymentTerms) dagar")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Förfallodatum")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text(invoice.dueDate.displayFormat)
                        .font(.subheadline)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        )
                }
            }
            .padding(20)
        }
        .onChange(of: invoice.date) { _, _ in updateDueDate() }
        .onChange(of: invoice.paymentTerms) { _, _ in updateDueDate() }
    }
    
    private func updateDueDate() {
        invoice.dueDate = Calendar.current.date(byAdding: .day, value: invoice.paymentTerms, to: invoice.date) ?? invoice.date
    }
}

// MARK: - Invoice Items Section
struct InvoiceItemsSection: View {
    @Binding var items: [InvoiceItem]
    @Binding var showingProductPicker: Bool
    let onDeleteItem: (InvoiceItem) -> Void
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Artiklar")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(items.count) st")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.green.opacity(0.6))
                        
                        Text("Inga artiklar tillagda")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Lägg till produkter eller tjänster för att skapa fakturan")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            InvoiceItemRow(
                                item: binding(for: item),
                                onDelete: { onDeleteItem(item) }
                            )
                            
                            if index < items.count - 1 {
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
    
    private func binding(for item: InvoiceItem) -> Binding<InvoiceItem> {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return .constant(item)
        }
        return $items[index]
    }
}

// MARK: - Invoice Item Row
struct InvoiceItemRow: View {
    @Binding var item: InvoiceItem
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Beskrivning", text: $item.description)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .textFieldStyle(.plain)
                
                Spacer()
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Antal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("1", value: $item.quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.ultraThinMaterial)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enhet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("st", text: $item.unit)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.ultraThinMaterial)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pris")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("0", value: $item.unitPrice, format: .currency(code: "SEK"))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.ultraThinMaterial)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Summa")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "%.0f kr", item.total))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.ultraThinMaterial)
                        )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Add Items Button
struct AddItemsButton: View {
    @Binding var showingProductPicker: Bool
    
    var body: some View {
        Button {
            showingProductPicker = true
        } label: {
            GlassCard {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lägg till artiklar")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Välj från produktbiblioteket")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Invoice Totals Section
struct InvoiceTotalsSection: View {
    let invoice: Invoice
    
    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Summering")
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
                            .font(.title2)
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

// MARK: - Invoice Notes Section
struct InvoiceNotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Anmärkningar")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextField(
                    "Lägg till kommentarer eller specialinstruktioner...",
                    text: $notes,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
            }
            .padding(20)
        }
    }
}

// MARK: - Invoice Action Buttons
struct InvoiceActionButtons: View {
    let invoice: Invoice
    let isLoading: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button("Avbryt") {
                onCancel()
            }
            .buttonStyle(SecondaryButtonStyle())
            .frame(maxWidth: .infinity)
            
            Button("Spara faktura") {
                onSave()
            }
            .buttonStyle(PrimaryButtonStyle(color: .blue, isLoading: isLoading))
            .frame(maxWidth: .infinity)
            .disabled(isLoading)
        }
    }
}

// MARK: - Invoice Form Error
struct InvoiceFormError: LocalizedError {
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
