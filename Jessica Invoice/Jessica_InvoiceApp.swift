//
//  Jessica_InvoiceApp.swift
//  📁 ERSÄTT BEFINTLIG FIL I ROOT LEVEL
//  Enhanced iOS 26 App with Multi-Company Support
//

import SwiftUI

@main
struct Jessica_InvoiceApp: App {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var companyManager = CompanyManager()
    @StateObject private var invoiceViewModel = InvoiceViewModel()
    @StateObject private var productViewModel = ProductViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if companyManager.isLoading {
                    LiquidLoadingView()
                } else {
                    ContentView()
                }
            }
            .environmentObject(dataManager)
            .environmentObject(companyManager)
            .environmentObject(invoiceViewModel)
            .environmentObject(productViewModel)
            .environmentObject(settingsViewModel)
            .environmentObject(notificationManager)
            .task {
                await configureApp()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task {
                    await handleAppBecameActive()
                }
            }
        }
    }
    
    // MARK: - App Configuration
    private func configureApp() async {
        print("🚀 Configuring Jessica Invoice App...")
        
        // Setup data migration
        do {
            try await dataManager.migrateDataIfNeeded()
        } catch {
            print("❌ Migration error: \(error)")
        }
        
        // Load initial data
        dataManager.loadData()
        
        // Setup notifications
        await configureNotifications()
        
        // Setup app monitoring
        setupAppMonitoring()
        
        print("✅ App configuration completed")
    }
    
    private func configureNotifications() async {
        await notificationManager.requestPermissions()
        
        // Schedule reminders for pending invoices if authorized
        if notificationManager.isEnabled {
            await notificationManager.scheduleRemindersForAllPendingInvoices()
            await notificationManager.updateBadgeCount()
        }
    }
    
    private func setupAppMonitoring() {
        // Monitor memory usage
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("⚠️ Memory warning received")
            // Handle memory pressure
        }
        
        // Monitor background state
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await handleAppDidEnterBackground()
            }
        }
    }
    
    private func handleAppBecameActive() async {
        // Update badge count
        await notificationManager.updateBadgeCount()
        
        // Refresh data if needed
        if let selectedCompany = companyManager.selectedCompany {
            await invoiceViewModel.loadInvoices(for: selectedCompany)
            await productViewModel.loadProducts(for: selectedCompany)
        }
    }
    
    private func handleAppDidEnterBackground() async {
        // Create backup when app goes to background
        do {
            _ = try await dataManager.createFullBackup()
        } catch {
            print("❌ Background backup failed: \(error)")
        }
    }
}

//
//  ContentView.swift
//  📁 ERSÄTT BEFINTLIG FIL I ROOT LEVEL
//  Enhanced iOS 26 Content View with Liquid Glass
//

struct ContentView: View {
    @EnvironmentObject var companyManager: CompanyManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var selectedTab: TabSelection = .invoice
    
    enum TabSelection: String, CaseIterable {
        case invoice = "invoice"
        case products = "products"
        case history = "history"
        case settings = "settings"
        
        var displayName: String {
            switch self {
            case .invoice: return "Faktura"
            case .products: return "Produkter"
            case .history: return "Historik"
            case .settings: return "Inställningar"
            }
        }
        
        var icon: String {
            switch self {
            case .invoice: return "doc.text.fill"
            case .products: return "cart.fill"
            case .history: return "clock.arrow.circlepath"
            case .settings: return "gearshape.fill"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .invoice: return "doc.text.fill"
            case .products: return "cart.fill"
            case .history: return "clock.arrow.circlepath.fill"
            case .settings: return "gearshape.2.fill"
            }
        }
        
        var backgroundContext: ContextualLiquidBackground.BackgroundContext {
            switch self {
            case .invoice: return .invoice
            case .products: return .products
            case .history: return .history
            case .settings: return .settings
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Main Content
            TabView(selection: $selectedTab) {
                InvoiceView()
                    .tag(TabSelection.invoice)
                
                ProductsView()
                    .tag(TabSelection.products)
                
                HistoryView()
                    .tag(TabSelection.history)
                
                SettingsView()
                    .tag(TabSelection.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar and Company Selector
            VStack {
                // Company Selector at top
                if !companyManager.companies.isEmpty {
                    companySelectorSection
                }
                
                Spacer()
                
                // Custom Tab Bar at bottom
                liquidTabBar
            }
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.light)
        .onAppear {
            setupAppearance()
        }
    }
    
    // MARK: - Company Selector Section
    private var companySelectorSection: some View {
        VStack(spacing: 0) {
            CompanySelectorView()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            
            Rectangle()
                .fill(.quaternary.opacity(0.5))
                .frame(height: 0.5)
        }
    }
    
    // MARK: - Liquid Tab Bar
    private var liquidTabBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.quaternary.opacity(0.5))
                .frame(height: 0.5)
            
            HStack(spacing: 0) {
                ForEach(TabSelection.allCases, id: \.self) { tab in
                    liquidTabButton(for: tab)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }
    
    private func liquidTabButton(for tab: TabSelection) -> some View {
        Button {
            selectTab(tab)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(selectedTab == tab ? .blue : .secondary)
                    .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                
                Text(tab.displayName)
                    .font(.caption)
                    .fontWeight(selectedTab == tab ? .semibold : .medium)
                    .foregroundStyle(selectedTab == tab ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)
    }
    
    // MARK: - Helper Functions
    private func selectTab(_ tab: TabSelection) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        selectedTab = tab
    }
    
    private func setupAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance (hidden since we use custom)
        UITabBar.appearance().isHidden = true
    }
}

//
//  LiquidLoadingView.swift
//  📁 PLACERA I: Components/LiquidGlass/
//  iOS 26 Loading Screen
//

struct LiquidLoadingView: View {
    @State private var animationPhase: CGFloat = 0
    @State private var pulsePhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Animated liquid background
            LiquidGlassBackground(
                colors: [.blue, .cyan, .indigo],
                intensity: 0.15,
                isAnimated: true
            )
            
            VStack(spacing: 32) {
                // Animated logo
                ZStack {
                    // Pulsing background circles
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .cyan.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: CGFloat(80 + index * 20), height: CGFloat(80 + index * 20))
                            .scaleEffect(1.0 + sin(pulsePhase + Double(index) * 0.5) * 0.1)
                            .opacity(0.7 - Double(index) * 0.2)
                    }
                    
                    // Main icon
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(1.0 + sin(animationPhase) * 0.05)
                }
                
                // App name and loading text
                VStack(spacing: 12) {
                    Text("Jessica Invoice")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Laddar dina företag...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
        
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: true)) {
            pulsePhase = .pi
        }
    }
}

#Preview("Content View") {
    ContentView()
        .environmentObject(CompanyManager())
        .environmentObject(InvoiceViewModel())
        .environmentObject(ProductViewModel())
        .environmentObject(SettingsViewModel())
}

#Preview("Loading View") {
    LiquidLoadingView()
}
