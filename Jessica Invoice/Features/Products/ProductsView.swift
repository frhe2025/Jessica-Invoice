//
//  ProductsView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

struct ProductsView: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var showingAddProduct = false
    @State private var selectedCategory: ProductCategory?
    @State private var showingFilterOptions = false
    @State private var showingBulkActions = false
    @State private var selectedProducts: Set<Product.ID> = []
    
    var filteredProducts: [Product] {
        productViewModel.filteredProducts
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.green.gradient)
                        
                        Text("Produkter & Tjänster")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        
                        Text("Hantera dina produkter och priser")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 32)
                    
                    // Statistics Cards
                    if !productViewModel.products.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: geometry.size.width > 700 ? 4 : 2), spacing: 16) {
                            ProductStatCard(
                                title: "Totala produkter",
                                value: "\(productViewModel.totalProducts)",
                                icon: "cart.fill",
                                color: .blue
                            )
                            
                            ProductStatCard(
                                title: "Genomsnittspris",
                                value: String(format: "%.0f kr", productViewModel.averagePrice),
                                icon: "chart.line.uptrend.xyaxis",
                                color: .green
                            )
                            
                            ProductStatCard(
                                title: "Kategorier",
                                value: "\(ProductCategory.allCases.count)",
                                icon: "folder.fill",
                                color: .purple
                            )
                            
                            ProductStatCard(
                                title: "Senast använda",
                                value: "\(productViewModel.mostUsedProducts.count)",
                                icon: "clock.arrow.circlepath",
                                color: .orange
                            )
                        }
                    }
                    
                    // Search and Filter
                    GlassCard {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                
                                TextField("Sök produkter...", text: $productViewModel.searchText)
                                    .textFieldStyle(.plain)
                                
                                if !productViewModel.searchText.isEmpty {
                                    Button {
                                        productViewModel.searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Button {
                                    showingFilterOptions.toggle()
                                } label: {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.ultraThinMaterial)
                            )
                            
                            if showingFilterOptions {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        CategoryPill(
                                            title: "Alla",
                                            isSelected: selectedCategory == nil
                                        ) {
                                            selectedCategory = nil
                                            productViewModel.selectedCategory = nil
                                        }
                                        
                                        ForEach(ProductCategory.allCases, id: \.self) { category in
                                            CategoryPill(
                                                title: category.displayName,
                                                isSelected: selectedCategory == category
                                            ) {
                                                selectedCategory = selectedCategory == category ? nil : category
                                                productViewModel.selectedCategory = selectedCategory
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                        .padding(16)
                    }
                    
                    // Add Product Button
                    Button {
                        productViewModel.createNewProduct()
                    } label: {
                        GlassCard {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                                
                                Text("Lägg till ny produkt")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(20)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Products Grid or Empty State
                    if filteredProducts.isEmpty {
                        ProductsEmptyState(
                            hasProducts: !productViewModel.products.isEmpty,
                            searchText: productViewModel.searchText,
                            onAddProduct: {
                                productViewModel.createNewProduct()
                            },
                            onClearSearch: {
                                productViewModel.clearFilters()
                            }
                        )
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: geometry.size.width > 700 ? 2 : 1), spacing: 16) {
                            ForEach(filteredProducts) { product in
                                ProductCard(product: product) {
                                    productViewModel.editProduct(product)
                                } onDelete: {
                                    Task {
                                        try? await productViewModel.deleteProduct(product)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .background(GradientBackground.products)
        .navigationBarHidden(true)
        .refreshable {
            productViewModel.loadProducts()
        }
        .searchable(text: $productViewModel.searchText, prompt: "Sök produkter...")
        .sheet(isPresented: $productViewModel.isEditingProduct) {
            if let product = productViewModel.currentProduct {
                AddProductView(product: product)
            }
        }
        .onAppear {
            if productViewModel.products.isEmpty {
                productViewModel.loadProducts()
            }
        }
    }
}

// MARK: - Product Stat Card
struct ProductStatCard: View {
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
                    .font(.title2)
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

// MARK: - Category Pill
struct CategoryPill: View {
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

// MARK: - Product Card
struct ProductCard: View {
    let product: Product
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button(action: onEdit) {
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Circle()
                            .fill(Color.categoryColor(for: product.category).opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: product.category.icon)
                                    .font(.title3)
                                    .foregroundStyle(Color.categoryColor(for: product.category))
                            )
                        
                        Spacer()
                        
                        Menu {
                            Button("Redigera") {
                                onEdit()
                            }
                            
                            Button("Duplicera") {
                                // Duplicate action
                            }
                            
                            Divider()
                            
                            Button("Ta bort", role: .destructive) {
                                showingDeleteAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        if !product.description.isEmpty {
                            Text(product.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        
                        HStack {
                            Text(String(format: "%.0f kr", product.price))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Text("/ \(product.unit)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text(product.category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.categoryColor(for: product.category).opacity(0.1))
                                .foregroundStyle(Color.categoryColor(for: product.category))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            if let lastUsed = product.lastUsed {
                                Text("Använd \(lastUsed.invoiceTimeString)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(20)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .alert("Ta bort produkt", isPresented: $showingDeleteAlert) {
            Button("Ta bort", role: .destructive) {
                onDelete()
            }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Är du säker på att du vill ta bort \(product.name)? Produkten kommer att inaktiveras om den används i befintliga fakturor.")
        }
    }
}

// MARK: - Products Empty State
struct ProductsEmptyState: View {
    let hasProducts: Bool
    let searchText: String
    let onAddProduct: () -> Void
    let onClearSearch: () -> Void
    
    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                if hasProducts && !searchText.isEmpty {
                    // No search results
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("Inga produkter hittades")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Försök med ett annat sökord eller lägg till en ny produkt")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Button("Rensa sökning") {
                            onClearSearch()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Lägg till produkt") {
                            onAddProduct()
                        }
                        .buttonStyle(PrimaryButtonStyle(color: .green))
                    }
                } else {
                    // No products at all
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 64))
                        .foregroundStyle(.green.opacity(0.6))
                    
                    Text("Inga produkter ännu")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Skapa din första produkt för att komma igång med fakturering")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Skapa första produkten") {
                        onAddProduct()
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .green))
                }
            }
            .padding(40)
        }
    }
}

#Preview {
    ProductsView()
        .environmentObject(ProductViewModel())
}
