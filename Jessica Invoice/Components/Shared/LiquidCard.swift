//
//  LiquidCardStyle.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-18.
//


import SwiftUI

public enum LiquidCardStyle {
    case primary
    case subtle
}

public struct LiquidCard<Content: View>: View {
    public let style: LiquidCardStyle
    public let content: Content
    
    public init(_ style: LiquidCardStyle = .subtle, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    public var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08))
            )
            .shadow(
                color: Color.black.opacity(style == .primary ? 0.2 : 0.1),
                radius: style == .primary ? 12 : 6,
                x: 0,
                y: 4
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
