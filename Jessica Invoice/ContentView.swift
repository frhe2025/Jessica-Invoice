//
//  ContentView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            InvoiceView()
                .tabItem {
                    Label("Faktura", systemImage: "doc.text.fill")
                }
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)

            ProductsView()
                .tabItem {
                    Label("Produkter", systemImage: "cart.fill")
                }

            HistoryView()
                .tabItem {
                    Label("Historik", systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Label("Inställningar", systemImage: "gearshape.fill")
                }
        }
        .tint(.blue)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
