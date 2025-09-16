//
//  LiquidGlassBackground.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-16.
//


//
//  LiquidGlassBackground.swift
//  Jessica Invoice
//
//  📁 PLACERA I: Components/LiquidGlass/
//  iOS 26 Liquid Glass Background System
//

import SwiftUI

// MARK: - Liquid Glass Background
struct LiquidGlassBackground: View {
    let colors: [Color]
    let intensity: Double
    let isAnimated: Bool
    
    @State private var animationOffset: CGFloat = 0
    @State private var secondaryOffset: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    init(
        colors: [Color],
        intensity: Double = 0.08,
        isAnimated: Bool = true
    ) {
        self.colors = colors
        self.intensity = intensity
        self.isAnimated = isAnimated
    }
    
    var body: some View {
        ZStack {
            // Base gradient layer
            baseGradientLayer
            
            // Liquid mesh overlay
            liquidMeshOverlay
            
            // Depth enhancement
            depthEnhancementLayer
            
            // Noise texture (iOS 26 feature)
            if #available(iOS 18.0, *) {
                noiseTextureLayer
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if isAnimated {
                startLiquidAnimation()
            }
        }
    }
    
    // MARK: - Base Gradient Layer
    private var baseGradientLayer: some View {
        LinearGradient(
            colors: colors.map { 
                $0.opacity(colorScheme == .dark ? intensity * 0.6 : intensity) 
            },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Liquid Mesh Overlay
    private var liquidMeshOverlay: some View {
        ZStack {
            // Primary mesh
            RadialGradient(
                colors: [
                    colors.first?.opacity(intensity * 1.5) ?? .clear,
                    .clear,
                    colors.last?.opacity(intensity * 0.8) ?? .clear
                ],
                center: UnitPoint(
                    x: 0.3 + animationOffset * 0.4,
                    y: 0.2 + animationOffset * 0.3
                ),
                startRadius: 50,
                endRadius: 400
            )
            
            // Secondary mesh
            RadialGradient(
                colors: [
                    .clear,
                    colors.randomElement()?.opacity(intensity * 1.2) ?? .clear,
                    .clear
                ],
                center: UnitPoint(
                    x: 0.7 - secondaryOffset * 0.3,
                    y: 0.8 - secondaryOffset * 0.4
                ),
                startRadius: 80,
                endRadius: 350
            )
            
            // Tertiary accent mesh
            if colors.count > 2 {
                RadialGradient(
                    colors: [
                        colors[1].opacity(intensity * 0.6),
                        .clear
                    ],
                    center: UnitPoint(
                        x: 0.5 + animationOffset * 0.2,
                        y: 0.5 + secondaryOffset * 0.2
                    ),
                    startRadius: 100,
                    endRadius: 300
                )
            }
        }
        .blendMode(colorScheme == .dark ? .plusLighter : .multiply)
    }
    
    // MARK: - Depth Enhancement Layer
    private var depthEnhancementLayer: some View {
        LinearGradient(
            colors: [
                .white.opacity(colorScheme == .dark ? 0.02 : 0.4),
                .clear,
                .black.opacity(colorScheme == .dark ? 0.3 : 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blendMode(.overlay)
    }
    
    // MARK: - Noise Texture Layer (iOS 18+)
    @available(iOS 18.0, *)
    private var noiseTextureLayer: some View {
        // Simulated noise texture using small circles
        Canvas { context, size in
            let spacing: CGFloat = 3
            let opacity: Double = colorScheme == .dark ? 0.015 : 0.03
            
            for x in stride(from: 0, to: size.width, by: spacing) {
                for y in stride(from: 0, to: size.height, by: spacing) {
                    let randomOpacity = Double.random(in: 0...opacity)
                    let color = Color.white.opacity(randomOpacity)
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(color)
                    )
                }
            }
        }
    }
    
    // MARK: - Animation Functions
    private func startLiquidAnimation() {
        withAnimation(
            .linear(duration: 20.0)
            .repeatForever(autoreverses: true)
        ) {
            animationOffset = 1.0
        }
        
        withAnimation(
            .linear(duration: 15.0)
            .repeatForever(autoreverses: true)
        ) {
            secondaryOffset = 1.0
        }
    }
}

// MARK: - Predefined Liquid Backgrounds
extension LiquidGlassBackground {
    static let invoice = LiquidGlassBackground(
        colors: [.blue, .indigo, .cyan],
        intensity: 0.06
    )
    
    static let products = LiquidGlassBackground(
        colors: [.green, .mint, .teal],
        intensity: 0.05
    )
    
    static let history = LiquidGlassBackground(
        colors: [.orange, .yellow, .red],
        intensity: 0.07
    )
    
    static let settings = LiquidGlassBackground(
        colors: [.purple, .pink, .indigo],
        intensity: 0.06
    )
    
    static let dashboard = LiquidGlassBackground(
        colors: [.blue, .purple, .indigo, .cyan],
        intensity: 0.08
    )
    
    static let neutral = LiquidGlassBackground(
        colors: [.gray, .secondary],
        intensity: 0.03,
        isAnimated: false
    )
}

// MARK: - Contextual Liquid Background
struct ContextualLiquidBackground: View {
    let context: BackgroundContext
    @Environment(\.colorScheme) var colorScheme
    
    enum BackgroundContext {
        case invoice
        case products
        case history
        case settings
        case dashboard
        case neutral
        case custom([Color])
        
        var liquidBackground: LiquidGlassBackground {
            switch self {
            case .invoice: return .invoice
            case .products: return .products
            case .history: return .history
            case .settings: return .settings
            case .dashboard: return .dashboard
            case .neutral: return .neutral
            case .custom(let colors): return LiquidGlassBackground(colors: colors)
            }
        }
    }
    
    var body: some View {
        context.liquidBackground
    }
}

// MARK: - Adaptive Liquid Material
struct AdaptiveLiquidMaterial: View {
    let baseColor: Color
    let intensity: Double
    
    @Environment(\.colorScheme) var colorScheme
    @State private var dominantColor: Color = .blue
    
    init(baseColor: Color = .accentColor, intensity: Double = 0.1) {
        self.baseColor = baseColor
        self.intensity = intensity
    }
    
    var body: some View {
        LiquidGlassBackground(
            colors: adaptiveColors,
            intensity: intensity
        )
        .onReceive(NotificationCenter.default.publisher(for: .accentColorChanged)) { _ in
            updateDominantColor()
        }
        .onAppear {
            updateDominantColor()
        }
    }
    
    private var adaptiveColors: [Color] {
        [
            dominantColor,
            dominantColor.lighter(by: 0.3),
            dominantColor.darker(by: 0.2)
        ]
    }
    
    private func updateDominantColor() {
        dominantColor = baseColor
    }
}

// MARK: - Liquid Glass Surface
struct LiquidGlassSurface<Content: View>: View {
    let content: Content
    let backgroundContext: ContextualLiquidBackground.BackgroundContext
    
    init(
        backgroundContext: ContextualLiquidBackground.BackgroundContext = .neutral,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundContext = backgroundContext
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            ContextualLiquidBackground(context: backgroundContext)
            content
        }
    }
}

// MARK: - View Extension for Easy Usage
extension View {
    func liquidGlassBackground(_ context: ContextualLiquidBackground.BackgroundContext) -> some View {
        background(ContextualLiquidBackground(context: context))
    }
    
    func adaptiveLiquidBackground(baseColor: Color = .accentColor, intensity: Double = 0.1) -> some View {
        background(AdaptiveLiquidMaterial(baseColor: baseColor, intensity: intensity))
    }
}

// MARK: - Color Extensions for Liquid Effects
extension Color {
    func lighter(by percentage: Double = 0.2) -> Color {
        return self.opacity(1 - percentage)
    }
    
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
}

// MARK: - Notification Extension
extension Notification.Name {
    static let accentColorChanged = Notification.Name("accentColorChanged")
}

#Preview {
    VStack(spacing: 20) {
        Text("Invoice Background")
            .font(.title)
            .padding()
            .liquidGlassBackground(.invoice)
            .frame(height: 200)
        
        Text("Products Background")
            .font(.title)
            .padding()
            .liquidGlassBackground(.products)
            .frame(height: 200)
        
        Text("Adaptive Background")
            .font(.title)
            .padding()
            .adaptiveLiquidBackground(baseColor: .orange, intensity: 0.15)
            .frame(height: 200)
    }
    .padding()
}