//
//  InvoiceView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

struct InvoiceView: View {
    @State private var showingNewInvoice = false
    @State private var recentInvoices = [
        Invoice(number: "2025-001", client: "Acme AB", amount: 15000, date: Date()),
        Invoice(number: "2025-002", client: "TechCorp", amount: 8500, date: Date().addingTimeInterval(-86400)),
        Invoice(number: "2025-003", client: "Design Studio", amount: 12000, date: Date().addingTimeInterval(-172800))
    ]
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 48, weight: .light))
                                .foregroundStyle(.blue.gradient)
                            
                            Text("Skapa Faktura")
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                            
                            Text("Skapa professionella fakturor snabbt och enkelt")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 32)
                        
                        // Action Cards
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: geometry.size.width > 700 ? 2 : 1), spacing: 16) {
                            // New Invoice Card
                            Button {
                                showingNewInvoice = true
                            } label: {
                                GlassCard {
                                    VStack(spacing: 12) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.blue)
                                        
                                        Text("Ny Faktura")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        Text("Skapa en ny faktura från början")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(24)
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Template Card
                            Button {
                                // Template action
                            } label: {
                                GlassCard {
                                    VStack(spacing: 12) {
                                        Image(systemName: "doc.badge.plus")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.green)
                                        
                                        Text("Använd Mall")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        Text("Skapa från befintlig mall")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(24)
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        
                        // Recent Invoices
                        if !recentInvoices.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Senaste Fakturor")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Button("Visa alla") {
                                        // Navigate to history
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                }
                                
                                GlassCard {
                                    VStack(spacing: 0) {
                                        ForEach(Array(recentInvoices.enumerated()), id: \.element.id) { index, invoice in
                                            InvoiceRow(invoice: invoice)
                                            
                                            if index < recentInvoices.count - 1 {
                                                Divider()
                                                    .padding(.leading, 16)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.03), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingNewInvoice) {
            NewInvoiceView()
        }
    }
}

// MARK: - Glass Card Component
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Invoice Row
struct InvoiceRow: View {
    let invoice: Invoice
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(.blue.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(invoice.number.suffix(3))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(invoice.client)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(invoice.number)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(invoice.amount)) kr")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(invoice.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Invoice Model
struct Invoice: Identifiable {
    let id = UUID()
    let number: String
    let client: String
    let amount: Double
    let date: Date
}

// MARK: - New Invoice View (Placeholder)
struct NewInvoiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Ny Faktura")
                    .font(.largeTitle)
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Spara") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    InvoiceView()
}
