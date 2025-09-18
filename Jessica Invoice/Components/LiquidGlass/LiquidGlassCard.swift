//
//  LiquidGlassCard.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-16.
//


//
//  LiquidGlassCard.swift
//  Jessica Invoice
//
//  📁 PLACERA I: Components/LiquidGlass/
//  iOS 26 Liquid Glass Implementation
//

import SwiftUI

// MARK: - iOS 26 Liquid Glass Card
struct LiquidGlassCard<Content: View>: View {
    let content: Content
    let style: LiquidGlassStyle
    let depth: LiquidDepth
    let adaptiveColor: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @State private var animationPhase = 0.0
    @State private var interactionIntensity = 0.0
    
    init(
        style: LiquidGlassStyle = .adaptive,
        depth: LiquidDepth = .medium,
        adaptiveColor: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.depth = depth
        self.adaptiveColor = adaptiveColor
        self.content = content()
    }
    
    var body: some View {
        content
            .background(liquidGlassBackground)
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
            .overlay(liquidGlassOverlay)
            .shadow(color: shadowColor, radius: depth.shadowRadius, x: 0, y: depth.shadowOffset)
            .scaleEffect(1.0 + interactionIntensity * 0.02)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    interactionIntensity = 0.5
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        interactionIntensity = 0.0
                    }
                }
            }
            .onAppear {
                startLiquidAnimation()
            }
    }
    
    // MARK: - Liquid Glass Background
    private var liquidGlassBackground: some View {
        ZStack {
            // Base glass material
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .fill(style.baseMaterial)
            
            // Liquid shimmer effect
            if style.hasShimmer {
                liquidShimmerEffect
            }
            
            // Adaptive color overlay
            if adaptiveColor {
                adaptiveColorOverlay
            }
        }
    }
    
    // MARK: - Liquid Shimmer Effect
    private var liquidShimmerEffect: some View {
        LinearGradient(
            colors: [
                .clear,
                .white.opacity(0.3),
                .clear,
                .white.opacity(0.2),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .mask(
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [.clear, .white, .clear],
                        startPoint: .init(x: -0.3 + animationPhase, y: -0.3 + animationPhase),
                        endPoint: .init(x: 0.7 + animationPhase, y: 0.7 + animationPhase)
                    )
                )
        )
        .animation(.linear(duration: 3.0).repeatForever(autoreverses: false), value: animationPhase)
    }
    
    // MARK: - Adaptive Color Overlay
    private var adaptiveColorOverlay: some View {
        RoundedRectangle(cornerRadius: style.cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        adaptiveAccentColor.opacity(0.1),
                        adaptiveAccentColor.opacity(0.05),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    // MARK: - Liquid Glass Overlay
    private var liquidGlassOverlay: some View {
        RoundedRectangle(cornerRadius: style.cornerRadius)
            .stroke(
                LinearGradient(
                    colors: strokeColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: style.strokeWidth
            )
    }
    
    // MARK: - Computed Properties
    private var shadowColor: Color {
        colorScheme == .dark ? 
            .black.opacity(0.4) : 
            .black.opacity(0.1)
    }
    
    private var strokeColors: [Color] {
        [
            .white.opacity(colorScheme == .dark ? 0.15 : 0.4),
            .white.opacity(colorScheme == .dark ? 0.05 : 0.2),
            .clear,
            .white.opacity(colorScheme == .dark ? 0.1 : 0.3)
        ]
    }
    
    private var adaptiveAccentColor: Color {
        // This would ideally sample the dominant color from content
        // For now, using system accent color
        .accentColor
    }
    
    // MARK: - Animation Functions
    private func startLiquidAnimation() {
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
    }
}

// MARK: - Liquid Glass Styles
enum LiquidGlassStyle {
    case minimal
    case adaptive
    case prominent
    case floating
    case interactive
    
    var cornerRadius: CGFloat {
        switch self {
        case .minimal: return 12
        case .adaptive: return 16
        case .prominent: return 20
        case .floating: return 24
        case .interactive: return 18
        }
    }
    
    var baseMaterial: Material {
        switch self {
        case .minimal: return .thin
        case .adaptive: return .ultraThin
        case .prominent: return .regular
        case .floating: return .thick
        case .interactive: return .ultraThin
        }
    }
    
    var strokeWidth: CGFloat {
        switch self {
        case .minimal: return 0.5
        case .adaptive: return 1.0
        case .prominent: return 1.5
        case .floating: return 1.0
        case .interactive: return 1.2
        }
    }
    
    var hasShimmer: Bool {
        switch self {
        case .minimal: return false
        case .adaptive: return true
        case .prominent: return true
        case .floating: return true
        case .interactive: return true
        }
    }
}

// MARK: - Liquid Depth Levels
enum LiquidDepth {
    case subtle
    case medium
    case deep
    case floating
    
    var shadowRadius: CGFloat {
        switch self {
        case .subtle: return 4
        case .medium: return 12
        case .deep: return 20
        case .floating: return 30
        }
    }
    
    var shadowOffset: CGFloat {
        switch self {
        case .subtle: return 2
        case .medium: return 6
        case .deep: return 10
        case .floating: return 15
        }
    }
}

// MARK: - Convenience Initializers
extension LiquidGlassCard {
    static func minimal<ViewContent: View>(@ViewBuilder content: @escaping () -> ViewContent) -> LiquidGlassCard<ViewContent> {
        LiquidGlassCard<ViewContent>(style: .minimal, depth: .subtle, content: content)
    }
    
    static func adaptive<ViewContent: View>(@ViewBuilder content: @escaping () -> ViewContent) -> LiquidGlassCard<ViewContent> {
        LiquidGlassCard<ViewContent>(style: .adaptive, depth: .medium, content: content)
    }
    
    static func prominent<ViewContent: View>(@ViewBuilder content: @escaping () -> ViewContent) -> LiquidGlassCard<ViewContent> {
        LiquidGlassCard<ViewContent>(style: .prominent, depth: .deep, content: content)
    }
    
    static func floating<ViewContent: View>(@ViewBuilder content: @escaping () -> ViewContent) -> LiquidGlassCard<ViewContent> {
        LiquidGlassCard<ViewContent>(style: .floating, depth: .floating, content: content)
    }
    
    static func interactive<ViewContent: View>(@ViewBuilder content: @escaping () -> ViewContent) -> LiquidGlassCard<ViewContent> {
        LiquidGlassCard<ViewContent>(style: .interactive, depth: .medium, content: content)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            LiquidGlassCard.minimal {
                VStack {
                    Text("Minimal Card")
                        .font(.headline)
                    Text("Clean and simple design")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            
            LiquidGlassCard.prominent {
                VStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.yellow.gradient)
                    
                    Text("Prominent Card")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Enhanced with liquid shimmer effects")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            }
            
            LiquidGlassCard.floating {
                HStack(spacing: 16) {
                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 50, height: 50)
                    
                    VStack(alignment: .leading) {
                        Text("Floating Card")
                            .font(.headline)
                        Text("Elevated with deep shadows")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
        }
        .padding(20)
    }
    .background(.gray.opacity(0.1))
}
