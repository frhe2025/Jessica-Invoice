//
//  LiquidGlassEffects.swift
//  Jessica Invoice
//  🔧 FIXED - Generic parameter issues and removed duplicates
//

import SwiftUI

// MARK: - Liquid Glass Container (FIXED - Proper generic implementation)
struct LiquidGlassContainer<Content: View>: View {
    let content: Content
    let style: ContainerStyle
    let cornerRadius: CGFloat
    let intensity: Double
    
    @Environment(\.colorScheme) var colorScheme
    @State private var animationPhase: Double = 0
    
    enum ContainerStyle {
        case primary
        case subtle
        case dynamic
        case breathing
        
        var material: Material {
            switch self {
            case .primary: return .regularMaterial
            case .subtle: return .ultraThinMaterial
            case .dynamic: return .thickMaterial
            case .breathing: return .thinMaterial
            }
        }
        
        var intensity: Double {
            switch self {
            case .primary: return 0.8
            case .subtle: return 0.3
            case .dynamic: return 1.0
            case .breathing: return 0.6
            }
        }
    }
    
    init(
        style: ContainerStyle = .primary,
        cornerRadius: CGFloat = 16,
        intensity: Double = 0.8,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.intensity = intensity
        self.content = content()
    }
    
    var body: some View {
        content
            .background(containerBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(liquidBorder)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
            .onAppear {
                if style == .dynamic || style == .breathing {
                    startAnimation()
                }
            }
    }
    
    // MARK: - Static Factory Methods (FIXED)
    static func primary<T: View>(@ViewBuilder content: @escaping () -> T) -> LiquidGlassContainer<T> {
        LiquidGlassContainer<T>(style: .primary, content: content)
    }
    
    static func subtle<T: View>(@ViewBuilder content: @escaping () -> T) -> LiquidGlassContainer<T> {
        LiquidGlassContainer<T>(style: .subtle, content: content)
    }
    
    static func dynamic<T: View>(@ViewBuilder content: @escaping () -> T) -> LiquidGlassContainer<T> {
        LiquidGlassContainer<T>(style: .dynamic, content: content)
    }
    
    static func breathing<T: View>(@ViewBuilder content: @escaping () -> T) -> LiquidGlassContainer<T> {
        LiquidGlassContainer<T>(style: .breathing, content: content)
    }
    
    // MARK: - Background Components
    private var containerBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(style.material)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(liquidGradient)
                    .opacity(intensity * 0.3)
            )
    }
    
    private var liquidBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(borderGradient, lineWidth: 1)
    }
    
    private var liquidGradient: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.4),
                .white.opacity(0.1),
                .clear,
                .white.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(colorScheme == .dark ? 0.3 : 0.6),
                .white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Animation
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            animationPhase = 1.0
        }
    }
    
    // MARK: - Computed Properties
    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.1)
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .primary: return 15
        case .subtle: return 5
        case .dynamic: return 20
        case .breathing: return 12 + (animationPhase * 8)
        }
    }
    
    private var shadowOffset: CGFloat {
        switch style {
        case .primary: return 8
        case .subtle: return 2
        case .dynamic: return 10
        case .breathing: return 6 + (animationPhase * 4)
        }
    }
}

// MARK: - Liquid Glass Material Modifier
struct LiquidGlassMaterial: ViewModifier {
    let intensity: Double
    let tintColor: Color?
    let adaptive: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(glassMaterial)
            .overlay(glassOverlay)
    }
    
    private var glassMaterial: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(material)
    }
    
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(overlayGradient)
    }
    
    private var material: Material {
        switch intensity {
        case 0.0...0.3:
            return .ultraThinMaterial
        case 0.3...0.6:
            return .thinMaterial
        case 0.6...0.8:
            return .regularMaterial
        default:
            return .thickMaterial
        }
    }
    
    private var overlayGradient: LinearGradient {
        let baseColor = tintColor ?? (adaptive ? .accentColor : .white)
        
        return LinearGradient(
            colors: [
                baseColor.opacity(intensity * 0.2),
                baseColor.opacity(intensity * 0.1),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Liquid Glass Border Modifier
struct LiquidGlassBorder: ViewModifier {
    let width: CGFloat
    let opacity: Double
    let animated: Bool
    
    @State private var animationPhase: Double = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(borderOverlay)
            .onAppear {
                if animated {
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        animationPhase = 1.0
                    }
                }
            }
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(borderGradient, lineWidth: width)
    }
    
    private var borderGradient: LinearGradient {
        if animated {
            return LinearGradient(
                colors: [
                    .white.opacity(opacity),
                    .clear,
                    .white.opacity(opacity * 0.5),
                    .clear
                ],
                startPoint: .init(x: -0.3 + animationPhase, y: -0.3 + animationPhase),
                endPoint: .init(x: 0.7 + animationPhase, y: 0.7 + animationPhase)
            )
        } else {
            return LinearGradient(
                colors: [
                    .white.opacity(opacity),
                    .white.opacity(opacity * 0.5),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Liquid Glass Shadow Modifier
struct LiquidGlassShadow: ViewModifier {
    let radius: CGFloat
    let intensity: Double
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: shadowColor,
                radius: radius,
                x: 0,
                y: radius * 0.3
            )
    }
    
    private var shadowColor: Color {
        color.opacity(colorScheme == .dark ? intensity * 1.5 : intensity)
    }
}

// MARK: - Morphing Glass Effect
struct MorphingGlass: ViewModifier {
    let intensity: Double
    
    @State private var morphPhase: Double = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.0 + (morphPhase * intensity * 0.05))
            .opacity(1.0 - (morphPhase * intensity * 0.1))
            .blur(radius: morphPhase * intensity * 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                    morphPhase = 1.0
                }
            }
    }
}

// MARK: - Breathing Glass Effect
struct BreathingGlass: ViewModifier {
    let intensity: Double
    let duration: Double
    
    @State private var breathPhase: Double = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.0 + (breathPhase * intensity * 0.03))
            .opacity(1.0 - (breathPhase * intensity * 0.05))
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    breathPhase = 1.0
                }
            }
    }
}

// MARK: - Liquid Ripple Effect
struct LiquidRipple: ViewModifier {
    let trigger: Bool
    let color: Color
    
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 1
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                    .animation(.easeOut(duration: 0.6), value: rippleScale)
                    .animation(.easeOut(duration: 0.6), value: rippleOpacity)
            )
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    rippleScale = 0
                    rippleOpacity = 1
                    
                    withAnimation(.easeOut(duration: 0.6)) {
                        rippleScale = 2.0
                        rippleOpacity = 0
                    }
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func liquidGlass(
        intensity: Double = 1.0,
        tintColor: Color? = nil,
        adaptive: Bool = true
    ) -> some View {
        modifier(LiquidGlassMaterial(intensity: intensity, tintColor: tintColor, adaptive: adaptive))
    }
    
    func liquidBorder(
        width: CGFloat = 1,
        opacity: Double = 0.3,
        animated: Bool = false
    ) -> some View {
        modifier(LiquidGlassBorder(width: width, opacity: opacity, animated: animated))
    }
    
    func liquidShadow(
        radius: CGFloat = 20,
        intensity: Double = 0.15,
        color: Color = .black
    ) -> some View {
        modifier(LiquidGlassShadow(radius: radius, intensity: intensity, color: color))
    }
    
    func morphingGlass(intensity: Double = 1.0) -> some View {
        modifier(MorphingGlass(intensity: intensity))
    }
    
    func breathingEffect(
        intensity: Double = 0.3,
        duration: Double = 3.0
    ) -> some View {
        modifier(BreathingGlass(intensity: intensity, duration: duration))
    }
    
    func liquidRipple(
        trigger: Bool,
        color: Color = .white
    ) -> some View {
        modifier(LiquidRipple(trigger: trigger, color: color))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 32) {
        LiquidGlassContainer.primary {
            VStack {
                Text("Primary Container")
                    .font(.headline)
                Text("Regular liquid glass effect")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        
        LiquidGlassContainer.subtle {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Subtle Container")
                    .font(.subheadline)
            }
            .padding()
        }
        
        LiquidGlassContainer.dynamic {
            Text("Dynamic Container")
                .font(.title3.weight(.semibold))
                .padding()
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

