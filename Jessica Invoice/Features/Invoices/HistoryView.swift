//
//  HistoryView.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-13.
//


//
//  HistoryView.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-13.
//

import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Tidigare fakturor visas här")
                    .font(.title2)
                    .padding()

                Spacer()
            }
            .navigationTitle("Historik")
        }
    }
}

#Preview {
    HistoryView()
}