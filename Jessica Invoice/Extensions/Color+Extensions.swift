//
//  Color+Extensions.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

// MARK: - Custom Colors
extension Color {
    
    // MARK: - Brand Colors
    static let jessicaBlue = Color("JessicaBlue") ?? .blue
    static let jessicaGreen = Color("JessicaGreen") ?? .green
    static let jessicaOrange = Color("JessicaOrange") ?? .orange
    static let jessicaPurple = Color("JessicaPurple") ?? .purple
    
    // MARK: - Semantic Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // MARK: - Status Colors
    static let statusDraft = Color.gray
    static let statusSent = Color.blue
    static let statusPaid = Color.green
    static let statusOverdue = Color.red
    static let statusCancelled = Color.orange
    
    // MARK: - Background Colors
    static let cardBackground = Color(.systemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let secondaryGroupedBackground = Color(.secondarySystemGroupedBackground)
    
    // MARK: - Text Colors
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    static let quaternaryText = Color(.quaternaryLabel)
    
    // MARK: - Glass Colors
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
    static let glassShadow = Color.black.opacity(0.1)
    
    // MARK: - Category Colors
    static func categoryColor(for category: ProductCategory) -> Color {
        switch category {
        case .service: return .blue
        case .product: return .orange
        case .design: return .purple
        case .consultation: return .green
        case .development: return .indigo
        case .maintenance: return .brown
        }
    }
    
    static func statusColor(for status: InvoiceStatus) -> Color {
        switch status {
        case .draft: return .statusDraft
        case .sent: return .statusSent
        case .paid: return .statusPaid
        case .overdue: return .statusOverdue
        case .cancelled: return .statusCancelled
        }
    }
}

// MARK: - Color Utilities
extension Color {
    
    /// Create a Color from hex string
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Convert Color to hex string
    var hexString: String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        let a = components.count >= 4 ? components[3] : 1.0
        
        if a < 1.0 {
            return String(format: "#%02X%02X%02X%02X",
                         Int(a * 255), Int(r * 255), Int(g * 255), Int(b * 255))
        } else {
            return String(format: "#%02X%02X%02X",
                         Int(r * 255), Int(g * 255), Int(b * 255))
        }
    }
    
    /// Get a lighter version of the color
    func lighter(by percentage: Double = 0.2) -> Color {
        return self.opacity(1 - percentage)
    }
    
    /// Get a darker version of the color
    func darker(by percentage: Double = 0.2) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        brightness *= CGFloat(1 - percentage)
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha))
    }
    
    /// Get complementary color
    var complementary: Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        hue += 0.5
        if hue > 1.0 { hue -= 1.0 }
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha))
    }
    
    /// Check if color is light or dark
    var isLight: Bool {
        let uiColor = UIColor(self)
        var white: CGFloat = 0
        uiColor.getWhite(&white, alpha: nil)
        return white > 0.5
    }
    
    /// Get contrasting text color (black or white)
    var contrastingTextColor: Color {
        return isLight ? .black : .white
    }
}

// MARK: - Predefined Color Schemes
extension Color {
    
    struct Scheme {
        let primary: Color
        let secondary: Color
        let accent: Color
        let background: Color
        let surface: Color
        let onPrimary: Color
        let onSecondary: Color
        let onBackground: Color
        let onSurface: Color
    }
    
    static let lightScheme = Scheme(
        primary: .blue,
        secondary: .gray,
        accent: .orange,
        background: Color(.systemBackground),
        surface: Color(.secondarySystemBackground),
        onPrimary: .white,
        onSecondary: .black,
        onBackground: Color(.label),
        onSurface: Color(.label)
    )
    
    static let darkScheme = Scheme(
        primary: .blue,
        secondary: .gray,
        accent: .orange,
        background: Color(.systemBackground),
        surface: Color(.secondarySystemBackground),
        onPrimary: .white,
        onSecondary: .white,
        onBackground: Color(.label),
        onSurface: Color(.label)
    )
}

// MARK: - Gradient Extensions
extension Color {
    
    static let invoiceGradient = LinearGradient(
        colors: [.blue, .blue.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let productsGradient = LinearGradient(
        colors: [.green, .green.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let historyGradient = LinearGradient(
        colors: [.orange, .orange.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let settingsGradient = LinearGradient(
        colors: [.purple, .purple.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let sunsetGradient = LinearGradient(
        colors: [.orange, .pink, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let oceanGradient = LinearGradient(
        colors: [.blue, .cyan, .teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let forestGradient = LinearGradient(
        colors: [.green, .mint],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Dynamic Colors
extension Color {
    
    /// Create a dynamic color that changes based on color scheme
    static func dynamic(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            case .light, .unspecified:
                return UIColor(light)
            @unknown default:
                return UIColor(light)
            }
        })
    }
    
    /// Adaptive colors for glass effects
    static let adaptiveGlass = Color.dynamic(
        light: .white.opacity(0.1),
        dark: .white.opacity(0.05)
    )
    
    static let adaptiveGlassBorder = Color.dynamic(
        light: .white.opacity(0.2),
        dark: .white.opacity(0.1)
    )
    
    static let adaptiveCardBackground = Color.dynamic(
        light: .white.opacity(0.8),
        dark: .black.opacity(0.8)
    )
}

// MARK: - Accessibility Colors
extension Color {
    
    /// High contrast version of the color for accessibility
    var highContrast: Color {
        return isLight ? .black : .white
    }
    
    /// Check if color meets WCAG AA contrast requirements against background
    func meetsContrastRequirements(against background: Color, level: ContrastLevel = .aa) -> Bool {
        let ratio = contrastRatio(with: background)
        switch level {
        case .aa:
            return ratio >= 4.5
        case .aaa:
            return ratio >= 7.0
        }
    }
    
    /// Calculate contrast ratio between two colors
    func contrastRatio(with other: Color) -> Double {
        let luminance1 = relativeLuminance
        let luminance2 = other.relativeLuminance
        
        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Calculate relative luminance of the color
    private var relativeLuminance: Double {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        func adjustComponent(_ component: CGFloat) -> Double {
            let c = Double(component)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        
        let r = adjustComponent(red)
        let g = adjustComponent(green)
        let b = adjustComponent(blue)
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
}

enum ContrastLevel {
    case aa
    case aaa
}

// MARK: - Color Preview Helpers
extension Color {
    
    /// Create a preview color for Xcode canvas
    static func preview(_ color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: 50, height: 50)
            .cornerRadius(8)
    }
    
    /// Create a color palette preview
    static func palettePreview(_ colors: [Color], title: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                ForEach(0..<colors.count, id: \.self) { index in
                    preview(colors[index])
                }
            }
        }
        .padding()
    }
}
