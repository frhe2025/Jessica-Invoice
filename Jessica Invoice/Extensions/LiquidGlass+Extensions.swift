//
//  LiquidEntranceAnimationModifier.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-16.
//


//
//  LiquidGlass+Extensions.swift
//  📁 PLACERA I: Extensions/
//  iOS 26 Liquid Glass Extensions och Utilities
//

import SwiftUI
import UIKit

// MARK: - View Extensions for Liquid Glass

extension View {
    
    // MARK: - Liquid Glass Styling
    
    /// Applies liquid glass card styling to any view
    func liquidGlassCard(
        style: LiquidGlassStyle = .adaptive,
        depth: LiquidDepth = .medium,
        adaptiveColor: Bool = true
    ) -> some View {
        LiquidGlassCard(style: style, depth: depth, adaptiveColor: adaptiveColor) {
            self
        }
    }
    
    /// Applies minimal liquid glass styling
    func liquidGlassMinimal() -> some View {
        LiquidGlassCard(style: .minimal) { self }
    }
    
    /// Applies prominent liquid glass styling
    func liquidGlassProminent() -> some View {
        LiquidGlassCard(style: .prominent) { self }
    }
    
    /// Applies floating liquid glass styling
    func liquidGlassFloating() -> some View {
        LiquidGlassCard(style: .floating) { self }
    }
    
    /// Applies interactive liquid glass styling
    func liquidGlassInteractive() -> some View {
        LiquidGlassCard(style: .interactive) { self }
    }
    
    // MARK: - Liquid Background Extensions
    
    /// Applies contextual liquid background
    func liquidBackground(_ context: ContextualLiquidBackground.BackgroundContext) -> some View {
        self.background(ContextualLiquidBackground(context: context))
    }
    
    /// Applies invoice-themed liquid background
    func invoiceLiquidBackground() -> some View {
        liquidBackground(.invoice)
    }
    
    /// Applies products-themed liquid background
    func productsLiquidBackground() -> some View {
        liquidBackground(.products)
    }
    
    /// Applies history-themed liquid background
    func historyLiquidBackground() -> some View {
        liquidBackground(.history)
    }
    
    /// Applies settings-themed liquid background
    func settingsLiquidBackground() -> some View {
        liquidBackground(.settings)
    }
    
    /// Applies dashboard-themed liquid background
    func dashboardLiquidBackground() -> some View {
        liquidBackground(.dashboard)
    }
    
    // MARK: - Liquid Animation Extensions
    
    /// Adds liquid entrance animation
    func liquidEntranceAnimation(delay: Double = 0.0) -> some View {
        self.modifier(LiquidEntranceAnimationModifier(delay: delay))
    }
    
    /// Adds liquid hover effect
    func liquidHoverEffect(intensity: CGFloat = 0.03) -> some View {
        self.modifier(LiquidHoverEffectModifier(intensity: intensity))
    }
    
    /// Adds liquid press animation
    func liquidPressAnimation(scale: CGFloat = 0.96, duration: Double = 0.1) -> some View {
        self.modifier(LiquidPressAnimationModifier(scale: scale, duration: duration))
    }
    
    /// Adds liquid shimmer effect
    func liquidShimmer(isActive: Bool = true, duration: Double = 2.0) -> some View {
        self.modifier(LiquidShimmerModifier(isActive: isActive, duration: duration))
    }
    
    // MARK: - Liquid Layout Extensions
    
    /// Creates a liquid glass section with header
    func liquidSection<Header: View>(
        @ViewBuilder header: () -> Header
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            header()
            LiquidGlassCard(style: .adaptive) {
                self
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            }
        }
    }
    
    /// Creates a liquid glass list item
    func liquidListItem(
        isFirst: Bool = false,
        isLast: Bool = false
    ) -> some View {
        self
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .modifier(
                        _ConditionalCornerRadiusModifier(
                            radius: 12,
                            isTop: isFirst,
                            isBottom: isLast
                        )
                    )
            )
    }
    
    // MARK: - Responsive Design Extensions
    
    /// Applies responsive padding based on device size
    func liquidResponsivePadding() -> some View {
        self.modifier(ResponsivePaddingModifier())
    }
    
    /// Applies responsive font scaling
    func liquidResponsiveFont() -> some View {
        self.modifier(ResponsiveFontModifier())
    }
    
    // MARK: - Accessibility Extensions
    
    /// Enhances accessibility for liquid glass components
    func liquidAccessibility(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self.modifier(LiquidAccessibilityModifier(label: label, hint: hint, value: value))
    }
    
    // MARK: - Device-Specific Extensions
    
    /// Applies iPad-specific liquid styling
    func liquidiPadOptimized() -> some View {
        self.modifier(iPadOptimizationModifier())
    }
    
    /// Applies iPhone-specific liquid styling
    func liquidiPhoneOptimized() -> some View {
        self.modifier(iPhoneOptimizationModifier())
    }
}

// Internal modifier to support conditional corner radius on list items
private struct _ConditionalCornerRadiusModifier: ViewModifier {
    let radius: CGFloat
    let isTop: Bool
    let isBottom: Bool
    
    func body(content: Content) -> some View {
        var corners: UIRectCorner = []
        if isTop { corners.formUnion([.topLeft, .topRight]) }
        if isBottom { corners.formUnion([.bottomLeft, .bottomRight]) }
        if corners.isEmpty { return AnyView(content) }
        return AnyView(content.cornerRadius(radius, corners: corners))
    }
}

// MARK: - Liquid Animation Modifiers

struct LiquidEntranceAnimationModifier: ViewModifier {
    let delay: Double
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

struct LiquidHoverEffectModifier: ViewModifier {
    let intensity: CGFloat
    
    @State private var isHovering = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? 1.0 + intensity : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

struct LiquidPressAnimationModifier: ViewModifier {
    let scale: CGFloat
    let duration: Double
    
    @GestureState private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.easeInOut(duration: duration), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

struct LiquidShimmerModifier: ViewModifier {
    let isActive: Bool
    let duration: Double
    
    @State private var animationPhase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .init(x: -0.3 + animationPhase, y: -0.3 + animationPhase),
                    endPoint: .init(x: 0.7 + animationPhase, y: 0.7 + animationPhase)
                )
                .mask(content)
                .opacity(isActive ? 1 : 0)
            )
            .onAppear {
                if isActive {
                    withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                        animationPhase = 1.0
                    }
                }
            }
    }
}

// MARK: - Corner Radius for Specific Corners

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Responsive Design Modifiers

struct ResponsivePaddingModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func body(content: Content) -> some View {
        let h: CGFloat = horizontalSizeClass == .compact ? 16 : 24
        let v: CGFloat = horizontalSizeClass == .compact ? 12 : 16
        return content
            .padding(EdgeInsets(top: v, leading: h, bottom: v, trailing: h))
    }
}

struct ResponsiveFontModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    func body(content: Content) -> some View {
        content
            .font(SwiftUI.Font.body)
    }
}

// MARK: - Accessibility Modifier

struct LiquidAccessibilityModifier: ViewModifier {
    let label: String?
    let hint: String?
    let value: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Device Optimization Modifiers

struct iPadOptimizationModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .frame(maxWidth: 800) // Limit width on iPad
                .padding(.horizontal, 40)
        } else {
            content
        }
    }
}

struct iPhoneOptimizationModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .compact {
            content
                .padding(.horizontal, 16)
        } else {
            content
        }
    }
}

// MARK: - Color Utilities
extension Color {
    /// Approximate check if the color appears light, used for contrast decisions
    var isLight: Bool {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
            // Perceived luminance formula
            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            return luminance > 0.6
        }
        var white: CGFloat = 0
        if ui.getWhite(&white, alpha: &a) {
            return white > 0.6
        }
        return true
        #else
        return true
        #endif
    }
}

// MARK: - Liquid Glass Utilities

struct LiquidGlassUtilities {
    
    /// Generates adaptive colors based on content
    static func adaptiveColors(for baseColor: Color, scheme: ColorScheme) -> [Color] {
        switch scheme {
        case .light:
            return [
                baseColor.opacity(0.8),
                baseColor.lighter(by: 0.3),
                baseColor.darker(by: 0.1)
            ]
        case .dark:
            return [
                baseColor.opacity(0.6),
                baseColor.lighter(by: 0.2),
                baseColor.darker(by: 0.3)
            ]
        @unknown default:
            return [baseColor]
        }
    }
    
    /// Calculates optimal contrast for text
    static func contrastingTextColor(for backgroundColor: Color) -> Color {
        // Simplified contrast calculation
        return backgroundColor.isLight ? .black : .white
    }
    
    /// Creates a liquid glass material based on intensity
    static func liquidMaterial(intensity: Double) -> Material {
        switch intensity {
        case 0.0..<0.2: return .thin
        case 0.2..<0.5: return .ultraThin
        case 0.5..<0.8: return .regular
        default: return .thick
        }
    }
    
    /// Generates liquid glass shadow parameters
    static func shadowParameters(for depth: LiquidDepth, scheme: ColorScheme) -> (Color, CGFloat, CGFloat, CGFloat) {
        let baseOpacity: Double = scheme == .dark ? 0.4 : 0.1
        
        switch depth {
        case .subtle:
            return (.black.opacity(baseOpacity), 2, 0, 1)
        case .medium:
            return (.black.opacity(baseOpacity * 1.2), 8, 0, 4)
        case .deep:
            return (.black.opacity(baseOpacity * 1.5), 15, 0, 8)
        case .floating:
            return (.black.opacity(baseOpacity * 2), 25, 0, 12)
        }
    }
}

// MARK: - Liquid Glass Environment

struct LiquidGlassEnvironment {
    static let defaultCornerRadius: CGFloat = 16
    static let defaultAnimationDuration: Double = 0.3
    static let defaultSpringResponse: Double = 0.6
    static let defaultSpringDamping: Double = 0.8
    
    /// Environment key for liquid glass intensity
    struct IntensityKey: EnvironmentKey {
        static let defaultValue: Double = 0.1
    }
    
    /// Environment key for liquid glass animation state
    struct AnimationStateKey: EnvironmentKey {
        static let defaultValue: Bool = true
    }
}

extension EnvironmentValues {
    var liquidGlassIntensity: Double {
        get { self[LiquidGlassEnvironment.IntensityKey.self] }
        set { self[LiquidGlassEnvironment.IntensityKey.self] = newValue }
    }
    
    var liquidGlassAnimationEnabled: Bool {
        get { self[LiquidGlassEnvironment.AnimationStateKey.self] }
        set { self[LiquidGlassEnvironment.AnimationStateKey.self] = newValue }
    }
}

// MARK: - Liquid Glass Theme Manager

@MainActor
class LiquidGlassThemeManager: ObservableObject {
    @Published var currentTheme: LiquidGlassTheme = .adaptive
    @Published var globalIntensity: Double = 0.1
    @Published var animationsEnabled: Bool = true
    @Published var accessibilityMode: Bool = false
    
    enum LiquidGlassTheme {
        case minimal
        case adaptive
        case prominent
        case custom(LiquidGlassCustomTheme)
    }
    
    struct LiquidGlassCustomTheme {
        let primaryColor: Color
        let secondaryColor: Color
        let intensity: Double
        let cornerRadius: CGFloat
        let animationDuration: Double
    }
    
    // MARK: - Theme Management
    
    func setTheme(_ theme: LiquidGlassTheme) {
        currentTheme = theme
        
        // Apply theme-specific settings
        switch theme {
        case .minimal:
            globalIntensity = 0.05
            animationsEnabled = false
        case .adaptive:
            globalIntensity = 0.1
            animationsEnabled = true
        case .prominent:
            globalIntensity = 0.15
            animationsEnabled = true
        case .custom(let customTheme):
            globalIntensity = customTheme.intensity
            animationsEnabled = true
        }
        
        // Save theme preference
        UserDefaults.standard.set(theme.identifier, forKey: "liquid_glass_theme")
    }
    
    func enableAccessibilityMode(_ enabled: Bool) {
        accessibilityMode = enabled
        
        if enabled {
            // Reduce animations and effects for better accessibility
            animationsEnabled = false
            globalIntensity = max(0.03, globalIntensity * 0.5)
        }
        
        UserDefaults.standard.set(enabled, forKey: "liquid_glass_accessibility")
    }
    
    // MARK: - Theme Application
    
    func liquidGlassStyle(for context: String) -> LiquidGlassStyle {
        switch currentTheme {
        case .minimal:
            return .minimal
        case .adaptive:
            return .adaptive
        case .prominent:
            return .prominent
        case .custom:
            return .interactive
        }
    }
    
    func liquidDepth(for context: String) -> LiquidDepth {
        switch currentTheme {
        case .minimal:
            return .subtle
        case .adaptive:
            return .medium
        case .prominent:
            return .deep
        case .custom:
            return .medium
        }
    }
}

extension LiquidGlassThemeManager.LiquidGlassTheme {
    var identifier: String {
        switch self {
        case .minimal: return "minimal"
        case .adaptive: return "adaptive"
        case .prominent: return "prominent"
        case .custom: return "custom"
        }
    }
}

// MARK: - Performance Optimization Extensions

extension View {
    
    /// Applies performance-optimized liquid effects
    func liquidPerformanceOptimized() -> some View {
        self.modifier(PerformanceOptimizedLiquidModifier())
    }
    
    /// Conditionally applies liquid effects based on performance
    func liquidConditional(enabled: Bool = true) -> some View {
        Group {
            if enabled {
                self.liquidGlassCard()
            } else {
                self
            }
        }
    }
}

struct PerformanceOptimizedLiquidModifier: ViewModifier {
    @State private var isVisible = false
    @Environment(\.scenePhase) var scenePhase
    
    func body(content: Content) -> some View {
        content
            .liquidGlassCard(adaptiveColor: isVisible)
            .onAppear { isVisible = true }
            .onDisappear { isVisible = false }
            .onChange(of: scenePhase) { newPhase in
                // Reduce effects when app is in background
                isVisible = newPhase == .active
            }
    }
}

extension Color {
    func lighter(by amount: CGFloat) -> Color {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return Color(red: min(r + amount, 1.0), green: min(g + amount, 1.0), blue: min(b + amount, 1.0))
        }
        var white: CGFloat = 0
        if ui.getWhite(&white, alpha: &a) {
            return Color(white: min(white + amount, 1.0))
        }
        return self
        #else
        return self
        #endif
    }
    
    func darker(by amount: CGFloat) -> Color {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return Color(red: max(r - amount, 0.0), green: max(g - amount, 0.0), blue: max(b - amount, 0.0))
        }
        var white: CGFloat = 0
        if ui.getWhite(&white, alpha: &a) {
            return Color(white: max(white - amount, 0.0))
        }
        return self
        #else
        return self
        #endif
    }
}

#Preview("Liquid Extensions Demo") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Liquid Glass Extensions Demo")
                .font(SwiftUI.Font.largeTitle)
                .fontWeight(.bold)
                .liquidGlassProminent()
                .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            
            VStack(spacing: 16) {
                Text("Basic Card")
                    .liquidGlassCard()
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                
                Text("Minimal Style")
                    .liquidGlassMinimal()
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                
                Text("Interactive Style")
                    .liquidGlassInteractive()
                    .liquidHoverEffect()
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                
                Text("With Shimmer")
                    .liquidGlassCard()
                    .liquidShimmer()
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                
                Text("Entrance Animation")
                    .liquidGlassCard()
                    .liquidEntranceAnimation(delay: 0.5)
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            }
        }
        .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
    }
    .invoiceLiquidBackground()
}

