import SwiftUI

// NOTE: Fallback stub implementations renamed to avoid conflicts with real implementations.
// These are simple no-op or basic fallbacks with slightly different names.

// MARK: - LiquidGlassBackgroundStub

public struct LiquidGlassBackgroundStub: View {
    private let colors: [Color]
    private let intensity: Double
    private let isAnimated: Bool

    public init(colors: [Color] = [.clear], intensity: Double = 0.08, isAnimated: Bool = false) {
        self.colors = colors
        self.intensity = intensity
        self.isAnimated = isAnimated
    }

    public var body: some View {
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(intensity)
        .ignoresSafeArea()
    }
}

// MARK: - LiquidCardStub

public struct LiquidCardStub<Content: View>: View {
    public enum Style {
        case primary
        case subtle
    }

    private let style: Style
    private let content: Content

    public init(style: Style = .primary, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }

    public var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground).opacity(style == .primary ? 0.9 : 0.6))
                    .shadow(color: Color.black.opacity(style == .primary ? 0.1 : 0), radius: 10, x: 0, y: 4)
            )
    }
}

// MARK: - LiquidGlassCardStub

public struct LiquidGlassCardStub<Content: View>: View {
    public enum Style {
        case minimal
        case adaptive
        case prominent
        case floating
        case interactive
        case subtle
        case primary
    }

    public enum Depth {
        case subtle
        case medium
        case deep
    }

    private let style: Style
    private let depth: Depth
    private let adaptiveColor: Bool
    private let content: Content

    public init(
        style: Style = .adaptive,
        depth: Depth = .medium,
        adaptiveColor: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.depth = depth
        self.adaptiveColor = adaptiveColor
        self.content = content()
    }

    public var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.15))
                    .background(.ultraThinMaterial)
                    .if(depth != .subtle) { view in
                        view.shadow(color: Color.black.opacity(depth == .deep ? 0.3 : 0.15), radius: depth == .deep ? 20 : 10, x: 0, y: 4)
                    }
            )
    }

    // Static factories
    public static func adaptive<C: View>(@ViewBuilder content: () -> C) -> LiquidGlassCardStub<C> {
        LiquidGlassCardStub<C>(style: .adaptive, depth: .medium, adaptiveColor: true, content: content)
    }

    public static func prominent<C: View>(@ViewBuilder content: () -> C) -> LiquidGlassCardStub<C> {
        LiquidGlassCardStub<C>(style: .prominent, depth: .deep, adaptiveColor: true, content: content)
    }
}

// MARK: - ContextualLiquidBackgroundStub

public struct ContextualLiquidBackgroundStub: View {
    public enum BackgroundContext {
        case invoice
        case products
        case history
        case settings
        case dashboard
    }

    private let context: BackgroundContext

    public init(_ context: BackgroundContext) {
        self.context = context
    }

    public var body: some View {
        let gradientColors: [Color] = {
            switch context {
            case .invoice:
                return [Color.orange.opacity(0.6), Color.orange.opacity(0.2)]
            case .products:
                return [Color.blue.opacity(0.6), Color.blue.opacity(0.2)]
            case .history:
                return [Color.green.opacity(0.6), Color.green.opacity(0.2)]
            case .settings:
                return [Color.purple.opacity(0.6), Color.purple.opacity(0.2)]
            case .dashboard:
                return [Color.pink.opacity(0.6), Color.pink.opacity(0.2)]
            }
        }()

        return LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - liquidButtonStyle Modifier

public struct LiquidButtonStyleModifier: ViewModifier {
    public enum Variant {
        case primary
        case secondary
        case ghost
    }

    public enum Size {
        case small
        case medium
        case large
    }

    private let variant: Variant
    private let size: Size

    public init(variant: Variant = .primary, size: Size = .medium) {
        self.variant = variant
        self.size = size
    }

    public func body(content: Content) -> some View {
        content
            .font(font)
            .padding(padding)
            .background(background)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var font: Font {
        switch size {
        case .small: return .caption
        case .medium: return .body
        case .large: return .title3
        }
    }

    private var padding: EdgeInsets {
        switch size {
        case .small:
            return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        case .medium:
            return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        case .large:
            return EdgeInsets(top: 14, leading: 22, bottom: 14, trailing: 22)
        }
    }

    private var background: some View {
        Group {
            switch variant {
            case .primary:
                Color.accentColor
            case .secondary:
                Color.accentColor.opacity(0.2)
            case .ghost:
                Color.clear
            }
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return Color.white
        case .secondary:
            return Color.accentColor
        case .ghost:
            return Color.accentColor
        }
    }
}

public extension View {
    func liquidButtonStyle(
        variant: LiquidButtonStyleModifier.Variant = .primary,
        size: LiquidButtonStyleModifier.Size = .medium
    ) -> some View {
        self.modifier(LiquidButtonStyleModifier(variant: variant, size: size))
    }
}

// MARK: - No-op / Simple fallback modifiers

public extension View {
    func errorAlert(isPresented: Binding<Bool>, message: String) -> some View {
        // No-op fallback: just return self
        self
    }

    func loadingButton(isLoading: Bool) -> some View {
        // No-op fallback: just return self
        self
    }

    func shareSheet(isPresented: Binding<Bool>, items: [Any]) -> some View {
        // No-op fallback: just return self
        self
    }

    func liquidGlassBackground(_ colors: [Color]) -> some View {
        self.background(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.08)
        )
    }
}

// MARK: - Helper extensions

// Removed private extension View with custom `if` modifier to avoid redeclaration issues.

