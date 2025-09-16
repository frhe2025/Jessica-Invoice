//
//  Jessica_InvoiceApp.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

@main
struct Jessica_InvoiceApp: App {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var invoiceViewModel = InvoiceViewModel()
    @StateObject private var productViewModel = ProductViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(invoiceViewModel)
                .environmentObject(productViewModel)
                .environmentObject(settingsViewModel)
                .onAppear {
                    configureApp()
                }
        }
    }
    
    private func configureApp() {
        // Load initial data
        dataManager.loadData()
        
        // Configure notifications
        NotificationManager.shared.requestPermissions()
    }
}
