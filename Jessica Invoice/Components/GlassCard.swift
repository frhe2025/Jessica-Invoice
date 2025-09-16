//
//  GlassCard.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowOffset: CGSize
    let strokeWidth: CGFloat
    
    init(
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 10,
        shadowOffset: CGSize = CGSize(width: 0, height: 4),
        strokeWidth: CGFloat = 1,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.strokeWidth = strokeWidth
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .stroke(.white.opacity(0.2), lineWidth: strokeWidth)
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: shadowRadius,
                        x: shadowOffset.width,
                        y: shadowOffset.height
                    )
            )
    }
}

// MARK: - Glass Card Variants
extension GlassCard {
    static func compact<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        GlassCard(
            cornerRadius: 12,
            shadowRadius: 6,
            shadowOffset: CGSize(width: 0, height: 2),
            content: content
        )
    }
    
    static func prominent<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        GlassCard(
            cornerRadius: 20,
            shadowRadius: 15,
            shadowOffset: CGSize(width: 0, height: 8),
            strokeWidth: 1.5,
            content: content
        )
    }
}

// MARK: - Glass Section
struct GlassSection<Header: View, Content: View>: View {
    let header: Header
    let content: Content
    
    init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            GlassCard {
                content
                    .padding(20)
            }
        }
    }
}

// MARK: - Glass List Item
struct GlassListItem<Content: View>: View {
    let content: Content
    let isFirst: Bool
    let isLast: Bool
    
    init(
        isFirst: Bool = false,
        isLast: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.isFirst = isFirst
        self.isLast = isLast
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .cornerRadius(isFirst ? 16 : 0, corners: [.topLeft, .topRight])
                    .cornerRadius(isLast ? 16 : 0, corners: [.bottomLeft, .bottomRight])
            )
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Standard glass card
            GlassCard {
                VStack {
                    Text("Standard Glass Card")
                        .font(.headline)
                    Text("This is a standard glass card with default styling")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            
            // Compact glass card
            GlassCard.compact {
                Text("Compact Glass Card")
                    .padding(12)
            }
            
            // Prominent glass card
            GlassCard.prominent {
                VStack {
                    Image(systemName: "star.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.yellow)
                    Text("Prominent Glass Card")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(24)
            }
        }
        .padding()
    }
    .background(.blue.opacity(0.1))
}
