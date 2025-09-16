//
//  LiquidNavigationBar.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//  iOS 26 Liquid Navigation Bar
//

import SwiftUI

// MARK: - Liquid Navigation Bar
struct LiquidNavigationBar: View {
    let title: String
    let subtitle: String?
    let leadingAction: NavigationAction?
    let trailingActions: [NavigationAction]
    let showsSeparator: Bool
    let isTransparent: Bool
    let tintColor: Color?
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isScrolled = false
    
    init(
        title: String,
        subtitle: String? = nil,
        leadingAction: NavigationAction? = nil,
        trailingActions: [NavigationAction] = [],
        showsSeparator: Bool = false,
        isTransparent: Bool = false,
        tintColor: Color? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingAction = leadingAction
        self.trailingActions = trailingActions
        self.showsSeparator = showsSeparator
        self.isTransparent = isTransparent
        self.tintColor = tintColor
    }
    
    var body: some View {
        VStack(spacing: 0) {
            liquidNavBar
            
            if showsSeparator {
                liquidSeparator
            }
        }
        .background(navBarBackground)
        .animation(.easeInOut(duration: 0.3), value: isScrolled)
    }
    
    @ViewBuilder
    private var liquidNavBar: some View {
        HStack(spacing: 16) {
            // Leading action
            if let leading = leadingAction {
                navigationActionView(leading)
            } else {
                Spacer()
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Title section
            titleSection
            
            Spacer()
            
            // Trailing actions
            HStack(spacing: 8) {
                ForEach(Array(trailingActions.enumerated()), id: \.offset) { _, action in
                    navigationActionView(action)
                }
                
                if trailingActions.isEmpty {
                    Spacer()
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .opacity(isScrolled ? 1.0 : 0.9)
        .scaleEffect(isScrolled ? 0.95 : 1.0)
    }
    
    @ViewBuilder
    private var liquidSeparator: some View {
        LinearGradient(
            colors: [
                .clear,
                .primary.opacity(0.1),
                .primary.opacity(0.05),
                .clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
        .opacity(isScrolled ? 1.0 : 0.3)
    }
    
    @ViewBuilder
    private var navBarBackground: some View {
        if isTransparent {
            Color.clear
        } else {
            LiquidGlassBackground(
                intensity: isScrolled ? 1.2 : 0.8,
                tintColor: tintColor,
                isAdaptive: true
            )
            .blur(radius: isScrolled ? 0 : 2)
            .animation(.easeInOut(duration: 0.4), value: isScrolled)
        }
    }
    
    @ViewBuilder
    private func navigationActionView(_ action: NavigationAction) -> some View {
        Button(action: action.action) {
            Group {
                if let systemImage = action.systemImage {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .fontWeight(.medium)
                } else if let customImage = action.customImage {
                    Image(customImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else if let text = action.text {
                    Text(text)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .foregroundStyle(action.color ?? tintColor ?? .blue)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(action.hasBackground ? 1.0 : 0.0)
            )
            .liquidRipple(trigger: false, color: action.color ?? tintColor ?? .blue)
            .scaleEffect(action.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: action.isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action.isDisabled)
        .opacity(action.isDisabled ? 0.5 : 1.0)
    }
}

// MARK: - Navigation Action
struct NavigationAction {
    let systemImage: String?
    let customImage: String?
    let text: String?
    let color: Color?
    let hasBackground: Bool
    let isDisabled: Bool
    let isPressed: Bool
    let action: () -> Void
    
    init(
        systemImage: String? = nil,
        customImage: String? = nil,
        text: String? = nil,
        color: Color? = nil,
        hasBackground: Bool = false,
        isDisabled: Bool = false,
        isPressed: Bool = false,
        action: @escaping () -> Void = {}
    ) {
        self.systemImage = systemImage
        self.customImage = customImage
        self.text = text
        self.color = color
        self.hasBackground = hasBackground
        self.isDisabled = isDisabled
        self.isPressed = isPressed
        self.action = action
    }
}

// MARK: - Convenience Extensions
extension NavigationAction {
    static func back(action: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            systemImage: "chevron.left",
            color: .blue,
            action: action
        )
    }
    
    static func close(action: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            systemImage: "xmark",
            color: .secondary,
            hasBackground: true,
            action: action
        )
    }
    
    static func done(action: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            text: "Klar",
            color: .blue,
            action: action
        )
    }
    
    static func save(isLoading: Bool = false, action: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            systemImage: isLoading ? "ellipsis" : "checkmark",
            color: .green,
            isDisabled: isLoading,
            action: action
        )
    }
    
    static func edit(action: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            systemImage: "pencil",
            color: .orange,
            action: action
        )
    }
    
    static func share(action: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            systemImage: "square.and.arrow.up",
            color: .blue,
            action: action
        )
    }
    
    static func more(action: @escaping () -> Void) -> NavigationAction {
        NavigationAction(
            systemImage: "ellipsis",
            color: .secondary,
            hasBackground: true,
            action: action
        )
    }
}

// MARK: - Liquid Tab Bar
struct LiquidTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    let tintColor: Color
    
    @State private var tabItemWidths: [CGFloat] = []
    @State private var totalWidth: CGFloat = 0
    
    init(selectedTab: Binding<Int>, tintColor: Color = .blue, tabs: [TabItem]) {
        self._selectedTab = selectedTab
        self.tintColor = tintColor
        self.tabs = tabs
        self._tabItemWidths = State(initialValue: Array(repeating: 0, count: tabs.count))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            liquidIndicator
            
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    tabItemView(tab, index: index)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedTab = index
                            }
                            
                            // Haptic feedback
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        tabItemWidths[index] = geometry.size.width
                                        totalWidth = tabItemWidths.reduce(0, +)
                                    }
                            }
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(
            LiquidGlassBackground(
                intensity: 1.0,
                tintColor: tintColor,
                isAdaptive: true
            )
            .blur(radius: 1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .liquidShadow(radius: 20, intensity: 0.2)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var liquidIndicator: some View {
        HStack {
            ForEach(0..<tabs.count, id: \.self) { index in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: selectedTab == index ?
                                [tintColor, tintColor.opacity(0.8)] :
                                [Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedTab)
            }
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
        )
    }
    
    @ViewBuilder
    private func tabItemView(_ tab: TabItem, index: Int) -> some View {
        VStack(spacing: 4) {
            ZStack {
                // Background pill for selected state
                if selectedTab == index {
                    Capsule()
                        .fill(tintColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .scaleEffect(1.2)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Image(systemName: selectedTab == index ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(selectedTab == index ? tintColor : .secondary)
                    .scaleEffect(selectedTab == index ? 1.1 : 1.0)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab)
            
            Text(tab.title)
                .font(.caption2)
                .fontWeight(selectedTab == index ? .semibold : .medium)
                .foregroundStyle(selectedTab == index ? tintColor : .secondary)
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

// MARK: - Tab Item
struct TabItem {
    let title: String
    let icon: String
    let selectedIcon: String
    let badge: String?
    
    init(title: String, icon: String, selectedIcon: String? = nil, badge: String? = nil) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon + ".fill"
        self.badge = badge
    }
}

// MARK: - Liquid Navigation Container
struct LiquidNavigationContainer<Content: View>: View {
    let navigationBar: LiquidNavigationBar?
    let tabBar: LiquidTabBar?
    let content: Content
    let showsNavBar: Bool
    let showsTabBar: Bool
    
    @State private var scrollOffset: CGFloat = 0
    
    init(
        navigationBar: LiquidNavigationBar? = nil,
        tabBar: LiquidTabBar? = nil,
        showsNavBar: Bool = true,
        showsTabBar: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.navigationBar = navigationBar
        self.tabBar = tabBar
        self.showsNavBar = showsNavBar
        self.showsTabBar = showsTabBar
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if showsNavBar, let navigationBar = navigationBar {
                navigationBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if showsTabBar, let tabBar = tabBar {
                tabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(edges: showsTabBar ? .bottom : [])
        .animation(.easeInOut(duration: 0.3), value: showsNavBar)
        .animation(.easeInOut(duration: 0.3), value: showsTabBar)
    }
}

#Preview {
    @State var selectedTab = 0
    
    return LiquidNavigationContainer(
        navigationBar: LiquidNavigationBar(
            title: "Jessica Invoice",
            subtitle: "Skapa fakturor",
            leadingAction: .back {},
            trailingActions: [.edit {}, .share {}],
            tintColor: .blue
        ),
        tabBar: LiquidTabBar(
            selectedTab: .constant(selectedTab),
            tintColor: .blue,
            tabs: [
                TabItem(title: "Faktura", icon: "doc.text"),
                TabItem(title: "Produkter", icon: "cart"),
                TabItem(title: "Historik", icon: "clock.arrow.circlepath"),
                TabItem(title: "Inställningar", icon: "gearshape")
            ]
        )
    ) {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<20) { index in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .frame(height: 60)
                        .overlay(
                            Text("Content Item \(index + 1)")
                                .font(.headline)
                        )
                }
            }
            .padding()
        }
    }
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.1), .purple.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
