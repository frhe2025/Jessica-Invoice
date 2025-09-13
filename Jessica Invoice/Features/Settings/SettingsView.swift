//
//  SettingsView.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-13.
//


//
//  SettingsView.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-13.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Företagsuppgifter")) {
                    Text("Här kommer inställningar för företag och fakturamallar")
                }
            }
            .navigationTitle("Inställningar")
        }
    }
}

#Preview {
    SettingsView()
}