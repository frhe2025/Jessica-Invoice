//
//  Color+Extensions.swift
//  Jessica Invoice
//  🔧 FIXED - Removed unnecessary nil coalescing warnings
//

import SwiftUI

extension Color {
    // MARK: - App Brand Colors (FIXED - Removed unnecessary nil coalescing)
    static let jessicaBlue = Color("JessicaBlue")
    static let jessicaGreen = Color("JessicaGreen")
    static let jessicaOrange = Color("JessicaOrange")
    static let jessicaPurple = Color("JessicaPurple")
    
    // MARK: - System Color Variations
    static var adaptiveBackground: Color {
        Color(.systemBackground)
    }
    
    static var adaptiveSecondaryBackground: Color {
        Color(.secondarySystemBackground)
    }
    
    static var adaptiveText: Color {
        Color(.label)
    }
    
    static var adaptiveSecondaryText: Color {
        Color(.secondaryLabel)
    }
    
    // MARK: - Gradient Colors
    static let gradientStart = Color(red: 0.2, green: 0.5, blue: 1.0)
    static let gradientEnd = Color(red: 0.8, green: 0.3, blue: 1.0)
    
    // MARK: - Status Colors
    static let successGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warningOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let errorRed = Color(red: 1.0, green: 0.3, blue: 0.3)
    static let infoBlue = Color(red: 0.3, green: 0.7, blue: 1.0)
    
    // MARK: - Invoice Status Colors
    static func invoiceStatusColor(for status: InvoiceStatus) -> Color {
        switch status {
        case .draft:
            return .gray
        case .sent:
            return .blue
        case .paid:
            return .green
        case .overdue:
            return .red
        case .cancelled:
            return .gray
        }
    }
    
    // MARK: - Category Colors
    static func categoryColor(for category: ProductCategory) -> Color {
        switch category {
        case .service:
            return .blue
        case .product:
            return .green
        case .digital:
            return .purple
        case .consultation:
            return .orange
        case .subscription:
            return .indigo
        case .other:
            return .gray
        }
    }
    
    // MARK: - Priority Colors
    static func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .urgent:
            return .red
        }
    }
    
    // MARK: - Glassmorphism Colors
    static var glassTint: Color {
        Color.white.opacity(0.1)
    }
    
    static var glassBorder: Color {
        Color.white.opacity(0.2)
    }
    
    static var glassShadow: Color {
        Color.black.opacity(0.1)
    }
    
    // MARK: - Color Manipulation (FIXED - Single implementation)
    func lighter(by percentage: Double = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
    
    func darker(by percentage: Double = 0.2) -> Color {
        return self.opacity(1.0 + percentage)
    }
    
    func withAlpha(_ alpha: Double) -> Color {
        return self.opacity(alpha)
    }
    
    // MARK: - Hex Color Support
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    var hexString: String {
        guard let components = cgColor?.components, components.count >= 3 else {
            return "#000000"
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}

// MARK: - Supporting Enums
enum InvoiceStatus: String, CaseIterable, Codable {
    case draft = "draft"
    case sent = "sent"
    case paid = "paid"
    case overdue = "overdue"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .draft: return "Utkast"
        case .sent: return "Skickad"
        case .paid: return "Betald"
        case .overdue: return "Försenad"
        case .cancelled: return "Annullerad"
        }
    }
}

enum ProductCategory: String, CaseIterable, Codable {
    case service = "service"
    case product = "product"
    case digital = "digital"
    case consultation = "consultation"
    case subscription = "subscription"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .service: return "Tjänst"
        case .product: return "Produkt"
        case .digital: return "Digital"
        case .consultation: return "Konsultation"
        case .subscription: return "Prenumeration"
        case .other: return "Övrigt"
        }
    }
    
    var icon: String {
        switch self {
        case .service: return "wrench.and.screwdriver"
        case .product: return "cube.box"
        case .digital: return "laptopcomputer"
        case .consultation: return "person.crop.circle.badge.questionmark"
        case .subscription: return "arrow.clockwise.circle"
        case .other: return "ellipsis.circle"
        }
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Låg"
        case .medium: return "Medium"
        case .high: return "Hög"
        case .urgent: return "Brådskande"
        }
    }
}
