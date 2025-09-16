//
//  AnimatedGradientBackground.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-16.
//


//
//  AnimatedGradientBackground.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//  iOS 26 Animated Liquid Glass Background
//

import SwiftUI

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    let colors: [Color]
    let duration: Double
    let intensity: Double
    let blendMode: BlendMode
    
    @State private var animationPhase: CGFloat = 0
    @State private var secondaryPhase: CGFloat = 0
    @State private var pulsePhase: CGFloat = 0
    
    init(
        colors: [Color],
        duration: Double = 8.0,
        intensity: Double = 0.15,
        blendMode: BlendMode = .overlay
    ) {
        self.colors = colors
        self.duration = duration
        self.intensity = intensity
        self.blendMode = blendMode
    }
    
    var body: some View {
        ZStack {
            // Base gradient layer
            baseGradient
            
            // Animated flowing layer
            flowingGradient
            
            // Pulse overlay
            pulseOverlay
            
            // Particle effect layer
            particleLayer
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
    }
    
    @ViewBuilder
    private var baseGradient: some View {
        LinearGradient(
            colors: colors.map { $0.opacity(intensity * 0.5) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: duration * 2), value: colors)
    }
    
    @ViewBuilder
    private var flowingGradient: some View {
        LinearGradient(
            colors: colors.map { $0.opacity(intensity * 0.8) } + [.clear],
            startPoint: UnitPoint(
                x: 0.3 + sin(animationPhase) * 0.4,
                y: 0.2 + cos(animationPhase * 0.8) * 0.3
            ),
            endPoint: UnitPoint(
                x: 0.7 + cos(animationPhase * 1.2) * 0.3,
                y: 0.8 + sin(animationPhase * 0.6) * 0.2
            )
        )
        .blendMode(blendMode)
    }
    
    @ViewBuilder
    private var pulseOverlay: some View {
        RadialGradient(
            colors: [
                colors.first?.opacity(intensity * pulseIntensity) ?? .clear,
                .clear
            ],
            center: .center,
            startRadius: 50 * (1 + pulsePhase * 0.5),
            endRadius: 400 * (1 + pulsePhase * 0.3)
        )
        .blendMode(.softLight)
    }
    
    @ViewBuilder
    private var particleLayer: some View {
        GeometryReader { geometry in
            ForEach(0..<particleCount, id: \.self) { index in
                ParticleView(
                    color: colors.randomElement() ?? .blue,
                    size: geometry.size,
                    intensity: intensity,
                    animationOffset: Double(index) * 0.1
                )
            }
        }
    }
    
    private var pulseIntensity: Double {
        0.3 + sin(pulsePhase) * 0.2
    }
    
    private var particleCount: Int {
        Int(intensity * 8) + 2
    }
    
    private func startAnimations() {
        // Main flowing animation
        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
        ) {
            animationPhase = .pi * 2
        }
        
        // Secondary animation for variety
        withAnimation(
            .easeInOut(duration: duration * 1.5)
            .repeatForever(autoreverses: true)
        ) {
            secondaryPhase = .pi * 1.5
        }
        
        // Pulse animation
        withAnimation(
            .easeInOut(duration: duration * 0.5)
            .repeatForever(autoreverses: true)
        ) {
            pulsePhase = 1.0
        }
    }
}

// MARK: - Particle View
struct ParticleView: View {
    let color: Color
    let size: CGSize
    let intensity: Double
    let animationOffset: Double
    
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(intensity * 0.6),
                        color.opacity(intensity * 0.2),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 20
                )
            )
            .frame(width: particleSize, height: particleSize)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(position)
            .blur(radius: 2)
            .onAppear {
                setupInitialState()
                startParticleAnimation()
            }
    }
    
    private var particleSize: CGFloat {
        CGFloat(intensity * 40 + 10)
    }
    
    private func setupInitialState() {
        position = CGPoint(
            x: CGFloat.random(in: 0...size.width),
            y: CGFloat.random(in: 0...size.height)
        )
        opacity = Double.random(in: 0.1...(intensity * 0.8))
        scale = CGFloat.random(in: 0.3...0.8)
    }
    
    private func startParticleAnimation() {
        withAnimation(
            .easeInOut(duration: 4 + animationOffset * 2)
            .repeatForever(autoreverses: true)
        ) {
            position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            opacity = Double.random(in: 0.05...(intensity * 0.6))
            scale = CGFloat.random(in: 0.2...1.0)
        }
    }
}

// MARK: - Liquid Wave Background
struct LiquidWaveBackground: View {
    let colors: [Color]
    let waveHeight: CGFloat
    let waveSpeed: Double
    
    @State private var waveOffset: CGFloat = 0
    @State private var secondWaveOffset: CGFloat = 0
    
    init(colors: [Color], waveHeight: CGFloat = 100, waveSpeed: Double = 2.0) {
        self.colors = colors
        self.waveHeight = waveHeight
        self.waveSpeed = waveSpeed
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: colors.map { $0.opacity(0.1) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // First wave
                WaveShape(offset: waveOffset, waveHeight: waveHeight)
                    .fill(
                        LinearGradient(
                            colors: [
                                colors.first?.opacity(0.15) ?? .clear,
                                colors.first?.opacity(0.05) ?? .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.overlay)
                
                // Second wave (inverted)
                WaveShape(offset: -secondWaveOffset, waveHeight: waveHeight * 0.8)
                    .fill(
                        LinearGradient(
                            colors: [
                                colors.last?.opacity(0.1) ?? .clear,
                                .clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .blendMode(.softLight)
                    .rotation3DEffect(
                        .degrees(180),
                        axis: (x: 1.0, y: 0.0, z: 0.0)
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .linear(duration: waveSpeed)
                .repeatForever(autoreverses: false)
            ) {
                waveOffset = geometry.size.width + 100
            }
            
            withAnimation(
                .linear(duration: waveSpeed * 1.5)
                .repeatForever(autoreverses: false)
            ) {
                secondWaveOffset = geometry.size.width + 100
            }
        }
    }
}

// MARK: - Wave Shape
struct WaveShape: Shape {
    let offset: CGFloat
    let waveHeight: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = (x + offset) / width
            let sine = sin(relativeX * .pi * 4) * waveHeight * 0.5
            let cosine = cos(relativeX * .pi * 2) * waveHeight * 0.3
            let y = midHeight + sine + cosine
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Aurora Background
struct AuroraBackground: View {
    let colors: [Color]
    let intensity: Double
    
    @State private var auroraPhase: CGFloat = 0
    @State private var wavePhase: CGFloat = 0
    
    init(colors: [Color], intensity: Double = 0.2) {
        self.colors = colors
        self.intensity = intensity
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base dark background
                Color.black.opacity(0.02)
                
                // Aurora layers
                ForEach(0..<3, id: \.self) { index in
                    AuroraLayer(
                        color: colors[safe: index] ?? colors.first ?? .blue,
                        intensity: intensity,
                        offset: auroraPhase * Double(index + 1) * 0.3,
                        waveOffset: wavePhase * Double(index + 1) * 0.2
                    )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 12)
                .repeatForever(autoreverses: true)
            ) {
                auroraPhase = .pi * 2
            }
            
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                wavePhase = .pi * 4
            }
        }
    }
}

struct AuroraLayer: View {
    let color: Color
    let intensity: Double
    let offset: Double
    let waveOffset: Double
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                path.move(to: CGPoint(x: 0, y: height * 0.3))
                
                for x in stride(from: 0, through: width, by: 2) {
                    let relativeX = x / width
                    let sine1 = sin((relativeX + offset) * .pi * 3) * height * 0.1
                    let sine2 = sin((relativeX + waveOffset) * .pi * 5) * height * 0.05
                    let y = height * 0.3 + sine1 + sine2
                    
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(intensity * 0.8),
                        color.opacity(intensity * 0.3),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blendMode(.screen)
        }
    }
}

// MARK: - Preset Backgrounds
extension AnimatedGradientBackground {
    static let invoice = AnimatedGradientBackground(
        colors: [.blue, .cyan, .indigo],
        duration: 8.0,
        intensity: 0.12
    )
    
    static let products = AnimatedGradientBackground(
        colors: [.green, .mint, .teal],
        duration: 10.0,
        intensity: 0.15
    )
    
    static let history = AnimatedGradientBackground(
        colors: [.orange, .yellow, .pink],
        duration: 12.0,
        intensity: 0.18
    )
    
    static let settings = AnimatedGradientBackground(
        colors: [.purple, .pink, .indigo],
        duration: 9.0,
        intensity: 0.14
    )
    
    static let dashboard = AnimatedGradientBackground(
        colors: [.blue, .purple, .pink],
        duration: 10.0,
        intensity: 0.2
    )
}

extension LiquidWaveBackground {
    static let ocean = LiquidWaveBackground(
        colors: [.blue, .cyan, .teal],
        waveHeight: 80,
        waveSpeed: 3.0
    )
    
    static let sunset = LiquidWaveBackground(
        colors: [.orange, .pink, .purple],
        waveHeight: 120,
        waveSpeed: 2.5
    )
}

extension AuroraBackground {
    static let northern = AuroraBackground(
        colors: [.green, .blue, .purple],
        intensity: 0.25
    )
    
    static let southern = AuroraBackground(
        colors: [.pink, .purple, .blue],
        intensity: 0.3
    )
}

// MARK: - Helper Extensions
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    VStack(spacing: 0) {
        // Animated Gradient
        AnimatedGradientBackground.dashboard
            .frame(height: 200)
            .overlay(
                Text("Animated Gradient")
                    .font(.headline)
                    .foregroundStyle(.white)
            )
        
        // Liquid Wave
        LiquidWaveBackground.ocean
            .frame(height: 200)
            .overlay(
                Text("Liquid Wave")
                    .font(.headline)
                    .foregroundStyle(.white)
            )
        
        // Aurora
        AuroraBackground.northern
            .frame(height: 200)
            .overlay(
                Text("Aurora Background")
                    .font(.headline)
                    .foregroundStyle(.white)
            )
    }
}