//
//  ProductViewModel.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import Foundation
import SwiftUI

@MainActor
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var searchText: String = "" {
        didSet { filterProducts() }
    }
    @Published var selectedCategory: ProductCategory? {
        didSet { filterProducts() }
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Current product being edited
    @Published var currentProduct: Product?
    @Published var isEditingProduct: Bool = false
    
    private let dataManager = DataManager.shared
    
    init() {
        loadProducts()
    }
    
    // MARK: - Data Loading
    func loadProducts() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let loadedProducts = try await dataManager.loadProducts()
                self.products = loadedProducts
                self.filterProducts()
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Filtering
    private func filterProducts() {
        filteredProducts = products.filter { product in
            let matchesSearch = searchText.isEmpty ||
                                product.name.localizedCaseInsensitiveContains(searchText) ||
                                product.description.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || product.category == selectedCategory
            let isActive = product.isActive
            
            return matchesSearch && matchesCategory && isActive
        }.sorted { $0.name < $1.name }
    }
    
    // MARK: - Product Operations
    func createNewProduct() {
        currentProduct = Product()
        isEditingProduct = true
    }
    
    func editProduct(_ product: Product) {
        currentProduct = product
        isEditingProduct = true
    }
    
    func saveProduct(_ product: Product) async throws {
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products[index] = product
        } else {
            products.append(product)
        }
        
        try await dataManager.saveProducts(products)
        filterProducts()
        currentProduct = nil
        isEditingProduct = false
    }
    
    func deleteProduct(_ product: Product) async throws {
        // Check if product is used in any invoices before deleting
        let isUsed = try await isProductUsedInInvoices(product)
        
        if isUsed {
            // Instead of deleting, mark as inactive
            if let index = products.firstIndex(where: { $0.id == product.id }) {
                products[index].isActive = false
            }
        } else {
            products.removeAll { $0.id == product.id }
        }
        
        try await dataManager.saveProducts(products)
        filterProducts()
    }
    
    func duplicateProduct(_ product: Product) {
        var duplicated = product
        duplicated.name = "\(product.name) (Kopia)"
        
        currentProduct = duplicated
        isEditingProduct = true
    }
    
    func toggleProductActive(_ product: Product) async throws {
        guard let index = products.firstIndex(where: { $0.id == product.id }) else { return }
        
        products[index].isActive.toggle()
        try await dataManager.saveProducts(products)
        filterProducts()
    }
    
    // MARK: - Statistics
    var totalProducts: Int {
        products.filter { $0.isActive }.count
    }
    
    var productsByCategory: [ProductCategory: [Product]] {
        Dictionary(grouping: products.filter { $0.isActive }) { $0.category }
    }
    
    var averagePrice: Double {
        let activeProducts = products.filter { $0.isActive }
        guard !activeProducts.isEmpty else { return 0 }
        return activeProducts.reduce(0) { $0 + $1.price } / Double(activeProducts.count)
    }
    
    var mostUsedProducts: [Product] {
        products
            .filter { $0.isActive && $0.lastUsed != nil }
            .sorted { ($0.lastUsed ?? Date.distantPast) > ($1.lastUsed ?? Date.distantPast) }
    }
    
    var recentlyAddedProducts: [Product] {
        products
            .filter { $0.isActive }
            .sorted { $0.createdDate > $1.createdDate }
    }
    
    // MARK: - Categories
    var availableCategories: [ProductCategory] {
        ProductCategory.allCases
    }
    
    func getProductCount(for category: ProductCategory) -> Int {
        products.filter { $0.category == category && $0.isActive }.count
    }
    
    // MARK: - Search & Filter Helpers
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
    }
    
    func getProductsByCategory(_ category: ProductCategory) -> [Product] {
        products.filter { $0.category == category && $0.isActive }
    }
    
    func getProductsByPriceRange(min: Double, max: Double) -> [Product] {
        products.filter { product in
            product.isActive && product.price >= min && product.price <= max
        }
    }
    
    // MARK: - Validation
    func validateProduct(_ product: Product) -> [String] {
        var errors: [String] = []
        
        if product.name.isEmpty {
            errors.append("Produktnamn saknas")
        }
        
        if product.price <= 0 {
            errors.append("Pris måste vara större än 0")
        }
        
        if product.unit.isEmpty {
            errors.append("Enhet saknas")
        }
        
        if product.vatRate < 0 || product.vatRate > 100 {
            errors.append("Moms måste vara mellan 0 och 100 procent")
        }
        
        // Check for duplicate names
        let existingProduct = products.first { existingProduct in
            existingProduct.name.lowercased() == product.name.lowercased() &&
            existingProduct.id != product.id &&
            existingProduct.isActive
        }
        
        if existingProduct != nil {
            errors.append("En produkt med detta namn finns redan")
        }
        
        return errors
    }
    
    // MARK: - Import/Export
    func exportProductsToCSV() async throws -> Data {
        let headers = ["Namn", "Beskrivning", "Pris", "Enhet", "Kategori", "Moms %"]
        let csvContent = [headers.joined(separator: ",")] +
                        products.filter { $0.isActive }.map { product in
            [
                product.name,
                product.description,
                String(product.price),
                product.unit,
                product.category.displayName,
                String(product.vatRate)
            ].joined(separator: ",")
        }
        
        return csvContent.joined(separator: "\n").data(using: .utf8) ?? Data()
    }
    
    func importProductsFromCSV(_ data: Data) async throws {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ProductError.invalidFileFormat
        }
        
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw ProductError.emptyFile
        }
        
        // Skip header line
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            let columns = line.components(separatedBy: ",")
            guard columns.count >= 6 else { continue }
            
            let product = Product(
                name: columns[0],
                description: columns[1],
                price: Double(columns[2]) ?? 0,
                unit: columns[3],
                category: ProductCategory.allCases.first { $0.displayName == columns[4] } ?? .service,
                vatRate: Double(columns[5]) ?? 25.0
            )
            
            products.append(product)
        }
        
        try await dataManager.saveProducts(products)
        filterProducts()
    }
    
    // MARK: - Usage Tracking
    func markProductAsUsed(_ product: Product) async throws {
        guard let index = products.firstIndex(where: { $0.id == product.id }) else { return }
        
        products[index].lastUsed = Date()
        try await dataManager.saveProducts(products)
    }
    
    private func isProductUsedInInvoices(_ product: Product) async throws -> Bool {
        let invoices = try await dataManager.loadInvoices()
        return invoices.contains { invoice in
            invoice.items.contains { item in
                item.description == product.name
            }
        }
    }
    
    // MARK: - Bulk Operations
    func bulkDelete(_ productsToDelete: [Product]) async throws {
        for product in productsToDelete {
            try await deleteProduct(product)
        }
    }
    
    func bulkUpdateCategory(_ products: [Product], to category: ProductCategory) async throws {
        for product in products {
            guard let index = self.products.firstIndex(where: { $0.id == product.id }) else { continue }
            self.products[index].category = category
        }
        
        try await dataManager.saveProducts(self.products)
        filterProducts()
    }
    
    func bulkUpdateVatRate(_ products: [Product], to vatRate: Double) async throws {
        for product in products {
            guard let index = self.products.firstIndex(where: { $0.id == product.id }) else { continue }
            self.products[index].vatRate = vatRate
        }
        
        try await dataManager.saveProducts(self.products)
        filterProducts()
    }
}

// MARK: - Product Errors
enum ProductError: LocalizedError {
    case invalidFileFormat
    case emptyFile
    case productInUse
    
    var errorDescription: String? {
        switch self {
        case .invalidFileFormat:
            return "Ogiltigt filformat"
        case .emptyFile:
            return "Filen är tom"
        case .productInUse:
            return "Produkten används i befintliga fakturor"
        }
    }
}
