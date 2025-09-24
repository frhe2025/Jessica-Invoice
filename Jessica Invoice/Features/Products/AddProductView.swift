//
//  AddProductView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//


import SwiftUI

struct AddProductView: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var product: Product
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingTemplates = false
    
    private let isEditMode: Bool
    
    init(product: Product? = nil) {
        if let existingProduct = product {
            self._product = State(initialValue: existingProduct)
            self.isEditMode = true
        } else {
            self._product = State(initialValue: Product())
            self.isEditMode = false
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Product Templates (only for new products)
                if !isEditMode {
                    ProductTemplateSection(
                        selectedProduct: $product,
                        showingTemplates: $showingTemplates
                    )
                }
                
                // Basic Information
                ProductBasicInfoSection(product: $product)
                
                // Pricing Information
                ProductPricingSection(product: $product)
                
                // Category and Settings
                ProductCategorySection(product: $product)
                
                // Advanced Settings
                ProductAdvancedSection(product: $product)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .background(GradientBackground.products)
        .navigationTitle(isEditMode ? "Redigera Produkt" : "Ny Produkt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Avbryt") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditMode ? "Uppdatera" : "Spara") {
                    saveProduct()
                }
                .fontWeight(.semibold)
                .disabled(product.name.isEmpty || product.price <= 0)
                .loadingButton(isLoading: isLoading)
            }
        }
        .sheet(isPresented: $showingTemplates) {
            ProductTemplatesView(selectedProduct: $product)
        }
        .errorAlert(isPresented: $showingError, error: ProductFormError(message: errorMessage ?? ""))
    }
    
    private func saveProduct() {
        let validationErrors = productViewModel.validateProduct(product)
        if !validationErrors.isEmpty {
            errorMessage = validationErrors.joined(separator: "\n")
            showingError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await productViewModel.saveProduct(product)
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

// MARK: - Product Template Section
struct ProductTemplateSection: View {
    @Binding var selectedProduct: Product
    @Binding var showingTemplates: Bool
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Kom igång snabbt")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Använd en mall eller skapa från början")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(ProductTemplate.quickTemplates, id: \.name) { template in
                        Button {
                            selectedProduct = template.product
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: template.product.category.icon)
                                    .font(.title2)
                                    .foregroundStyle(Color.categoryColor(for: template.product.category))
                                
                                Text(template.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                
                Button("Visa alla mallar") {
                    showingTemplates = true
                }
                .font(.subheadline)
                .foregroundStyle(.green)
            }
            .padding(20)
        }
    }
}

// MARK: - Product Basic Info Section
struct ProductBasicInfoSection: View {
    @Binding var product: Product
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Grunduppgifter")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    FormField(
                        title: "Produktnamn *",
                        text: $product.name,
                        placeholder: "Ange produktnamn"
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Beskrivning")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        TextField(
                            "Beskriv produkten eller tjänsten...",
                            text: $product.description,
                            axis: .vertical
                        )
                        .lineLimit(2...4)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Product Pricing Section
struct ProductPricingSection: View {
    @Binding var product: Product
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Prissättning")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pris *")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        TextField("0", value: $product.price, format: .currency(code: "SEK"))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enhet")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Menu {
                            ForEach(ProductUnit.allCases, id: \.self) { unit in
                                Button(unit.displayName) {
                                    product.unit = unit.rawValue
                                }
                            }
                        } label: {
                            HStack {
                                Text(product.unit.isEmpty ? "st" : product.unit)
                                    .foregroundStyle(product.unit.isEmpty ? .secondary : .primary)
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
                    HStack {
                        Text("Moms")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.0f", product.vatRate))%")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    
                    Slider(value: $product.vatRate, in: 0...25, step: 5)
                        .tint(.green)
                    
                    HStack {
                        Text("0%")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text("25%")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // Price Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prisöversikt")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text("Exkl. moms:")
                        Spacer()
                        Text(String(format: "%.0f kr", product.price))
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Moms (\(String(format: "%.0f", product.vatRate))%):")
                        Spacer()
                        Text(String(format: "%.0f kr", product.price * (product.vatRate / 100)))
                    }
                    .font(.caption)
                    
                    Divider()
                    
                    HStack {
                        Text("Inkl. moms:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(String(format: "%.0f kr", product.price * (1 + product.vatRate / 100)))
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    .font(.subheadline)
                }
                .padding(12)
                .background(.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)
        }
    }
}

// MARK: - Product Category Section
struct ProductCategorySection: View {
    @Binding var product: Product
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Kategori")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(ProductCategory.allCases, id: \.self) { category in
                        CategorySelectionCard(
                            category: category,
                            isSelected: product.category == category
                        ) {
                            product.category = category
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

struct CategorySelectionCard: View {
    let category: ProductCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.categoryColor(for: category))
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AnyShapeStyle(Color.categoryColor(for: category)) : AnyShapeStyle(.ultraThinMaterial))
                    .stroke(isSelected ? .clear : Color.categoryColor(for: category).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Product Advanced Section
struct ProductAdvancedSection: View {
    @Binding var product: Product
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Avancerat")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Toggle(isOn: $product.isActive) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aktiv produkt")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Visa produkten i produktlistan")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.green)
                
                if !product.isActive {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.orange)
                        
                        Text("Inaktiva produkter visas inte i produktväljarens")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.05))
                    )
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Product Templates
struct ProductTemplate {
    let name: String
    let product: Product
    
    static let quickTemplates: [ProductTemplate] = [
        ProductTemplate(
            name: "Konsultation",
            product: Product(
                name: "Konsultation",
                description: "Rådgivning och konsultation",
                price: 1500,
                unit: "timme",
                category: .consultation
            )
        ),
        ProductTemplate(
            name: "Webbutveckling",
            product: Product(
                name: "Webbutveckling",
                description: "Frontend och backend utveckling",
                price: 1200,
                unit: "timme",
                category: .development
            )
        ),
        ProductTemplate(
            name: "Design",
            product: Product(
                name: "Grafisk design",
                description: "Logo, broschyrer och grafisk design",
                price: 1000,
                unit: "timme",
                category: .design
            )
        ),
        ProductTemplate(
            name: "Support",
            product: Product(
                name: "Teknisk support",
                description: "Support och underhåll av system",
                price: 800,
                unit: "timme",
                category: .maintenance
            )
        )
    ]
    
    static let allTemplates: [ProductTemplate] = quickTemplates + [
        ProductTemplate(
            name: "Projektledning",
            product: Product(
                name: "Projektledning",
                description: "Ledning och koordinering av projekt",
                price: 1400,
                unit: "timme",
                category: .consultation
            )
        ),
        ProductTemplate(
            name: "Hosting",
            product: Product(
                name: "Webbhotell",
                description: "Hosting och domänhantering",
                price: 299,
                unit: "månad",
                category: .service
            )
        ),
        ProductTemplate(
            name: "Licens",
            product: Product(
                name: "Programlicens",
                description: "Licens för programvara",
                price: 500,
                unit: "månad",
                category: .product
            )
        )
    ]
}

// MARK: - Product Templates View
struct ProductTemplatesView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedProduct: Product
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(ProductTemplate.allTemplates, id: \.name) { template in
                        ProductTemplateCard(template: template) {
                            selectedProduct = template.product
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(GradientBackground.products)
            .navigationTitle("Produktmallar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Stäng") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProductTemplateCard: View {
    let template: ProductTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            GlassCard {
                VStack(spacing: 12) {
                    Image(systemName: template.product.category.icon)
                        .font(.title)
                        .foregroundStyle(Color.categoryColor(for: template.product.category))
                    
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(template.product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("\(String(format: "%.0f", template.product.price)) kr/\(template.product.unit)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .padding(16)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Product Form Error
struct ProductFormError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

#Preview {
    AddProductView()
        .environmentObject(ProductViewModel())
}
