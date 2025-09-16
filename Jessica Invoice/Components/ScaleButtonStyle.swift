//
//  ScaleButtonStyle.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    let scaleEffect: CGFloat
    let duration: Double
    
    init(scaleEffect: CGFloat = 0.96, duration: Double = 0.1) {
        self.scaleEffect = scaleEffect
        self.duration = duration
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            .animation(.easeInOut(duration: duration), value: configuration.isPressed)
    }
}

// MARK: - Button Style Variants
extension ScaleButtonStyle {
    static let gentle = ScaleButtonStyle(scaleEffect: 0.98, duration: 0.15)
    static let strong = ScaleButtonStyle(scaleEffect: 0.92, duration: 0.08)
    static let subtle = ScaleButtonStyle(scaleEffect: 0.99, duration: 0.05)
}

// MARK: - Bounce Button Style
struct BounceButtonStyle: ButtonStyle {
    let scaleUp: CGFloat
    let scaleDown: CGFloat
    
    init(scaleUp: CGFloat = 1.05, scaleDown: CGFloat = 0.95) {
        self.scaleUp = scaleUp
        self.scaleDown = scaleDown
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleDown : 1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    // Bounce effect happens automatically through the press state
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Glass Button Style
struct GlassButtonStyle: ButtonStyle {
    let isProminent: Bool
    
    init(isProminent: Bool = false) {
        self.isProminent = isProminent
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: isProminent ? 16 : 12)
                    .fill(.ultraThinMaterial)
                    .stroke(.white.opacity(0.2), lineWidth: isProminent ? 1.5 : 1)
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: isProminent ? 8 : 4,
                        x: 0,
                        y: isProminent ? 4 : 2
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    let isLoading: Bool
    
    init(color: Color = .blue, isLoading: Bool = false) {
        self.color = color
        self.isLoading = isLoading
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
            
            configuration.label
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.gradient)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        )
        .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    let color: Color
    
    init(color: Color = .blue) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(configuration.isPressed ? 0.1 : 0.05))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            Group {
                Text("Button Styles")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                VStack(spacing: 16) {
                    Button("Scale Button (Default)") {}
                        .buttonStyle(ScaleButtonStyle())
                    
                    Button("Gentle Scale") {}
                        .buttonStyle(ScaleButtonStyle.gentle)
                    
                    Button("Strong Scale") {}
                        .buttonStyle(ScaleButtonStyle.strong)
                    
                    Button("Bounce Button") {}
                        .buttonStyle(BounceButtonStyle())
                }
                
                VStack(spacing: 16) {
                    Button("Glass Button") {}
                        .buttonStyle(GlassButtonStyle())
                    
                    Button("Prominent Glass") {}
                        .buttonStyle(GlassButtonStyle(isProminent: true))
                }
                
                VStack(spacing: 16) {
                    Button("Primary Button") {}
                        .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Loading Button") {}
                        .buttonStyle(PrimaryButtonStyle(isLoading: true))
                    
                    Button("Green Primary") {}
                        .buttonStyle(PrimaryButtonStyle(color: .green))
                    
                    Button("Secondary Button") {}
                        .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Orange Secondary") {}
                        .buttonStyle(SecondaryButtonStyle(color: .orange))
                }
            }
        }
        .padding()
    }
    .background(.gray.opacity(0.1))
}
