//
//  View+Extensions.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

// MARK: - Glass Effects
extension View {
    func glassBackground(
        cornerRadius: CGFloat = 16,
        strokeColor: Color = .white.opacity(0.2),
        strokeWidth: CGFloat = 1
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .stroke(strokeColor, lineWidth: strokeWidth)
        )
    }
    
    func glassShadow(
        color: Color = .black.opacity(0.1),
        radius: CGFloat = 10,
        x: CGFloat = 0,
        y: CGFloat = 4
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
    
    func glassCard(
        cornerRadius: CGFloat = 16,
        strokeColor: Color = .white.opacity(0.2),
        strokeWidth: CGFloat = 1,
        shadowColor: Color = .black.opacity(0.1),
        shadowRadius: CGFloat = 10,
        shadowOffset: CGSize = CGSize(width: 0, height: 4)
    ) -> some View {
        self
            .glassBackground(
                cornerRadius: cornerRadius,
                strokeColor: strokeColor,
                strokeWidth: strokeWidth
            )
            .glassShadow(
                color: shadowColor,
                radius: shadowRadius,
                x: shadowOffset.width,
                y: shadowOffset.height
            )
    }
}

// MARK: - Conditional Modifiers
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func ifLet<Content: View, T>(_ optional: T?, transform: (Self, T) -> Content) -> some View {
        if let value = optional {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Keyboard Handling
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func onTapGestureToHideKeyboard() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
}

// MARK: - Device Detection
extension View {
    func iPhone(_ modifier: some ViewModifier) -> some View {
        self.modifier(DeviceModifier(device: .phone, modifier: modifier))
    }
    
    func iPad(_ modifier: some ViewModifier) -> some View {
        self.modifier(DeviceModifier(device: .pad, modifier: modifier))
    }
}

struct DeviceModifier<M: ViewModifier>: ViewModifier {
    let device: UIUserInterfaceIdiom
    let modifier: M
    
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == device {
            content.modifier(modifier)
        } else {
            content
        }
    }
}

// MARK: - Loading State
extension View {
    func loadingOverlay(isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                        
                        ProgressView()
                            .scaleEffect(1.2)
                    }
                    .transition(.opacity)
                }
            }
        )
    }
    
    func loadingButton(isLoading: Bool, loadingText: String = "Laddar...") -> some View {
        self.disabled(isLoading)
            .overlay(
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text(loadingText)
                            .foregroundStyle(.white)
                    }
                }
            )
            .opacity(isLoading ? 0.7 : 1.0)
    }
}

// MARK: - Animation Extensions
extension View {
    func animate(
        using animation: Animation = .easeInOut(duration: 0.3),
        _ action: @escaping () -> Void
    ) -> some View {
        self.onTapGesture {
            withAnimation(animation) {
                action()
            }
        }
    }
    
    func bounceOnTap(scale: CGFloat = 0.95) -> some View {
        self.scaleEffect(1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    // The bounce effect is handled by the button styles
                }
            }
    }
    
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .clipped()
                .opacity(isActive ? 1 : 0)
            )
            .onAppear {
                if isActive {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 300
                    }
                }
            }
    }
}

// MARK: - Spacing and Sizing
extension View {
    func frame(square size: CGFloat) -> some View {
        self.frame(width: size, height: size)
    }
    
    func maxWidth(_ width: CGFloat? = .infinity, alignment: Alignment = .center) -> some View {
        self.frame(maxWidth: width, alignment: alignment)
    }
    
    func maxHeight(_ height: CGFloat? = .infinity, alignment: Alignment = .center) -> some View {
        self.frame(maxHeight: height, alignment: alignment)
    }
}

// MARK: - Text Styling
extension View {
    func textStyle(_ style: TextStyle) -> some View {
        self.modifier(style)
    }
}

struct TextStyle: ViewModifier {
    let font: Font
    let color: Color
    let weight: Font.Weight?
    
    init(font: Font, color: Color = .primary, weight: Font.Weight? = nil) {
        self.font = font
        self.color = color
        self.weight = weight
    }
    
    func body(content: Content) -> some View {
        content
            .font(weight != nil ? font.weight(weight!) : font)
            .foregroundStyle(color)
    }
    
    // Predefined styles
    static let title = TextStyle(font: .largeTitle, weight: .bold)
    static let headline = TextStyle(font: .headline, weight: .semibold)
    static let body = TextStyle(font: .body)
    static let caption = TextStyle(font: .caption, color: .secondary)
    static let error = TextStyle(font: .caption, color: .red, weight: .medium)
    static let success = TextStyle(font: .caption, color: .green, weight: .medium)
}

// MARK: - Error Handling
extension View {
    func errorAlert(
        isPresented: Binding<Bool>,
        error: LocalizedError?,
        dismissAction: (() -> Void)? = nil
    ) -> some View {
        self.alert(
            "Fel",
            isPresented: isPresented,
            presenting: error
        ) { error in
            Button("OK") {
                dismissAction?()
            }
        } message: { error in
            Text(error.errorDescription ?? "Ett okänt fel uppstod")
        }
    }
    
    func successToast(
        isPresented: Binding<Bool>,
        message: String
    ) -> some View {
        self.overlay(
            VStack {
                Spacer()
                
                if isPresented.wrappedValue {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        
                        Text(message)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .stroke(.green.opacity(0.3), lineWidth: 1)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isPresented.wrappedValue = false
                            }
                        }
                    }
                }
            }
            .padding()
        )
    }
}

// MARK: - Share Sheet
extension View {
    func shareSheet(
        isPresented: Binding<Bool>,
        items: [Any],
        completion: UIActivityViewController.CompletionWithItemsHandler? = nil
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            ShareSheet(items: items, completion: completion)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let completion: UIActivityViewController.CompletionWithItemsHandler?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = completion
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Haptic Feedback
extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    func selectionFeedback() -> some View {
        self.onTapGesture {
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        }
    }
    
    func notificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) -> some View {
        self.onTapGesture {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(type)
        }
    }
}

// MARK: - Accessibility
extension View {
    func accessibilityLabel(_ label: LocalizedStringKey) -> some View {
        self.accessibilityLabel(Text(label))
    }
    
    func accessibilityHint(_ hint: LocalizedStringKey) -> some View {
        self.accessibilityHint(Text(hint))
    }
    
    func accessibilityValue(_ value: LocalizedStringKey) -> some View {
        self.accessibilityValue(Text(value))
    }
}
