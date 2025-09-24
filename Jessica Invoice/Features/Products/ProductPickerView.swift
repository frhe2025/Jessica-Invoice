//
//  ProductPickerView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//


import SwiftUI

struct ProductPickerView: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var selectedItems: [InvoiceItem]
    
    @State private var searchText = ""
    @State private var selectedCategory: ProductCategory?
    
    var filteredProducts: [Product] {
        productViewModel.products.filter { product in
            product.isActive &&
            (selectedCategory == nil || product.category == selectedCategory) &&
            (searchText.isEmpty || 
             product.name.localizedCaseInsensitiveContains(searchText) ||
             product.description.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Section
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Sök produkter...", text: $searchText)
                            .textFieldStyle(.plain)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryFilterPill(
                                title: "Alla",
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(ProductCategory.allCases, id: \.self) { category in
                                CategoryFilterPill(
                                    title: category.displayName,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                
                // Products List
                if filteredProducts.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "cart.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text("Inga produkter hittades")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        if !searchText.isEmpty {
                            Text("Försök med ett annat sökord")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredProducts) { product in
                            ProductPickerRow(
                                product: product,
                                isSelected: selectedItems.contains { $0.description == product.name },
                                onToggle: {
                                    toggleProduct(product)
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(GradientBackground.products)
            .navigationTitle("Välj Produkter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Klar") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if productViewModel.products.isEmpty {
                productViewModel.loadProducts()
            }
        }
    }
    
    private func toggleProduct(_ product: Product) {
        if let index = selectedItems.firstIndex(where: { $0.description == product.name }) {
            selectedItems.remove(at: index)
        } else {
            let newItem = InvoiceItem(
                description: product.name,
                quantity: 1.0,
                unit: product.unit,
                unitPrice: product.price,
                vatRate: product.vatRate
            )
            selectedItems.append(newItem)
            
            // Mark product as used
            Task {
                try? await productViewModel.markProductAsUsed(product)
            }
        }
    }
}

// MARK: - Category Filter Pill
struct CategoryFilterPill: View {
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
                        .fill(isSelected ? AnyShapeStyle(Color.green.opacity(0.2)) : AnyShapeStyle(.ultraThinMaterial))
                        .stroke(isSelected ? .green.opacity(0.3) : .clear, lineWidth: 1)
                )
                .foregroundStyle(isSelected ? .green : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Product Picker Row
struct ProductPickerRow: View {
    let product: Product
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .green : .secondary)
                
                // Product icon
                Circle()
                    .fill(Color.categoryColor(for: product.category).opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: product.category.icon)
                            .font(.title3)
                            .foregroundStyle(Color.categoryColor(for: product.category))
                    )
                
                // Product info
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    if !product.description.isEmpty {
                        Text(product.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 8) {
                        Text(product.category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.categoryColor(for: product.category).opacity(0.1))
                            .foregroundStyle(Color.categoryColor(for: product.category))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        Text(product.unit)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f kr", product.price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("per \(product.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? AnyShapeStyle(Color.green.opacity(0.05)) : AnyShapeStyle(.ultraThinMaterial))
                .stroke(isSelected ? .green.opacity(0.2) : .clear, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - Quick Add Product Button
struct QuickAddProductButton: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var showingAddProduct = false
    
    var body: some View {
        Button {
            showingAddProduct = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                
                Text("Skapa ny produkt")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .stroke(.green.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .sheet(isPresented: $showingAddProduct) {
            AddProductView()
        }
    }
}

#Preview {
    ProductPickerView(selectedItems: .constant([]))
        .environmentObject(ProductViewModel())
}
