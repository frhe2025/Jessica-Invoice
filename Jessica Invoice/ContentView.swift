//
//  ContentView.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-13.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            InvoiceView()
                .tabItem {
                    Label("Faktura", systemImage: "doc.plaintext")
                }

            ProductsView()
                .tabItem {
                    Label("Produkter", systemImage: "cart")
                }

            HistoryView()
                .tabItem {
                    Label("Historik", systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Label("Inställningar", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
}
