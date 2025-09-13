//
//  ProductsView.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-13.
//


//
//  ProductsView.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-13.
//

import SwiftUI

struct ProductsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Hantera dina produkter här")
                    .font(.title2)
                    .padding()

                Spacer()
            }
            .navigationTitle("Produkter")
        }
    }
}

#Preview {
    ProductsView()
}
