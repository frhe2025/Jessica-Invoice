//
//  AnimatedGradientBackground.swift
//  Jessica Invoice
//  🔧 FIXED - Added missing .dashboard static member
//

import SwiftUI

struct AnimatedGradientBackground: View {
    let colors: [Color]
    let animation: Animation
    let blendMode: BlendMode
    let intensity: Double
    
    @State private var gradientRotation: Double = 0
    @State private var colorShift: Double = 0
    
    init(
        colors: [Color] = [.blue, .purple, .pink, .orange],
        animation: Animation = .easeInOut(duration: 8).repeatForever(autoreverses: true),
        blendMode: BlendMode = .screen,
        intensity: Double = 0.8
    ) {
        self.colors = colors
        self.animation = animation
        self.blendMode = blendMode
        self.intensity = intensity
    }
    
    var body: some View {
        ZStack {
            // Base gradient layer
            baseGradient
            
            // Animated overlay layers
            ForEach(0..<3, id: \.self) { index in
                animatedLayer(index: index)
            }
        }
        .clipped()
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Base Gradient
    private var baseGradient: some View {
        LinearGradient(
            colors: colors.map { $0.opacity(intensity * 0.6) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Animated Layers
    private func animatedLayer(index: Int) -> some View {
        let delay = Double(index) * 0.3
        let rotationOffset = Double(index) * 45
        
        return RadialGradient(
            colors: [
                colors[index % colors.count].opacity(intensity * 0.4),
                colors[(index + 1) % colors.count].opacity(intensity * 0.2),
                .clear
            ],
            center: UnitPoint(
                x: 0.5 + sin(gradientRotation + delay) * 0.3,
                y: 0.5 + cos(gradientRotation + delay) * 0.3
            ),
            startRadius: 50,
            endRadius: 300
        )
        .rotationEffect(.degrees(gradientRotation * 0.5 + rotationOffset))
        .blendMode(blendMode)
        .opacity(0.8)
    }
    
    // MARK: - Animation Control
    private func startAnimations() {
        withAnimation(animation) {
            gradientRotation = 360
            colorShift = 1.0
        }
    }
}

// MARK: - Static Presets (FIXED - Added missing .dashboard)
extension AnimatedGradientBackground {
    // MARK: - Dashboard preset (FIXED - Previously missing)
    static var dashboard: AnimatedGradientBackground {
        AnimatedGradientBackground(
            colors: [.blue, .purple, .indigo, .cyan, .teal],
            animation: .easeInOut(duration: 12).repeatForever(autoreverses: true),
            blendMode: .softLight,
            intensity: 0.7
        )
    }
    
    // MARK: - Invoice preset
    static var invoice: AnimatedGradientBackground {
        AnimatedGradientBackground(
            colors: [.blue, .cyan, .indigo],
            animation: .easeInOut(duration: 10).repeatForever(autoreverses: true),
            blendMode: .multiply,
            intensity: 0.6
        )
    }
    
    // MARK: - Products preset
    static var products: AnimatedGradientBackground {
        AnimatedGradientBackground(
            colors: [.green, .mint, .teal],
            animation: .easeInOut(duration: 9).repeatForever(autoreverses: true),
            blendMode: .overlay,
            intensity: 0.65
        )
    }
    
    // MARK: - History preset
    static var history: AnimatedGradientBackground {
        AnimatedGradientBackground(
            colors: [.orange, .yellow, .red],
            animation: .easeInOut(duration: 11).repeatForever(autoreverses: true),
            blendMode: .softLight,
            intensity: 0.55
        )
    }
    
    // MARK: - Settings preset
    static var settings: AnimatedGradientBackground {
        AnimatedGradientBackground(
            colors: [.purple, .pink, .indigo],
            animation: .easeInOut(duration: 13).repeatForever(autoreverses: true),
            blendMode: .screen,
            intensity: 0.6
        )
    }
    
    // MARK: - Aurora preset
    static var aurora: AnimatedGradientBackground {
        AnimatedGradientBackground(
            colors: [.green, .blue, .purple, .pink],
            animation: .easeInOut(duration: 15).repeatForever(autoreverses: true),
            blendMode: .screen,
            intensity: 0.8
        )
    }
    
    // MARK: - Ocean preset
    static var ocean: AnimatedGradientBackground {
        AnimatedGradientBackground(
            colors: [.blue, .cyan, .teal, .mint],
            animation: .easeInOut(duration: 20).repeatForever(autoreverses: true),
            blendMode: .multiply,
            intensity: 0.75
        )
    }
    
    // MARK: - Sunset preset
    static var sunset: AnimatedGradientBackground {
        AnimatedGradientBackground(
            colors: [.orange, .pink, .purple, .indigo],
            animation: .easeInOut(duration: 18).repeatForever(autoreverses: true),
            blendMode: .overlay,
            intensity: 0.7
        )
    }
}

// MARK: - Liquid Wave Background Component
struct LiquidWaveBackground: View {
    let colors: [Color]
    let waveSpeed: Double
    let waveAmplitude: Double
    
    @State private var phase: Double = 0
    
    init(
        colors: [Color] = [.blue, .cyan],
        waveSpeed: Double = 0.02,
        waveAmplitude: Double = 0.3
    ) {
        self.colors = colors
        self.waveSpeed = waveSpeed
        self.waveAmplitude = waveAmplitude
    }
    
    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                let path = createWavePath(size: size)
                
                context.fill(
                    path,
                    with: .linearGradient(
                        Gradient(colors: colors),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                phase = Double.pi * 2
            }
        }
    }
    
    private func createWavePath(size: CGSize) -> Path {
        Path { path in
            let width = size.width
            let height = size.height
            let midHeight = height / 2
            
            path.move(to: CGPoint(x: 0, y: midHeight))
            
            for x in stride(from: 0, through: width, by: 1) {
                let relativeX = x / width // CGFloat
                let sine = sin(Double(relativeX) * Double.pi * 4 + phase) // Double
                let y = midHeight + CGFloat(sine) * CGFloat(waveAmplitude) * height // CGFloat
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
    }
}

// MARK: - Wave Presets
extension LiquidWaveBackground {
    static var ocean: LiquidWaveBackground {
        LiquidWaveBackground(
            colors: [.blue.opacity(0.3), .cyan.opacity(0.5), .teal.opacity(0.3)],
            waveSpeed: 0.015,
            waveAmplitude: 0.2
        )
    }
    
    static var gentle: LiquidWaveBackground {
        LiquidWaveBackground(
            colors: [.mint.opacity(0.2), .green.opacity(0.3)],
            waveSpeed: 0.01,
            waveAmplitude: 0.1
        )
    }
}

// MARK: - Aurora Background
struct AuroraBackground: View {
    let colors: [Color]
    let intensity: Double
    
    @State private var animationPhase: Double = 0
    
    init(colors: [Color] = [.green, .blue, .purple], intensity: Double = 0.6) {
        self.colors = colors
        self.intensity = intensity
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<colors.count, id: \.self) { index in
                auroraStreak(color: colors[index], delay: Double(index) * 0.5)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animationPhase = 1.0
            }
        }
    }
    
    private func auroraStreak(color: Color, delay: Double) -> some View {
        RoundedRectangle(cornerRadius: 50)
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(intensity),
                        color.opacity(intensity * 0.3),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 200, height: 800)
            .rotationEffect(.degrees(25 + sin(animationPhase + delay) * 15))
            .offset(
                x: sin(animationPhase + delay) * 100,
                y: cos(animationPhase + delay * 1.3) * 50
            )
            .blendMode(.screen)
    }
}

// MARK: - Aurora Presets
extension AuroraBackground {
    static var northern: AuroraBackground {
        AuroraBackground(
            colors: [.green, .mint, .cyan, .blue],
            intensity: 0.7
        )
    }
    
    static var cosmic: AuroraBackground {
        AuroraBackground(
            colors: [.purple, .pink, .indigo, .blue],
            intensity: 0.8
        )
    }
}

// MARK: - Preview
#Preview {
    VStack {
        AnimatedGradientBackground.dashboard
            .frame(height: 200)
            .overlay(
                Text("Dashboard Background")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
            )
        
        AnimatedGradientBackground.invoice
            .frame(height: 200)
            .overlay(
                Text("Invoice Background")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
            )
    }
}

