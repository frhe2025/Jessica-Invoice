//
//  ClientFormView.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//


import SwiftUI

struct ClientFormView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var client: Client
    
    @State private var tempClient: Client
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    init(client: Binding<Client>) {
        self._client = client
        self._tempClient = State(initialValue: client.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Information
                    ClientBasicInfoSection(client: $tempClient)
                    
                    // Contact Information
                    ClientContactInfoSection(client: $tempClient)
                    
                    // Address Information
                    ClientAddressSection(client: $tempClient)
                    
                    // Business Information
                    ClientBusinessInfoSection(client: $tempClient)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(GradientBackground.invoice)
            .navigationTitle("Kundinformation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Spara") {
                        saveClient()
                    }
                    .fontWeight(.semibold)
                    .disabled(tempClient.name.isEmpty)
                    .loadingButton(isLoading: isLoading)
                }
            }
            .errorAlert(isPresented: $showingError, error: ClientError(message: errorMessage ?? ""))
        }
    }
    
    private func saveClient() {
        let validationErrors = validateClient()
        if !validationErrors.isEmpty {
            errorMessage = validationErrors.joined(separator: "\n")
            showingError = true
            return
        }
        
        isLoading = true
        
        // Simulate save delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            client = tempClient
            isLoading = false
            dismiss()
        }
    }
    
    private func validateClient() -> [String] {
        var errors: [String] = []
        
        if tempClient.name.isEmpty {
            errors.append("Företagsnamn är obligatoriskt")
        }
        
        if !tempClient.email.isEmpty && !isValidEmail(tempClient.email) {
            errors.append("E-postadress har fel format")
        }
        
        if !tempClient.organizationNumber.isEmpty && !isValidOrganizationNumber(tempClient.organizationNumber) {
            errors.append("Organisationsnummer har fel format")
        }
        
        return errors
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidOrganizationNumber(_ number: String) -> Bool {
        let pattern = "^\\d{6}-\\d{4}$|^\\d{10}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: number)
    }
}

// MARK: - Client Basic Info Section
struct ClientBasicInfoSection: View {
    @Binding var client: Client
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Grunduppgifter")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    FormField(
                        title: "Företagsnamn *",
                        text: $client.name,
                        placeholder: "Ange företagsnamn"
                    )
                    
                    FormField(
                        title: "Kontaktperson",
                        text: $client.contactPerson,
                        placeholder: "Ange kontaktperson"
                    )
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Client Contact Info Section
struct ClientContactInfoSection: View {
    @Binding var client: Client
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Kontaktuppgifter")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    FormField(
                        title: "E-postadress",
                        text: $client.email,
                        placeholder: "exempel@företag.se"
                    )
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    
                    FormField(
                        title: "Telefonnummer",
                        text: $client.phone,
                        placeholder: "08-123 45 67"
                    )
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Client Address Section
struct ClientAddressSection: View {
    @Binding var client: Client
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Adressuppgifter")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    FormField(
                        title: "Gatuadress",
                        text: $client.address.street,
                        placeholder: "Storgatan 1"
                    )
                    .textContentType(.streetAddressLine1)
                    
                    HStack(spacing: 12) {
                        FormField(
                            title: "Postnummer",
                            text: $client.address.postalCode,
                            placeholder: "123 45"
                        )
                        .keyboardType(.numbersAndPunctuation)
                        .textContentType(.postalCode)
                        
                        FormField(
                            title: "Stad",
                            text: $client.address.city,
                            placeholder: "Stockholm"
                        )
                        .textContentType(.addressCity)
                    }
                    
                    FormField(
                        title: "Land",
                        text: $client.address.country,
                        placeholder: "Sverige"
                    )
                    .textContentType(.countryName)
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Client Business Info Section
struct ClientBusinessInfoSection: View {
    @Binding var client: Client
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Företagsuppgifter")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    FormField(
                        title: "Organisationsnummer",
                        text: $client.organizationNumber,
                        placeholder: "556789-1234"
                    )
                    .keyboardType(.numbersAndPunctuation)
                    
                    FormField(
                        title: "VAT-nummer",
                        text: $client.vatNumber,
                        placeholder: "SE556789123401"
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Format för organisationsnummer:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text("• 10 siffror: 5567891234")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Text("• Med bindestreck: 556789-1234")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Form Field Component
struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Client Quick Actions
struct ClientQuickActions: View {
    @Binding var client: Client
    
    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                Text("Snabbåtgärder")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    QuickActionButton(
                        title: "Kopiera från tidigare kund",
                        icon: "person.crop.circle.badge.plus",
                        action: {
                            // Copy from previous client
                        }
                    )
                    
                    QuickActionButton(
                        title: "Importera från kontakter",
                        icon: "person.crop.circle.badge.checkmark",
                        action: {
                            // Import from contacts
                        }
                    )
                    
                    if !client.name.isEmpty {
                        QuickActionButton(
                            title: "Spara som mall",
                            icon: "doc.badge.plus",
                            action: {
                                // Save as template
                            }
                        )
                    }
                }
            }
            .padding(20)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Client Templates
struct ClientTemplate {
    let name: String
    let client: Client
    
    static let templates: [ClientTemplate] = [
        ClientTemplate(
            name: "Enskild firma",
            client: Client(
                name: "",
                address: Address(country: "Sverige")
            )
        ),
        ClientTemplate(
            name: "Aktiebolag",
            client: Client(
                name: "",
                address: Address(country: "Sverige"),
                organizationNumber: "",
                vatNumber: ""
            )
        )
    ]
}

// MARK: - Client Error
struct ClientError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

#Preview {
    ClientFormView(client: .constant(Client()))
}
