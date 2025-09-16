//
//  LiquidGlassEffects.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//  iOS 26 Liquid Glass Implementation
//

import SwiftUI

// MARK: - Liquid Glass Material
struct LiquidGlassMaterial: ViewModifier {
    let intensity: Double
    let tintColor: Color?
    let isAdaptive: Bool
    
    init(intensity: Double = 1.0, tintColor: Color? = nil, adaptive: Bool = true) {
        self.intensity = intensity
        self.tintColor = tintColor
        self.isAdaptive = adaptive
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                LiquidGlassBackground(
                    intensity: intensity,
                    tintColor: tintColor,
                    isAdaptive: isAdaptive
                )
            )
    }
}

struct LiquidGlassBackground: View {
    let intensity: Double
    let tintColor: Color?
    let isAdaptive: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base material layer
            if #available(iOS 18.0, *) {
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(intensity * 0.8))
            } else {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(intensity * 0.8)
            }
            
            // Liquid overlay with adaptive tinting
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: liquidColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(intensity * 0.12)
                .blendMode(.overlay)
            
            // Luminance layer for depth
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(intensity * 0.15),
                            .clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .blendMode(.softLight)
        }
    }
    
    private var liquidColors: [Color] {
        if let tintColor = tintColor {
            return [
                tintColor.opacity(0.3),
                tintColor.opacity(0.1),
                .clear
            ]
        }
        
        if isAdaptive {
            return colorScheme == .dark ?
                [.white.opacity(0.08), .blue.opacity(0.05), .clear] :
                [.blue.opacity(0.06), .white.opacity(0.12), .clear]
        }
        
        return [.white.opacity(0.08), .clear]
    }
}

// MARK: - Liquid Glass Border
struct LiquidGlassBorder: ViewModifier {
    let width: CGFloat
    let opacity: Double
    let animated: Bool
    
    @State private var animationPhase: CGFloat = 0
    
    init(width: CGFloat = 1, opacity: Double = 0.3, animated: Bool = false) {
        self.width = width
        self.opacity = opacity
        self.animated = animated
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: borderColors,
                            startPoint: animated ?
                                UnitPoint(x: animationPhase, y: 0) :
                                .topLeading,
                            endPoint: animated ?
                                UnitPoint(x: animationPhase + 0.3, y: 1) :
                                .bottomTrailing
                        ),
                        lineWidth: width
                    )
            )
            .onAppear {
                if animated {
                    withAnimation(
                        .linear(duration: 3)
                        .repeatForever(autoreverses: true)
                    ) {
                        animationPhase = 1.0
                    }
                }
            }
    }
    
    private var borderColors: [Color] {
        [
            .white.opacity(opacity * 0.8),
            .white.opacity(opacity * 0.3),
            .clear,
            .white.opacity(opacity * 0.5)
        ]
    }
}

// MARK: - Liquid Glass Shadow
struct LiquidGlassShadow: ViewModifier {
    let radius: CGFloat
    let intensity: Double
    let color: Color
    
    init(radius: CGFloat = 20, intensity: Double = 0.15, color: Color = .black) {
        self.radius = radius
        self.intensity = intensity
        self.color = color
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(intensity * 0.4),
                radius: radius * 0.3,
                x: 0,
                y: 2
            )
            .shadow(
                color: color.opacity(intensity * 0.2),
                radius: radius * 0.6,
                x: 0,
                y: 4
            )
            .shadow(
                color: color.opacity(intensity * 0.1),
                radius: radius,
                x: 0,
                y: 8
            )
    }
}

// MARK: - Morphing Glass Effect
struct MorphingGlass: ViewModifier {
    @State private var morphPhase: CGFloat = 0
    let intensity: Double
    
    init(intensity: Double = 1.0) {
        self.intensity = intensity
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base glass
                    Rectangle()
                        .fill(.ultraThinMaterial)
                    
                    // Morphing overlay
                    GeometryReader { geometry in
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            
                            path.move(to: CGPoint(x: 0, y: height * (0.3 + sin(morphPhase) * 0.1)))
                            path.addCurve(
                                to: CGPoint(x: width, y: height * (0.7 + cos(morphPhase * 1.2) * 0.1)),
                                control1: CGPoint(x: width * 0.3, y: height * (0.1 + sin(morphPhase * 1.5) * 0.05)),
                                control2: CGPoint(x: width * 0.7, y: height * (0.9 + cos(morphPhase * 0.8) * 0.05))
                            )
                            path.addLine(to: CGPoint(x: width, y: height))
                            path.addLine(to: CGPoint(x: 0, y: height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(intensity * 0.1),
                                    .blue.opacity(intensity * 0.05),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.overlay)
                    }
                }
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true)
                ) {
                    morphPhase = .pi * 2
                }
            }
    }
}

// MARK: - Liquid Ripple Effect
struct LiquidRipple: ViewModifier {
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0
    @State private var rippleOffset: CGSize = .zero
    
    let trigger: Bool
    let color: Color
    
    init(trigger: Bool, color: Color = .white) {
        self.trigger = trigger
        self.color = color
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.3),
                                color.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                    .offset(rippleOffset)
                    .allowsHitTesting(false)
            )
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    createRipple()
                }
            }
    }
    
    private func createRipple() {
        withAnimation(.easeOut(duration: 0.6)) {
            rippleScale = 3.0
            rippleOpacity = 0
        }
        
        rippleScale = 0
        rippleOpacity = 1
    }
}

// MARK: - Breathing Glass Effect
struct BreathingGlass: ViewModifier {
    @State private var breathPhase: CGFloat = 0
    let intensity: Double
    let duration: Double
    
    init(intensity: Double = 0.3, duration: Double = 3.0) {
        self.intensity = intensity
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.0 + sin(breathPhase) * intensity * 0.02)
            .opacity(1.0 - sin(breathPhase) * intensity * 0.1)
            .blur(radius: sin(breathPhase) * intensity * 0.5)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    breathPhase = .pi * 2
                }
            }
    }
}

// MARK: - Liquid Glass Container
struct LiquidGlassContainer<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let intensity: Double
    let tintColor: Color?
    let hasRipple: Bool
    let isMorphing: Bool
    
    @State private var isPressed = false
    
    init(
        cornerRadius: CGFloat = 20,
        intensity: Double = 1.0,
        tintColor: Color? = nil,
        hasRipple: Bool = false,
        isMorphing: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.intensity = intensity
        self.tintColor = tintColor
        self.hasRipple = hasRipple
        self.isMorphing = isMorphing
        self.content = content()
    }
    
    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .modifier(LiquidGlassMaterial(intensity: intensity, tintColor: tintColor))
            .if(isMorphing) { view in
                view.modifier(MorphingGlass(intensity: intensity))
            }
            .modifier(LiquidGlassBorder(animated: hasRipple))
            .modifier(LiquidGlassShadow(radius: cornerRadius))
            .if(hasRipple) { view in
                view.modifier(LiquidRipple(trigger: isPressed))
            }
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onTapGesture {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
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

// MARK: - Predefined Liquid Glass Styles
extension LiquidGlassContainer {
    static func primary<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LiquidGlassContainer(
            cornerRadius: 16,
            intensity: 1.0,
            tintColor: .blue,
            hasRipple: true,
            content: content
        )
    }
    
    static func subtle<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LiquidGlassContainer(
            cornerRadius: 12,
            intensity: 0.6,
            tintColor: nil,
            hasRipple: false,
            content: content
        )
    }
    
    static func dynamic<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LiquidGlassContainer(
            cornerRadius: 20,
            intensity: 1.2,
            tintColor: .purple,
            hasRipple: true,
            isMorphing: true,
            content: content
        )
    }
    
    static func breathing<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LiquidGlassContainer(
            cornerRadius: 24,
            intensity: 0.8,
            tintColor: .green,
            content: content
        )
        .breathingEffect(intensity: 0.2)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 32) {
            Text("iOS 26 Liquid Glass Effects")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            // Primary Liquid Glass
            LiquidGlassContainer.primary {
                VStack {
                    Image(systemName: "star.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    Text("Primary Liquid Glass")
                        .font(.headline)
                }
                .padding(24)
            }
            
            // Morphing Glass
            LiquidGlassContainer.dynamic {
                VStack {
                    Image(systemName: "waveform")
                        .font(.largeTitle)
                        .foregroundStyle(.purple)
                    Text("Dynamic Morphing Glass")
                        .font(.headline)
                }
                .padding(24)
            }
            
            // Breathing Glass
            LiquidGlassContainer.breathing {
                VStack {
                    Image(systemName: "heart.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("Breathing Glass Effect")
                        .font(.headline)
                }
                .padding(24)
            }
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.2), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
