//
//  InvoiceViewModel.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import Foundation
import SwiftUI

@MainActor
class InvoiceViewModel: ObservableObject {
    @Published var invoices: [Invoice] = []
    @Published var filteredInvoices: [Invoice] = []
    @Published var searchText: String = "" {
        didSet { filterInvoices() }
    }
    @Published var selectedStatus: InvoiceStatus? {
        didSet { filterInvoices() }
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Current invoice being edited
    @Published var currentInvoice: Invoice?
    @Published var isEditingInvoice: Bool = false
    
    private let dataManager = DataManager.shared
    
    init() {
        loadInvoices()
    }
    
    // MARK: - Data Loading
    func loadInvoices() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let loadedInvoices = try await dataManager.loadInvoices()
                self.invoices = loadedInvoices
                self.filterInvoices()
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Filtering
    private func filterInvoices() {
        filteredInvoices = invoices.filter { invoice in
            let matchesSearch = searchText.isEmpty ||
                                invoice.client.name.localizedCaseInsensitiveContains(searchText) ||
                                invoice.number.localizedCaseInsensitiveContains(searchText) ||
                                invoice.formattedNumber.localizedCaseInsensitiveContains(searchText)
            
            let matchesStatus = selectedStatus == nil || invoice.status == selectedStatus
            
            return matchesSearch && matchesStatus
        }.sorted { $0.date > $1.date }
    }
    
    // MARK: - Invoice Operations
    func createNewInvoice() {
        let activeCompanyId: UUID? = {
            if let idString = UserDefaults.standard.string(forKey: "activeCompanyId") {
                return UUID(uuidString: idString)
            }
            return nil
        }()
        let newInvoice = Invoice(
            companyId: activeCompanyId,
            number: generateInvoiceNumber(),
            date: Date(),
            client: Client(),
            items: []
        )
        currentInvoice = newInvoice
        isEditingInvoice = true
    }
    
    func saveInvoice(_ invoice: Invoice) async throws {
        if let index = invoices.firstIndex(where: { $0.id == invoice.id }) {
            invoices[index] = invoice
        } else {
            invoices.append(invoice)
        }
        
        try await dataManager.saveInvoices(invoices)
        filterInvoices()
        currentInvoice = nil
        isEditingInvoice = false
    }
    
    func deleteInvoice(_ invoice: Invoice) async throws {
        invoices.removeAll { $0.id == invoice.id }
        try await dataManager.saveInvoices(invoices)
        filterInvoices()
    }
    
    func duplicateInvoice(_ invoice: Invoice) {
        var duplicated = invoice
        duplicated.number = generateInvoiceNumber()
        duplicated.date = Date()
        duplicated.status = .draft
        
        currentInvoice = duplicated
        isEditingInvoice = true
    }
    
    func updateInvoiceStatus(_ invoice: Invoice, to status: InvoiceStatus) async throws {
        guard let index = invoices.firstIndex(where: { $0.id == invoice.id }) else { return }
        
        invoices[index].status = status
        
        if status == .paid {
            // Send notification that invoice was paid
            NotificationManager.shared.sendInvoicePaidNotification(invoice)
        }
        
        try await dataManager.saveInvoices(invoices)
        filterInvoices()
    }
    
    // MARK: - Statistics
    var totalInvoiced: Double {
        invoices.reduce(0) { $0 + $1.total }
    }
    
    var totalPaid: Double {
        invoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.total }
    }
    
    var totalOutstanding: Double {
        invoices.filter { $0.status == .sent }.reduce(0) { $0 + $1.total }
    }
    
    var totalOverdue: Double {
        invoices.filter { $0.isOverdue }.reduce(0) { $0 + $1.total }
    }
    
    var recentInvoices: [Invoice] {
        Array(invoices.sorted { $0.date > $1.date }.prefix(5))
    }
    
    var overdueInvoices: [Invoice] {
        invoices.filter { $0.isOverdue }
    }
    
    // MARK: - Invoice Number Generation
    private func generateInvoiceNumber() -> String {
        let currentYear = Calendar.current.component(.year, from: Date())
        let yearString = String(currentYear)
        
        let invoicesThisYear = invoices.filter { invoice in
            Calendar.current.component(.year, from: invoice.date) == currentYear
        }
        
        let nextNumber = invoicesThisYear.count + 1
        return String(format: "%@-%03d", yearString, nextNumber)
    }
    
    // MARK: - Export Functions
    func exportInvoiceToPDF(_ invoice: Invoice) async throws -> Data {
        return try await PDFGenerator.shared.generateInvoicePDF(invoice)
    }
    
    func shareInvoice(_ invoice: Invoice) async throws -> URL {
        let pdfData = try await exportInvoiceToPDF(invoice)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Invoice_\(invoice.formattedNumber).pdf")
        
        try pdfData.write(to: tempURL)
        return tempURL
    }
    
    // MARK: - Validation
    func validateInvoice(_ invoice: Invoice) -> [String] {
        var errors: [String] = []
        
        if invoice.client.name.isEmpty {
            errors.append("Kundnamn saknas")
        }
        
        if invoice.items.isEmpty {
            errors.append("Inga artiklar har lagts till")
        }
        
        if invoice.items.contains(where: { $0.description.isEmpty }) {
            errors.append("Artikelbeskrivning saknas")
        }
        
        if invoice.items.contains(where: { $0.unitPrice <= 0 }) {
            errors.append("Pris måste vara större än 0")
        }
        
        return errors
    }
    
    // MARK: - Bulk Operations
    func bulkUpdateStatus(_ invoices: [Invoice], to status: InvoiceStatus) async throws {
        for invoice in invoices {
            try await updateInvoiceStatus(invoice, to: status)
        }
    }
    
    func bulkDelete(_ invoicesToDelete: [Invoice]) async throws {
        invoices.removeAll { invoice in
            invoicesToDelete.contains { $0.id == invoice.id }
        }
        try await dataManager.saveInvoices(invoices)
        filterInvoices()
    }
    
    // MARK: - Search & Filter Helpers
    func clearFilters() {
        searchText = ""
        selectedStatus = nil
    }
    
    func getInvoicesByStatus(_ status: InvoiceStatus) -> [Invoice] {
        invoices.filter { $0.status == status }
    }
    
    func getInvoicesByDateRange(from startDate: Date, to endDate: Date) -> [Invoice] {
        invoices.filter { invoice in
            invoice.date >= startDate && invoice.date <= endDate
        }
    }
}
