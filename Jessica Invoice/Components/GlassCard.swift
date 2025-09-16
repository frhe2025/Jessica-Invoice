//
//  GlassCard.swift
//  Jessica Invoice
//  🔧 FIXED - Generic parameter issues resolved
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    let style: CardStyle
    
    @Environment(\.colorScheme) var colorScheme
    
    enum CardStyle {
        case compact
        case prominent
        case floating
        
        var padding: EdgeInsets {
            switch self {
            case .compact: return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            case .prominent: return EdgeInsets(top: 20, leading: 24, bottom: 20, trailing: 24)
            case .floating: return EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .compact: return 12
            case .prominent: return 16
            case .floating: return 20
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .compact: return 8
            case .prominent: return 16
            case .floating: return 24
            }
        }
    }
    
    init(style: CardStyle = .compact, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(style.padding)
            .background(cardBackground)
            .cornerRadius(style.cornerRadius)
            .shadow(
                color: shadowColor,
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowRadius / 3
            )
    }
    
    // MARK: - Static Factory Methods (FIXED - Proper generic syntax)
    static func compact<T: View>(@ViewBuilder content: () -> T) -> some View {
        GlassCard<T>(style: .compact, content: content)
    }
    
    static func prominent<T: View>(@ViewBuilder content: () -> T) -> some View {
        GlassCard<T>(style: .prominent, content: content)
    }
    
    static func floating<T: View>(@ViewBuilder content: () -> T) -> some View {
        GlassCard<T>(style: .floating, content: content)
    }
    
    // MARK: - Computed Properties
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: style.cornerRadius)
            .fill(glassMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(borderGradient, lineWidth: 1)
            )
    }
    
    private var glassMaterial: Material {
        switch style {
        case .compact:
            return colorScheme == .dark ? .ultraThinMaterial : .thinMaterial
        case .prominent:
            return colorScheme == .dark ? .thinMaterial : .regularMaterial
        case .floating:
            return colorScheme == .dark ? .regularMaterial : .thickMaterial
        }
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
    
    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.1)
    }
}

// MARK: - Convenience Initializers
extension View {
    func glassCard(style: GlassCard<Self>.CardStyle = .compact) -> some View {
        GlassCard(style: style) {
            self
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        GlassCard.compact {
            VStack {
                Text("Compact Card")
                    .font(.headline)
                Text("Simple and clean design")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        
        GlassCard.prominent {
            VStack(spacing: 12) {
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "doc.text")
                            .foregroundStyle(.blue)
                    )
                
                Text("Prominent Card")
                    .font(.title3.weight(.semibold))
                Text("More prominent with larger padding")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        
        GlassCard.floating {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Floating Card")
                        .font(.headline)
                    Spacer()
                }
                
                Text("Enhanced shadow and corner radius")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Button("Action") {}
                        .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Button("Cancel") {}
                        .buttonStyle(.bordered)
                }
            }
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
