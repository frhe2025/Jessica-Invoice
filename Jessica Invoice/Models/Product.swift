//
//  Product.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import Foundation

struct Product: Identifiable, Codable, Hashable, Equatable {
    let id = UUID()
    var name: String
    var description: String
    var price: Double
    var unit: String
    var category: ProductCategory
    var vatRate: Double // percentage
    var isActive: Bool
    var createdDate: Date
    var lastUsed: Date?
    
    var formattedPrice: String {
        String(format: "%.0f kr", price)
    }
    
    init(
        name: String = "",
        description: String = "",
        price: Double = 0.0,
        unit: String = "st",
        category: ProductCategory = .service,
        vatRate: Double = 25.0,
        isActive: Bool = true,
        createdDate: Date = Date(),
        lastUsed: Date? = nil
    ) {
        self.name = name
        self.description = description
        self.price = price
        self.unit = unit
        self.category = category
        self.vatRate = vatRate
        self.isActive = isActive
        self.createdDate = createdDate
        self.lastUsed = lastUsed
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum ProductCategory: String, CaseIterable, Codable {
    case service = "service"
    case product = "product"
    case design = "design"
    case consultation = "consultation"
    case development = "development"
    case maintenance = "maintenance"
    
    var displayName: String {
        switch self {
        case .service: return "Tjänst"
        case .product: return "Produkt"
        case .design: return "Design"
        case .consultation: return "Konsultation"
        case .development: return "Utveckling"
        case .maintenance: return "Underhåll"
        }
    }
    
    var icon: String {
        switch self {
        case .service: return "wrench.and.screwdriver"
        case .product: return "shippingbox"
        case .design: return "paintbrush"
        case .consultation: return "person.2"
        case .development: return "laptopcomputer"
        case .maintenance: return "gear"
        }
    }
    
    var color: String {
        switch self {
        case .service: return "blue"
        case .product: return "orange"
        case .design: return "purple"
        case .consultation: return "green"
        case .development: return "indigo"
        case .maintenance: return "brown"
        }
    }
}

enum ProductUnit: String, CaseIterable, Codable {
    case piece = "st"
    case hour = "timme"
    case day = "dag"
    case week = "vecka"
    case month = "månad"
    case year = "år"
    case project = "projekt"
    case meter = "m"
    case squareMeter = "m²"
    case kilogram = "kg"
    
    var displayName: String {
        return rawValue
    }
    
    var shortName: String {
        switch self {
        case .piece: return "st"
        case .hour: return "h"
        case .day: return "dag"
        case .week: return "v"
        case .month: return "mån"
        case .year: return "år"
        case .project: return "proj"
        case .meter: return "m"
        case .squareMeter: return "m²"
        case .kilogram: return "kg"
        }
    }
}
