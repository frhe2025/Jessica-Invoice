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
@available(iOS 18.0, *)
struct LiquidGlassCard<Content: View>: View {
    let content: Content
    let style: LiquidGlassStyle
    let depth: LiquidDepth
    let adaptiveColor: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false
    
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
        Group {
            content
                .padding(paddingForStyle)
                .glassEffect(in: .rect(cornerRadius: style.cornerRadius))
                .shadow(color: shadowColor, radius: depth.shadowRadius, x: 0, y: depth.shadowOffset)
                .scaleEffect(isPressed && !reduceMotion ? 0.98 : 1.0)
                .onTapGesture {
                    guard !reduceMotion else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPressed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { isPressed = false }
                    }
                }
        }
    }
    
    // MARK: - Computed Properties
    private var shadowColor: Color {
        colorScheme == .dark ?
            .black.opacity(0.4) :
            .black.opacity(0.1)
    }
    
    private var paddingForStyle: CGFloat {
        switch style {
        case .minimal: return 12
        case .adaptive: return 16
        case .prominent: return 20
        case .floating: return 20
        case .interactive: return 16
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
    static func minimal(@ViewBuilder content: () -> Content) -> Self {
        Self(style: .minimal, depth: .subtle, content: content)
    }
    
    static func adaptive(@ViewBuilder content: () -> Content) -> Self {
        Self(style: .adaptive, depth: .medium, content: content)
    }
    
    static func prominent(@ViewBuilder content: () -> Content) -> Self {
        Self(style: .prominent, depth: .deep, content: content)
    }
    
    static func floating(@ViewBuilder content: () -> Content) -> Self {
        Self(style: .floating, depth: .floating, content: content)
    }
    
    static func interactive(@ViewBuilder content: () -> Content) -> Self {
        Self(style: .interactive, depth: .medium, content: content)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            LiquidGlassCard(style: .minimal, depth: .subtle) {
                VStack {
                    Text("Minimal Card")
                        .font(.headline)
                    Text("Clean and simple design")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            
            LiquidGlassCard(style: .prominent, depth: .deep) {
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
            
            LiquidGlassCard(style: .floating, depth: .floating) {
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
