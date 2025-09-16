//
//  AdaptiveButton.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//  iOS 26 Adaptive Button with Liquid Glass
//

import SwiftUI

// MARK: - Adaptive Button Types
enum AdaptiveButtonStyle {
    case primary
    case secondary
    case ghost
    case floating
    case pill
    case icon
    case destructive
}

enum AdaptiveButtonSize {
    case small
    case medium
    case large
    case extraLarge
    
    var padding: EdgeInsets {
        switch self {
        case .small:
            return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .medium:
            return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        case .large:
            return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        case .extraLarge:
            return EdgeInsets(top: 20, leading: 32, bottom: 20, trailing: 32)
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
    
    var fontSize: Font {
        switch self {
        case .small: return .caption
        case .medium: return .subheadline
        case .large: return .headline
        case .extraLarge: return .title3
        }
    }
}

// MARK: - Adaptive Button
struct AdaptiveButton: View {
    let title: String?
    let icon: String?
    let style: AdaptiveButtonStyle
    let size: AdaptiveButtonSize
    let color: Color
    let isLoading: Bool
    let isDisabled: Bool
    let hapticFeedback: UIImpactFeedbackGenerator.FeedbackStyle?
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    init(
        _ title: String? = nil,
        icon: String? = nil,
        style: AdaptiveButtonStyle = .primary,
        size: AdaptiveButtonSize = .medium,
        color: Color = .blue,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        hapticFeedback: UIImpactFeedbackGenerator.FeedbackStyle? = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.color = color
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.hapticFeedback = hapticFeedback
        self.action = action
    }
    
    var body: some View {
        Button(action: handleTap) {
            content
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(pressedScale)
        .opacity(isDisabled ? 0.6 : 1.0)
        .disabled(isDisabled || isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel(title ?? "Button")
        .accessibilityHint(isLoading ? "Loading" : nil)
    }
    
    @ViewBuilder
    private var content: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: contentColor))
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(iconFont)
                    .foregroundStyle(contentColor)
            }
            
            if let title = title, style != .icon {
                Text(title)
                    .font(size.fontSize)
                    .fontWeight(fontWeight)
                    .foregroundStyle(contentColor)
            }
        }
        .padding(style == .pill ? pillPadding : size.padding)
        .background(backgroundView)
        .clipShape(shape)
        .liquidRipple(trigger: isPressed, color: rippleColor)
        .liquidShadow(
            radius: shadowRadius,
            intensity: shadowIntensity,
            color: shadowColor
        )
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LiquidGlassBackground(
                intensity: backgroundIntensity,
                tintColor: color,
                isAdaptive: true
            )
            .overlay(
                shape
                    .fill(color.opacity(colorScheme == .dark ? 0.7 : 0.8))
                    .blendMode(.overlay)
            )
            
        case .secondary:
            LiquidGlassBackground(
                intensity: 0.8,
                tintColor: color,
                isAdaptive: true
            )
            .overlay(
                shape
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            
        case .ghost:
            Color.clear
                .overlay(
                    shape
                        .fill(color.opacity(isHovered ? 0.1 : 0.05))
                )
            
        case .floating:
            LiquidGlassBackground(
                intensity: 1.2,
                tintColor: color,
                isAdaptive: true
            )
            .morphingGlass(intensity: 0.5)
            
        case .pill:
            LiquidGlassBackground(
                intensity: 0.9,
                tintColor: color,
                isAdaptive: true
            )
            .overlay(
                Capsule()
                    .fill(color.opacity(0.2))
                    .blendMode(.overlay)
            )
            
        case .icon:
            Circle()
                .fill(.ultraThinMaterial)
                .liquidGlass(intensity: 0.8, tintColor: color)
            
        case .destructive:
            LiquidGlassBackground(
                intensity: 1.0,
                tintColor: .red,
                isAdaptive: true
            )
            .overlay(
                shape
                    .fill(Color.red.opacity(0.8))
                    .blendMode(.overlay)
            )
        }
    }
    
    @ViewBuilder
    private var shape: some Shape {
        switch style {
        case .pill:
            Capsule()
        case .icon:
            Circle()
        default:
            RoundedRectangle(cornerRadius: size.cornerRadius)
        }
    }
    
    private var contentColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary, .ghost:
            return color
        case .floating:
            return colorScheme == .dark ? .white : color
        case .pill:
            return color
        case .icon:
            return color
        }
    }
    
    private var backgroundIntensity: Double {
        switch style {
        case .primary, .destructive: return 1.0
        case .secondary: return 0.8
        case .floating: return 1.2
        case .pill: return 0.9
        case .icon: return 0.7
        case .ghost: return 0.0
        }
    }
    
    private var pressedScale: CGFloat {
        switch style {
        case .floating: return isPressed ? 0.94 : (isHovered ? 1.02 : 1.0)
        case .icon: return isPressed ? 0.9 : (isHovered ? 1.1 : 1.0)
        default: return isPressed ? 0.96 : (isHovered ? 1.01 : 1.0)
        }
    }
    
    private var fontWeight: Font.Weight {
        switch style {
        case .primary, .destructive: return .semibold
        case .floating: return .medium
        default: return .medium
        }
    }
    
    private var iconFont: Font {
        switch size {
        case .small: return .caption
        case .medium: return .subheadline
        case .large: return .title3
        case .extraLarge: return .title2
        }
    }
    
    private var pillPadding: EdgeInsets {
        switch size {
        case .small: return EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
        case .medium: return EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
        case .large: return EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        case .extraLarge: return EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
        }
    }
    
    private var rippleColor: Color {
        switch style {
        case .primary, .destructive: return .white
        case .ghost, .secondary, .pill, .floating, .icon: return color
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .floating: return 24
        case .primary, .destructive: return 12
        case .icon: return 8
        default: return 6
        }
    }
    
    private var shadowIntensity: Double {
        switch style {
        case .floating: return 0.25
        case .primary, .destructive: return 0.15
        case .secondary, .pill: return 0.1
        case .icon: return 0.12
        case .ghost: return 0.05
        }
    }
    
    private var shadowColor: Color {
        style == .destructive ? .red : .black
    }
    
    private func handleTap() {
        guard !isDisabled && !isLoading else { return }
        
        // Haptic feedback
        if let hapticStyle = hapticFeedback {
            let impact = UIImpactFeedbackGenerator(style: hapticStyle)
            impact.impactOccurred()
        }
        
        // Visual feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
        
        // Execute action
        action()
    }
}

// MARK: - Convenience Initializers
extension AdaptiveButton {
    // Primary button
    static func primary(
        _ title: String,
        icon: String? = nil,
        size: AdaptiveButtonSize = .medium,
        color: Color = .blue,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> AdaptiveButton {
        AdaptiveButton(
            title,
            icon: icon,
            style: .primary,
            size: size,
            color: color,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    // Secondary button
    static func secondary(
        _ title: String,
        icon: String? = nil,
        size: AdaptiveButtonSize = .medium,
        color: Color = .blue,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> AdaptiveButton {
        AdaptiveButton(
            title,
            icon: icon,
            style: .secondary,
            size: size,
            color: color,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    // Ghost button
    static func ghost(
        _ title: String,
        icon: String? = nil,
        color: Color = .blue,
        action: @escaping () -> Void
    ) -> AdaptiveButton {
        AdaptiveButton(
            title,
            icon: icon,
            style: .ghost,
            color: color,
            hapticFeedback: .light,
            action: action
        )
    }
    
    // Floating action button
    static func floating(
        icon: String,
        color: Color = .blue,
        size: AdaptiveButtonSize = .large,
        action: @escaping () -> Void
    ) -> AdaptiveButton {
        AdaptiveButton(
            icon: icon,
            style: .floating,
            size: size,
            color: color,
            hapticFeedback: .heavy,
            action: action
        )
    }
    
    // Pill button
    static func pill(
        _ title: String,
        icon: String? = nil,
        color: Color = .blue,
        size: AdaptiveButtonSize = .small,
        action: @escaping () -> Void
    ) -> AdaptiveButton {
        AdaptiveButton(
            title,
            icon: icon,
            style: .pill,
            size: size,
            color: color,
            hapticFeedback: .light,
            action: action
        )
    }
    
    // Icon button
    static func icon(
        _ icon: String,
        color: Color = .blue,
        size: AdaptiveButtonSize = .medium,
        action: @escaping () -> Void
    ) -> AdaptiveButton {
        AdaptiveButton(
            icon: icon,
            style: .icon,
            size: size,
            color: color,
            hapticFeedback: .light,
            action: action
        )
    }
    
    // Destructive button
    static func destructive(
        _ title: String,
        icon: String? = nil,
        size: AdaptiveButtonSize = .medium,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> AdaptiveButton {
        AdaptiveButton(
            title,
            icon: icon,
            style: .destructive,
            size: size,
            color: .red,
            isLoading: isLoading,
            hapticFeedback: .heavy,
            action: action
        )
    }
}

// MARK: - Button Group
struct AdaptiveButtonGroup: View {
    let buttons: [AdaptiveButton]
    let axis: Axis
    let spacing: CGFloat
    
    init(
        axis: Axis = .horizontal,
        spacing: CGFloat = 12,
        @ArrayBuilder<AdaptiveButton> buttons: () -> [AdaptiveButton]
    ) {
        self.axis = axis
        self.spacing = spacing
        self.buttons = buttons()
    }
    
    var body: some View {
        if axis == .horizontal {
            HStack(spacing: spacing) {
                ForEach(0..<buttons.count, id: \.self) { index in
                    buttons[index]
                        .frame(maxWidth: .infinity)
                }
            }
        } else {
            VStack(spacing: spacing) {
                ForEach(0..<buttons.count, id: \.self) { index in
                    buttons[index]
                }
            }
        }
    }
}

// MARK: - Array Builder
@resultBuilder
struct ArrayBuilder<Element> {
    static func buildBlock(_ elements: Element...) -> [Element] {
        elements
    }
    
    static func buildOptional(_ element: [Element]?) -> [Element] {
        element ?? []
    }
    
    static func buildEither(first: [Element]) -> [Element] {
        first
    }
    
    static func buildEither(second: [Element]) -> [Element] {
        second
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 32) {
            Text("iOS 26 Adaptive Buttons")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            // Button sizes
            VStack(spacing: 16) {
                Text("Primary Buttons - Different Sizes")
                    .font(.headline)
                    .padding(.top)
                
                AdaptiveButton.primary("Small", size: .small) {}
                AdaptiveButton.primary("Medium", size: .medium) {}
                AdaptiveButton.primary("Large", size: .large) {}
                AdaptiveButton.primary("Extra Large", size: .extraLarge) {}
            }
            
            // Button styles
            VStack(spacing: 16) {
                Text("Button Styles")
                    .font(.headline)
                
                AdaptiveButton.primary("Primary", icon: "checkmark") {}
                AdaptiveButton.secondary("Secondary", icon: "star") {}
                AdaptiveButton.ghost("Ghost", icon: "heart") {}
                
                HStack(spacing: 16) {
                    AdaptiveButton.floating(icon: "plus", color: .green) {}
                    AdaptiveButton.icon("heart.fill", color: .red) {}
                    AdaptiveButton.pill("Pill", color: .purple) {}
                }
                
                AdaptiveButton.destructive("Delete", icon: "trash") {}
            }
            
            // Button group
            VStack(spacing: 16) {
                Text("Button Groups")
                    .font(.headline)
                
                AdaptiveButtonGroup {
                    AdaptiveButton.secondary("Cancel") {}
                    AdaptiveButton.primary("Save") {}
                }
            }
            
            // Loading and disabled states
            VStack(spacing: 16) {
                Text("States")
                    .font(.headline)
                
                AdaptiveButton.primary("Loading", isLoading: true) {}
                AdaptiveButton.primary("Disabled", isDisabled: true) {}
            }
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.1), .purple.opacity(0.05), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
