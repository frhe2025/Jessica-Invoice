//
//  Jessica_InvoiceApp.swift
//  Jessica Invoice
//  🔧 FIXED - Removed duplicate ContentView declaration
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
                    // Use the ContentView from ContentView.swift - removed duplicate
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
        if companyManager.activeCompany != nil {
            invoiceViewModel.loadInvoices()
            productViewModel.loadProducts()
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

// MARK: - Loading View
struct LiquidLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground.dashboard
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Liquid loading animation
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 20, height: 20)
                            .offset(y: isAnimating ? -20 : 20)
                            .animation(
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                            .offset(x: CGFloat(index - 1) * 30)
                    }
                }
                .frame(height: 60)
                
                VStack(spacing: 8) {
                    Text("Jessica Invoice")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Text("Laddar...")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    LiquidLoadingView()
}
