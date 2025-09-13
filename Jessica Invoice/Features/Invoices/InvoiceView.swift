//
//  InvoiceView.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-13.
//


//
//  InvoiceView.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-13.
//

import SwiftUI

struct InvoiceView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Här skapar du en ny faktura")
                    .font(.title2)
                    .padding()

                Spacer()
            }
            .navigationTitle("Faktura")
        }
    }
}

#Preview {
    InvoiceView()
}