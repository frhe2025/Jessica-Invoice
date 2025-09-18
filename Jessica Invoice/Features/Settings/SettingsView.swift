//
//  SettingsView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

struct SettingsView: View {
    @State private var companyName = "Jessica AB"
    @State private var organizationNumber = "559999-9999"
    @State private var address = "Storgatan 1"
    @State private var postalCode = "123 45"
    @State private var city = "Stockholm"
    @State private var email = "jessica@example.com"
    @State private var phone = "08-123 45 67"
    @State private var vatNumber = "SE559999999901"
    
    @State private var enableNotifications = true
    @State private var defaultPaymentTerms = 30
    @State private var currency = "SEK"
    @State private var invoiceTemplate = "Standard"
    
    let paymentTermsOptions = [14, 30, 60, 90]
    let currencyOptions = ["SEK", "EUR", "USD"]
    let templateOptions = ["Standard", "Minimal", "Professional"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.purple.gradient)
                        
                        Text("Inställningar")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        
                        Text("Konfigurera din app och företagsinformation")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 32)
                    
                    // Company Information
                    SettingsSection(title: "Företagsinformation", icon: "building.2") {
                        VStack(spacing: 16) {
                            SettingsField(title: "Företagsnamn", text: $companyName, icon: "building")
                            SettingsField(title: "Organisationsnummer", text: $organizationNumber, icon: "number")
                            SettingsField(title: "Adress", text: $address, icon: "location")
                            
                            HStack(spacing: 12) {
                                SettingsField(title: "Postnummer", text: $postalCode, icon: "envelope")
                                SettingsField(title: "Stad", text: $city, icon: "location.circle")
                            }
                            
                            SettingsField(title: "E-post", text: $email, icon: "envelope.fill")
                            SettingsField(title: "Telefon", text: $phone, icon: "phone.fill")
                            SettingsField(title: "VAT-nummer", text: $vatNumber, icon: "doc.text")
                        }
                    }
                    
                    // Invoice Settings
                    SettingsSection(title: "Fakturainställningar", icon: "doc.text.fill") {
                        VStack(spacing: 16) {
                            SettingsPicker(
                                title: "Betalningsvillkor",
                                selection: $defaultPaymentTerms,
                                options: paymentTermsOptions,
                                displayValue: { "\($0) dagar" },
                                icon: "calendar"
                            )
                            
                            SettingsPicker(
                                title: "Valuta",
                                selection: $currency,
                                options: currencyOptions,
                                displayValue: { $0 },
                                icon: "dollarsign.circle"
                            )
                            
                            SettingsPicker(
                                title: "Fakturamall",
                                selection: $invoiceTemplate,
                                options: templateOptions,
                                displayValue: { $0 },
                                icon: "doc.richtext"
                            )
                        }
                    }
                    
                    // App Settings
                    SettingsSection(title: "App-inställningar", icon: "app.badge") {
                        VStack(spacing: 16) {
                            SettingsToggle(
                                title: "Push-notiser",
                                subtitle: "Få notiser när fakturor betalas",
                                isOn: $enableNotifications,
                                icon: "bell.fill"
                            )
                            
                            SettingsButton(
                                title: "Exportera data",
                                subtitle: "Exportera all fakturadata",
                                icon: "square.and.arrow.up",
                                color: .blue
                            ) {
                                // Export data
                            }
                            
                            SettingsButton(
                                title: "Återställ app",
                                subtitle: "Återställ all data och inställningar",
                                icon: "arrow.clockwise",
                                color: .orange
                            ) {
                                // Reset app
                            }
                        }
                    }
                    
                    // Support
                    SettingsSection(title: "Support", icon: "questionmark.circle") {
                        VStack(spacing: 16) {
                            SettingsButton(
                                title: "Hjälp & FAQ",
                                subtitle: "Vanliga frågor och svar",
                                icon: "questionmark.circle",
                                color: .green
                            ) {
                                // Show help
                            }
                            
                            SettingsButton(
                                title: "Kontakta support",
                                subtitle: "Få hjälp med din app",
                                icon: "envelope",
                                color: .blue
                            ) {
                                // Contact support
                            }
                            
                            SettingsButton(
                                title: "Betygsätt appen",
                                subtitle: "Betygsätt oss i App Store",
                                icon: "star.fill",
                                color: .yellow
                            ) {
                                // Rate app
                            }
                        }
                    }
                    
                    // Version Info
                    GlassCard(style: .compact) {
                        VStack(spacing: 8) {
                            Text("Jessica Invoice")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("© 2025 Jessica AB")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(
                LinearGradient(
                    colors: [.purple.opacity(0.03), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.purple)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            GlassCard {
                content
                    .padding(20)
            }
        }
    }
}

// MARK: - Settings Field
struct SettingsField: View {
    let title: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Settings Picker
struct SettingsPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let displayValue: (T) -> String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(displayValue(option)) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(displayValue(selection))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Settings Toggle
struct SettingsToggle: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    let icon: String
    
    init(title: String, subtitle: String? = nil, isOn: Binding<Bool>, icon: String) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(.purple)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Settings Button
struct SettingsButton: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(title: String, subtitle: String? = nil, icon: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    SettingsView()
}
