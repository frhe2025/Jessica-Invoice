//
//  GradientBackground.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

struct GradientBackground: View {
    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    let opacity: Double
    
    init(
        colors: [Color],
        startPoint: UnitPoint = .top,
        endPoint: UnitPoint = .bottom,
        opacity: Double = 0.03
    ) {
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.opacity = opacity
    }
    
    var body: some View {
        LinearGradient(
            colors: colors.map { $0.opacity(opacity) } + [.clear],
            startPoint: startPoint,
            endPoint: endPoint
        )
        .ignoresSafeArea()
    }
}

// MARK: - Predefined Gradients
extension GradientBackground {
    static let invoice = GradientBackground(colors: [.blue])
    static let products = GradientBackground(colors: [.green])
    static let history = GradientBackground(colors: [.orange])
    static let settings = GradientBackground(colors: [.purple])
    
    static let sunrise = GradientBackground(
        colors: [.orange, .pink, .yellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing,
        opacity: 0.05
    )
    
    static let ocean = GradientBackground(
        colors: [.blue, .cyan, .teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing,
        opacity: 0.04
    )
    
    static let forest = GradientBackground(
        colors: [.green, .mint],
        startPoint: .top,
        endPoint: .bottom,
        opacity: 0.03
    )
    
    static let sunset = GradientBackground(
        colors: [.purple, .pink, .orange],
        startPoint: .topTrailing,
        endPoint: .bottomLeading,
        opacity: 0.05
    )
}

// MARK: - Simple Animated Gradient Background (renamed to avoid ambiguity)
struct SimpleAnimatedGradientBackground: View {
    let colors: [Color]
    let duration: Double
    @State private var animationOffset: CGFloat = 0
    
    init(colors: [Color], duration: Double = 8.0) {
        self.colors = colors
        self.duration = duration
    }
    
    var body: some View {
        LinearGradient(
            colors: colors.map { $0.opacity(0.03) } + [.clear],
            startPoint: UnitPoint(
                x: 0.5 + animationOffset * 0.3,
                y: 0.0 + animationOffset * 0.2
            ),
            endPoint: UnitPoint(
                x: 0.5 - animationOffset * 0.3,
                y: 1.0 - animationOffset * 0.2
            )
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
            ) {
                animationOffset = 1.0
            }
        }
    }
}

// MARK: - Mesh Gradient Background (iOS 18+)
@available(iOS 18.0, *)
struct MeshGradientBackground: View {
    let colors: [Color]
    let points: [SIMD2<Float>]
    
    init(colors: [Color]) {
        self.colors = colors
        // Create a 3x3 mesh of points
        self.points = [
            SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
            SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1.0, 0.5),
            SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
        ]
    }
    
    var body: some View {
        if #available(iOS 18.0, *) {
            MeshGradient(
                width: 3,
                height: 3,
                points: points,
                colors: colors.map { $0.opacity(0.05) }
            )
            .ignoresSafeArea()
        } else {
            // Fallback to linear gradient
            GradientBackground(colors: colors)
        }
    }
}

// MARK: - Glass Overlay
struct GlassOverlay: View {
    let intensity: Double
    
    init(intensity: Double = 0.1) {
        self.intensity = intensity
    }
    
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .opacity(intensity)
            .ignoresSafeArea()
    }
}

// MARK: - Background View Modifier
struct BackgroundModifier: ViewModifier {
    let gradient: GradientBackground
    let hasGlassOverlay: Bool
    
    func body(content: Content) -> some View {
        content
            .background(gradient)
            .background(hasGlassOverlay ? GlassOverlay(intensity: 0.05) : nil)
    }
}

extension View {
    func gradientBackground(
        _ gradient: GradientBackground,
        glassOverlay: Bool = false
    ) -> some View {
        modifier(BackgroundModifier(gradient: gradient, hasGlassOverlay: glassOverlay))
    }
    
    func invoiceBackground() -> some View {
        gradientBackground(.invoice)
    }
    
    func productsBackground() -> some View {
        gradientBackground(.products)
    }
    
    func historyBackground() -> some View {
        gradientBackground(.history)
    }
    
    func settingsBackground() -> some View {
        gradientBackground(.settings)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 32) {
            Text("Gradient Backgrounds")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                ForEach(["Invoice", "Products", "History", "Settings"], id: \.self) { title in
                    VStack {
                        Text(title)
                            .font(.headline)
                            .padding()
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding()
        }
    }
    .gradientBackground(.sunrise)
}
