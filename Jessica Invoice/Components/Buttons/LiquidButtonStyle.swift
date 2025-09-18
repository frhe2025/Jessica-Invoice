//
//  LiquidButtonStyle.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-16.
//


//
//  LiquidButtonStyle.swift
//  Jessica Invoice
//
//  📁 PLACERA I: Components/Buttons/
//  iOS 26 Liquid Button System with Haptic Feedback
//

import SwiftUI

// MARK: - Liquid Button Style
struct LiquidButtonStyle: ButtonStyle {
    let variant: LiquidButtonVariant
    let size: LiquidButtonSize
    let isLoading: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled
    @State private var animationPhase: CGFloat = 0
    @State private var pressAnimationPhase: CGFloat = 0
    
    init(
        variant: LiquidButtonVariant = .primary,
        size: LiquidButtonSize = .medium,
        isLoading: Bool = false
    ) {
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: size.iconSpacing) {
            if isLoading {
                LoadingIndicator(size: size)
            }
            
            configuration.label
        }
        .foregroundStyle(variant.foregroundColor(for: colorScheme))
        .font(size.font)
        .fontWeight(size.fontWeight)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(buttonBackground(isPressed: configuration.isPressed))
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        .overlay(liquidOverlay(isPressed: configuration.isPressed))
        .scaleEffect(pressAnimationPhase)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: pressAnimationPhase)
        .disabled(isLoading)
        .onChange(of: configuration.isPressed) { _, isPressed in
            handlePressStateChange(isPressed: isPressed)
        }
        .onAppear {
            startShimmerAnimation()
        }
    }
    
    // MARK: - Button Background
    @ViewBuilder
    private func buttonBackground(isPressed: Bool) -> some View {
        ZStack {
            // Base background
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(variant.backgroundColor(for: colorScheme, isPressed: isPressed))
            
            // Liquid shimmer effect
            if variant.hasShimmer {
                liquidShimmerBackground
            }
            
            // Gradient overlay
            if variant.hasGradient {
                gradientOverlay(isPressed: isPressed)
            }
        }
    }
    
    // MARK: - Liquid Shimmer Background
    private var liquidShimmerBackground: some View {
        LinearGradient(
            colors: [
                .clear,
                Color.white.opacity(0.3),
                .clear,
                Color.white.opacity(0.2),
                .clear
            ],
            startPoint: .init(x: -0.3 + animationPhase, y: -0.3 + animationPhase),
            endPoint: .init(x: 0.7 + animationPhase, y: 0.7 + animationPhase)
        )
        .mask(
            RoundedRectangle(cornerRadius: size.cornerRadius)
        )
    }
    
    // MARK: - Gradient Overlay
    private func gradientOverlay(isPressed: Bool) -> some View {
        LinearGradient(
            colors: variant.gradientColors(for: colorScheme, isPressed: isPressed),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .mask(
            RoundedRectangle(cornerRadius: size.cornerRadius)
        )
    }
    
    // MARK: - Liquid Overlay
    private func liquidOverlay(isPressed: Bool) -> some View {
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .stroke(
                LinearGradient(
                    colors: variant.strokeColors(for: colorScheme, isPressed: isPressed),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: variant.strokeWidth
            )
    }
    
    // MARK: - Animation Functions
    private func startShimmerAnimation() {
        guard variant.hasShimmer else { return }
        
        withAnimation(
            .linear(duration: 2.5)
            .repeatForever(autoreverses: false)
        ) {
            animationPhase = 1.0
        }
    }
    
    private func handlePressStateChange(isPressed: Bool) {
        // Haptic feedback
        if isPressed {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                pressAnimationPhase = 0.96
            }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                pressAnimationPhase = 1.0
            }
        }
    }
}

// MARK: - Liquid Button Variants
enum LiquidButtonVariant {
    case primary
    case secondary
    case tertiary
    case destructive
    case ghost
    case adaptive
    
    var hasShimmer: Bool {
        switch self {
        case .primary, .adaptive: return true
        case .secondary, .tertiary, .destructive, .ghost: return false
        }
    }
    
    var hasGradient: Bool {
        switch self {
        case .primary, .destructive, .adaptive: return true
        case .secondary, .tertiary, .ghost: return false
        }
    }
    
    var strokeWidth: CGFloat {
        switch self {
        case .primary, .destructive: return 0
        case .secondary, .tertiary: return 1.0
        case .ghost: return 0.5
        case .adaptive: return 1.0
        }
    }
    
    func backgroundColor(for colorScheme: ColorScheme, isPressed: Bool) -> Color {
        let pressedOpacity = isPressed ? 0.8 : 1.0
        
        switch self {
        case .primary:
            return .accentColor.opacity(pressedOpacity)
        case .secondary:
            return .clear
        case .tertiary:
            return (colorScheme == .dark ? .white : .black).opacity(0.05 * pressedOpacity)
        case .destructive:
            return .red.opacity(pressedOpacity)
        case .ghost:
            return .clear
        case .adaptive:
            return .accentColor.opacity(0.8 * pressedOpacity)
        }
    }
    
    func foregroundColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .accentColor
        case .tertiary, .adaptive:
            return .primary
        case .ghost:
            return .secondary
        }
    }
    
    func gradientColors(for colorScheme: ColorScheme, isPressed: Bool) -> [Color] {
        let opacity = isPressed ? 0.8 : 1.0
        
        switch self {
        case .primary:
            return [
                .accentColor.opacity(opacity),
                .accentColor.darker(by: 0.2).opacity(opacity)
            ]
        case .destructive:
            return [
                .red.opacity(opacity),
                .red.darker(by: 0.3).opacity(opacity)
            ]
        case .adaptive:
            return [
                .accentColor.lighter(by: 0.1).opacity(opacity),
                .accentColor.darker(by: 0.1).opacity(opacity)
            ]
        default:
            return [.clear]
        }
    }
    
    func strokeColors(for colorScheme: ColorScheme, isPressed: Bool) -> [Color] {
        let opacity = isPressed ? 0.6 : 1.0
        
        switch self {
        case .secondary:
            return [
                .accentColor.opacity(0.6 * opacity),
                .accentColor.opacity(0.3 * opacity)
            ]
        case .tertiary:
            return [
                (colorScheme == .dark ? Color.white : Color.black).opacity(0.2 * opacity),
                (colorScheme == .dark ? Color.white : Color.black).opacity(0.1 * opacity)
            ]
        case .ghost:
            return [
                .secondary.opacity(0.3 * opacity),
                .secondary.opacity(0.1 * opacity)
            ]
        case .adaptive:
            return [
                Color.white.opacity(0.4 * opacity),
                Color.white.opacity(0.2 * opacity)
            ]
        default:
            return [.clear]
        }
    }
}

// MARK: - Liquid Button Sizes
enum LiquidButtonSize {
    case small
    case medium
    case large
    case extraLarge
    
    var font: Font {
        switch self {
        case .small: return .caption
        case .medium: return .subheadline
        case .large: return .body
        case .extraLarge: return .title3
        }
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .small: return .medium
        case .medium: return .medium
        case .large: return .semibold
        case .extraLarge: return .semibold
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        case .extraLarge: return 24
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 10
        case .large: return 14
        case .extraLarge: return 18
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        case .extraLarge: return 20
        }
    }
    
    var iconSpacing: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        case .extraLarge: return 10
        }
    }
}

// MARK: - Loading Indicator
struct LoadingIndicator: View {
    let size: LiquidButtonSize
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "arrow.clockwise")
            .font(size.font)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Adaptive Liquid Button
struct AdaptiveLiquidButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    let variant: LiquidButtonVariant
    let size: LiquidButtonSize
    let isLoading: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @State private var dominantColor: Color = .blue
    
    init(
        variant: LiquidButtonVariant = .adaptive,
        size: LiquidButtonSize = .medium,
        isLoading: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(LiquidButtonStyle(variant: variant, size: size, isLoading: isLoading))
    }
}

// MARK: - Convenience Extensions
extension View {
    func liquidButtonStyle(
        variant: LiquidButtonVariant = .primary,
        size: LiquidButtonSize = .medium,
        isLoading: Bool = false
    ) -> some View {
        self.buttonStyle(LiquidButtonStyle(variant: variant, size: size, isLoading: isLoading))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            Text("iOS 26 Liquid Buttons")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom)
            
            // Primary Buttons
            VStack(spacing: 16) {
                Text("Primary Buttons")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    Button("Small") {}
                        .liquidButtonStyle(variant: .primary, size: .small)
                    
                    Button("Medium") {}
                        .liquidButtonStyle(variant: .primary, size: .medium)
                    
                    Button("Large") {}
                        .liquidButtonStyle(variant: .primary, size: .large)
                }
                
                Button("Loading Button") {}
                    .liquidButtonStyle(variant: .primary, size: .large, isLoading: true)
            }
            
            // Secondary Buttons
            VStack(spacing: 16) {
                Text("Secondary & Variants")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    Button("Secondary Button") {}
                        .liquidButtonStyle(variant: .secondary, size: .medium)
                    
                    Button("Tertiary Button") {}
                        .liquidButtonStyle(variant: .tertiary, size: .medium)
                    
                    Button("Destructive Button") {}
                        .liquidButtonStyle(variant: .destructive, size: .medium)
                    
                    Button("Ghost Button") {}
                        .liquidButtonStyle(variant: .ghost, size: .medium)
                    
                    Button("Adaptive Button") {}
                        .liquidButtonStyle(variant: .adaptive, size: .medium)
                }
            }
        }
        .padding(20)
    }
    .liquidGlassBackground(.dashboard)
}
