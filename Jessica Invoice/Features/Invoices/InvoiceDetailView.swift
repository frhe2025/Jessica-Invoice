//
//  InvoiceDetailView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//


import SwiftUI
import PDFKit

struct InvoiceDetailView: View {
    @EnvironmentObject var invoiceViewModel: InvoiceViewModel
    @Environment(\.dismiss) var dismiss
    
    let invoice: Invoice
    
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingStatusPicker = false
    @State private var showingPDFPreview = false
    @State private var isLoading = false
    @State private var shareURL: URL?
    @State private var pdfData: Data?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Header
                    InvoiceStatusHeader(invoice: invoice, showingStatusPicker: $showingStatusPicker)
                    
                    // Client Information
                    ClientInformationCard(client: invoice.client)
                    
                    // Invoice Details
                    InvoiceDetailsCard(invoice: invoice)
                    
                    // Invoice Items
                    InvoiceItemsCard(items: invoice.items)
                    
                    // Totals
                    InvoiceTotalsCard(invoice: invoice)
                    
                    // Payment Information
                    if invoice.status == .sent || invoice.status == .overdue {
                        PaymentInformationCard(invoice: invoice)
                    }
                    
                    // Actions
                    InvoiceActionsCard(
                        invoice: invoice,
                        showingEditSheet: $showingEditSheet,
                        showingShareSheet: $showingShareSheet,
                        showingPDFPreview: $showingPDFPreview,
                        showingDeleteAlert: $showingDeleteAlert
                    )
                    
                    // Notes
                    if !invoice.notes.isEmpty {
                        InvoiceNotesCard(notes: invoice.notes)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(GradientBackground.invoice)
            .navigationTitle(invoice.formattedNumber)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Tillbaka") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Redigera") {
                            showingEditSheet = true
                        }
                        
                        Button("Dela") {
                            shareInvoice()
                        }
                        
                        Button("Visa PDF") {
                            generatePDF()
                        }
                        
                        Divider()
                        
                        Button("Duplicera") {
                            duplicateInvoice()
                        }
                        
                        Button("Ta bort", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                NewInvoiceView(invoice: invoice)
            }
            .sheet(isPresented: $showingPDFPreview) {
                if let pdfData = pdfData {
                    PDFPreviewView(pdfData: pdfData, fileName: "Faktura_\(invoice.formattedNumber)")
                }
            }
            .shareSheet(
                isPresented: $showingShareSheet,
                items: shareURL != nil ? [shareURL!] : [],
                completion: { _, _, _, _ in
                    shareURL = nil
                }
            )
            .confirmationDialog(
                "Ändra status",
                isPresented: $showingStatusPicker,
                titleVisibility: .visible
            ) {
                ForEach(InvoiceStatus.allCases, id: \.self) { status in
                    if status != invoice.status {
                        Button(status.displayName) {
                            updateStatus(to: status)
                        }
                    }
                }
                
                Button("Avbryt", role: .cancel) {}
            }
            .alert("Ta bort faktura", isPresented: $showingDeleteAlert) {
                Button("Ta bort", role: .destructive) {
                    deleteInvoice()
                }
                Button("Avbryt", role: .cancel) {}
            } message: {
                Text("Är du säker på att du vill ta bort denna faktura? Denna åtgärd kan inte ångras.")
            }
            .errorAlert(isPresented: $showingError, error: InvoiceDetailError(message: errorMessage ?? ""))
        }
    }
    
    private func updateStatus(to status: InvoiceStatus) {
        Task {
            do {
                try await invoiceViewModel.updateInvoiceStatus(invoice, to: status)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func shareInvoice() {
        isLoading = true
        
        Task {
            do {
                let url = try await invoiceViewModel.shareInvoice(invoice)
                await MainActor.run {
                    shareURL = url
                    showingShareSheet = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func generatePDF() {
        isLoading = true
        
        Task {
            do {
                let data = try await invoiceViewModel.exportInvoiceToPDF(invoice)
                await MainActor.run {
                    pdfData = data
                    showingPDFPreview = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func duplicateInvoice() {
        invoiceViewModel.duplicateInvoice(invoice)
        dismiss()
    }
    
    private func deleteInvoice() {
        Task {
            do {
                try await invoiceViewModel.deleteInvoice(invoice)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Invoice Status Header
struct InvoiceStatusHeader: View {
    let invoice: Invoice
    @Binding var showingStatusPicker: Bool
    
    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Circle()
                        .fill(invoice.status.color.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: invoice.status.icon)
                                .font(.title)
                                .foregroundStyle(invoice.status.color)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(invoice.status.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(invoice.status.color)
                        
                        Text(invoice.status.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if invoice.isOverdue {
                            Text("Förföll \(invoice.dueDate.invoiceTimeString)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Ändra") {
                        showingStatusPicker = true
                    }
                    .buttonStyle(SecondaryButtonStyle(color: invoice.status.color))
                }
                
                if invoice.status == .sent && !invoice.isOverdue {
                    VStack(spacing: 8) {
                        ProgressView(value: invoice.daysSince(), total: Double(invoice.paymentTerms))
                            .tint(invoice.dueDate.daysUntil() <= 7 ? .orange : .blue)
                        
                        HStack {
                            Text("Skickad \(invoice.date.invoiceTimeString)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text(invoice.dueDate.dueDateString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Client Information Card
struct ClientInformationCard: View {
    let client: Client
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Kunduppgifter")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(client.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if !client.contactPerson.isEmpty {
                        Text("Att: \(client.contactPerson)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !client.address.street.isEmpty {
                        Text(client.address.street)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("\(client.address.postalCode) \(client.address.city)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !client.organizationNumber.isEmpty {
                        Text("Org.nr: \(client.organizationNumber)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                if !client.email.isEmpty || !client.phone.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if !client.email.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "envelope")
                                    .foregroundStyle(.secondary)
                                
                                Text(client.email)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Button("Mejla") {
                                    if let url = URL(string: "mailto:\(client.email)") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.blue)
                            }
                        }
                        
                        if !client.phone.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "phone")
                                    .foregroundStyle(.secondary)
                                
                                Text(client.phone)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Button("Ring") {
                                    if let url = URL(string: "tel:\(client.phone)") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Invoice Details Card
struct InvoiceDetailsCard: View {
    let invoice: Invoice
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Fakturauppgifter")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    DetailRow(title: "Fakturanummer", value: invoice.formattedNumber)
                    DetailRow(title: "Fakturadatum", value: invoice.date.displayFormat)
                    DetailRow(title: "Förfallodatum", value: invoice.dueDate.displayFormat)
                    DetailRow(title: "Betalningsvillkor", value: "\(invoice.paymentTerms) dagar")
                    DetailRow(title: "Valuta", value: invoice.currency)
                }
            }
            .padding(20)
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Invoice Items Card
struct InvoiceItemsCard: View {
    let items: [InvoiceItem]
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Artiklar")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        InvoiceItemDetailRow(item: item)
                        
                        if index < items.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

struct InvoiceItemDetailRow: View {
    let item: InvoiceItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.description)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(String(format: "%.0f kr", item.total))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            HStack(spacing: 16) {
                Text("\(String(format: "%.1f", item.quantity)) \(item.unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("à \(String(format: "%.0f", item.unitPrice)) kr")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if item.vatRate > 0 {
                    Text("Moms: \(String(format: "%.0f", item.vatRate))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Invoice Totals Card
struct InvoiceTotalsCard: View {
    let invoice: Invoice
    
    var body: some View {
        GlassCard {
            VStack(alignment: .trailing, spacing: 12) {
                Text("Summering")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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

// MARK: - Payment Information Card
struct PaymentInformationCard: View {
    let invoice: Invoice
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "creditcard")
                        .foregroundStyle(.orange)
                    
                    Text("Betalningsinformation")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vänligen betala fakturan senast \(invoice.dueDate.displayFormat)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if invoice.isOverdue {
                        Text("⚠️ Denna faktura har passerat förfallodatum")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                    }
                }
                
                Button("Markera som betald") {
                    // Mark as paid action
                }
                .buttonStyle(PrimaryButtonStyle(color: .green))
            }
            .padding(20)
        }
    }
}

// MARK: - Invoice Actions Card
struct InvoiceActionsCard: View {
    let invoice: Invoice
    @Binding var showingEditSheet: Bool
    @Binding var showingShareSheet: Bool
    @Binding var showingPDFPreview: Bool
    @Binding var showingDeleteAlert: Bool
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Åtgärder")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ActionButton(title: "Redigera", icon: "pencil", color: .blue) {
                        showingEditSheet = true
                    }
                    
                    ActionButton(title: "Dela", icon: "square.and.arrow.up", color: .green) {
                        showingShareSheet = true
                    }
                    
                    ActionButton(title: "Visa PDF", icon: "doc.text", color: .purple) {
                        showingPDFPreview = true
                    }
                    
                    ActionButton(title: "Ta bort", icon: "trash", color: .red) {
                        showingDeleteAlert = true
                    }
                }
            }
            .padding(20)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Invoice Notes Card
struct InvoiceNotesCard: View {
    let notes: String
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Anmärkningar")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }
}

// MARK: - PDF Preview View
struct PDFPreviewView: View {
    let pdfData: Data
    let fileName: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            PDFKitView(data: pdfData)
                .navigationTitle(fileName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Stäng") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: pdfData, preview: SharePreview(fileName)) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {}
}

// MARK: - Invoice Detail Error
struct InvoiceDetailError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

#Preview {
    InvoiceDetailView(
        invoice: Invoice(
            number: "2025-001",
            client: Client(
                name: "Acme AB",
                contactPerson: "Anna Andersson",
                email: "anna@acme.se",
                phone: "08-123 45 67"
            ),
            items: [
                InvoiceItem(description: "Webbutveckling", quantity: 40, unit: "timmar", unitPrice: 1200)
            ],
            status: .sent
        )
    )
    .environmentObject(InvoiceViewModel())
}
