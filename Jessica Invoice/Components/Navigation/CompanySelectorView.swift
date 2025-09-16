//
//  CompanySelectorView.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-16.
//


//
//  CompanySelectorView.swift
//  Jessica Invoice
//
//  📁 PLACERA I: Components/Navigation/
//  iOS 26 Multi-Company Selector with Liquid Glass
//

import SwiftUI

// MARK: - Company Selector View
struct CompanySelectorView: View {
    @EnvironmentObject var companyManager: CompanyManager
    @State private var showingSelector = false
    @State private var animationPhase: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button {
            showingSelector = true
            triggerHapticFeedback()
        } label: {
            selectorContent
        }
        .liquidButtonStyle(variant: .tertiary, size: .medium)
        .sheet(isPresented: $showingSelector) {
            CompanyPickerSheet()
        }
        .onAppear {
            startSubtleAnimation()
        }
    }
    
    // MARK: - Selector Content
    private var selectorContent: some View {
        HStack(spacing: 12) {
            // Company Avatar with Liquid Effect
            companyAvatar
            
            // Company Info
            companyInfo
            
            Spacer()
            
            // Selector Indicator
            selectorIndicator
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Company Avatar
    private var companyAvatar: some View {
        ZStack {
            // Liquid background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            .blue.opacity(0.8),
                            .cyan.opacity(0.6),
                            .indigo.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
            
            // Subtle shimmer effect
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.4),
                            .clear,
                            .white.opacity(0.2)
                        ],
                        startPoint: UnitPoint(x: animationPhase, y: 0),
                        endPoint: UnitPoint(x: 1 + animationPhase, y: 1)
                    ),
                    lineWidth: 1
                )
                .frame(width: 36, height: 36)
            
            // Company Initials
            Text(companyInitials)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Company Info
    private var companyInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(companyName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let company = companyManager.selectedCompany, company.isPrimaryCompany {
                    primaryBadge
                }
            }
            
            if let company = companyManager.selectedCompany, !company.organizationNumber.isEmpty {
                Text(company.organizationNumber)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Primary Badge
    private var primaryBadge: some View {
        Text("PRIMÄR")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(
                Capsule()
                    .fill(.blue.opacity(0.15))
            )
            .foregroundStyle(.blue)
    }
    
    // MARK: - Selector Indicator
    private var selectorIndicator: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 1)
                .fill(.secondary)
                .frame(width: 8, height: 2)
            RoundedRectangle(cornerRadius: 1)
                .fill(.secondary)
                .frame(width: 8, height: 2)
        }
        .rotationEffect(.degrees(showingSelector ? 180 : 0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingSelector)
    }
    
    // MARK: - Computed Properties
    private var companyName: String {
        companyManager.selectedCompany?.name ?? "Välj företag"
    }
    
    private var companyInitials: String {
        companyManager.selectedCompany?.name.prefix(2).uppercased() ?? "AB"
    }
    
    // MARK: - Animation Functions
    private func startSubtleAnimation() {
        withAnimation(
            .linear(duration: 3.0)
            .repeatForever(autoreverses: false)
        ) {
            animationPhase = 1.0
        }
    }
    
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Company Picker Sheet
struct CompanyPickerSheet: View {
    @EnvironmentObject var companyManager: CompanyManager
    @Environment(\.dismiss) var dismiss
    @State private var showingAddCompany = false
    @State private var animationDelay: Double = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Companies List
                    companiesSection
                    
                    // Add Company Section
                    addCompanySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .liquidGlassBackground(.settings)
            .navigationTitle("Välj Företag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Stäng") {
                        dismiss()
                    }
                    .liquidButtonStyle(variant: .ghost, size: .small)
                }
            }
        }
        .sheet(isPresented: $showingAddCompany) {
            AddCompanyView()
        }
        .onAppear {
            animateCompanyCards()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        LiquidGlassCard.prominent {
            VStack(spacing: 16) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue.gradient)
                
                VStack(spacing: 8) {
                    Text("Välj Företag")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Växla mellan dina företag för att se specifika fakturor och produkter")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Companies Section
    private var companiesSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(companyManager.companies.enumerated()), id: \.element.id) { index, company in
                LiquidCompanyCard(
                    company: company,
                    isSelected: company.id == companyManager.selectedCompany?.id,
                    animationDelay: Double(index) * 0.1
                ) {
                    selectCompany(company)
                }
            }
        }
    }
    
    // MARK: - Add Company Section
    private var addCompanySection: some View {
        Button {
            showingAddCompany = true
        } label: {
            LiquidGlassCard.interactive {
                HStack(spacing: 16) {
                    // Plus Icon with Animation
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue.gradient)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lägg till nytt företag")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Text("Skapa ett nytt företag för fakturering")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .padding(20)
            }
        }
        .liquidButtonStyle(variant: .ghost, size: .large)
    }
    
    // MARK: - Helper Functions
    private func selectCompany(_ company: Company) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        companyManager.selectCompany(company)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }
    
    private func animateCompanyCards() {
        for (index, _) in companyManager.companies.enumerated() {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.8)
                .delay(Double(index) * 0.1)
            ) {
                animationDelay += 0.1
            }
        }
    }
}

// MARK: - Liquid Company Card
struct LiquidCompanyCard: View {
    let company: Company
    let isSelected: Bool
    let animationDelay: Double
    let onSelect: () -> Void
    
    @State private var animationPhase: CGFloat = 0
    @State private var isVisible = false
    
    var body: some View {
        Button(action: onSelect) {
            LiquidGlassCard(
                style: isSelected ? .prominent : .adaptive,
                depth: isSelected ? .deep : .medium
            ) {
                cardContent
            }
        }
        .liquidButtonStyle(variant: .ghost, size: .large)
        .overlay(selectionIndicator)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0)
        .onAppear {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.8)
                .delay(animationDelay)
            ) {
                isVisible = true
            }
            
            if isSelected {
                startShimmerEffect()
            }
        }
    }
    
    // MARK: - Card Content
    private var cardContent: some View {
        HStack(spacing: 16) {
            // Company Avatar
            companyAvatar
            
            // Company Details
            companyDetails
            
            Spacer()
            
            // Status Indicators
            statusIndicators
        }
        .padding(20)
    }
    
    // MARK: - Company Avatar
    private var companyAvatar: some View {
        ZStack {
            Circle()
                .fill(companyGradient)
                .frame(width: 52, height: 52)
            
            if isSelected {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .clear, .white.opacity(0.3)],
                            startPoint: UnitPoint(x: animationPhase, y: 0),
                            endPoint: UnitPoint(x: 1 + animationPhase, y: 1)
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 52, height: 52)
            }
            
            Text(company.name.prefix(2).uppercased())
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Company Details
    private var companyDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(company.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                if company.isPrimaryCompany {
                    primaryBadge
                }
            }
            
            if !company.organizationNumber.isEmpty {
                Text(company.organizationNumber)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if !company.address.city.isEmpty {
                Text("\(company.address.city), \(company.address.country)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    // MARK: - Status Indicators
    private var statusIndicators: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if isSelected {
                selectionCheckmark
            }
            
            if company.isActive {
                activeStatusIndicator
            }
        }
    }
    
    // MARK: - Component Elements
    private var companyGradient: LinearGradient {
        LinearGradient(
            colors: [
                .blue,
                .cyan,
                .indigo
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var primaryBadge: some View {
        Text("PRIMÄR")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.blue.opacity(0.15))
            )
            .foregroundStyle(.blue)
    }
    
    private var selectionCheckmark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.title2)
            .foregroundStyle(.green.gradient)
    }
    
    private var activeStatusIndicator: some View {
        Circle()
            .fill(.green)
            .frame(width: 8, height: 8)
    }
    
    private var selectionIndicator: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                isSelected ? .blue.opacity(0.4) : .clear,
                lineWidth: 2
            )
    }
    
    // MARK: - Animation Functions
    private func startShimmerEffect() {
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            animationPhase = 1.0
        }
    }
}

// MARK: - Add Company View
struct AddCompanyView: View {
    @EnvironmentObject var companyManager: CompanyManager
    @Environment(\.dismiss) var dismiss
    @State private var company = Company()
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerCard
                    
                    // Company Form
                    companyFormSections
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .liquidGlassBackground(.settings)
            .navigationTitle("Nytt Företag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                    .liquidButtonStyle(variant: .ghost, size: .small)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Spara") {
                        saveCompany()
                    }
                    .liquidButtonStyle(variant: .primary, size: .small, isLoading: isLoading)
                    .disabled(company.name.isEmpty || company.organizationNumber.isEmpty)
                }
            }
        }
        .alert("Fel", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        LiquidGlassCard.prominent {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue.gradient)
                
                Text("Lägg till nytt företag")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Skapa ett nytt företag för att hantera separata fakturor och produkter")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }
    
    // MARK: - Company Form Sections
    private var companyFormSections: some View {
        VStack(spacing: 20) {
            // Basic Information
            LiquidGlassCard.interactive {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Grunduppgifter", icon: "building.2")
                    
                    VStack(spacing: 12) {
                        LiquidTextField(title: "Företagsnamn *", text: $company.name, placeholder: "Ange företagsnamn")
                        LiquidTextField(title: "Organisationsnummer *", text: $company.organizationNumber, placeholder: "556789-1234")
                        LiquidTextField(title: "E-post", text: $company.email, placeholder: "kontakt@företag.se")
                        LiquidTextField(title: "Telefon", text: $company.phone, placeholder: "08-123 45 67")
                    }
                }
                .padding(20)
            }
            
            // Settings
            LiquidGlassCard.interactive {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Inställningar", icon: "gearshape")
                    
                    VStack(spacing: 16) {
                        Toggle("Sätt som primärt företag", isOn: $company.isPrimaryCompany)
                            .toggleStyle(LiquidToggleStyle())
                        
                        if company.isPrimaryCompany {
                            infoBox("Detta kommer att vara ditt huvudföretag och visas först")
                        }
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
    
    private func infoBox(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Save Function
    private func saveCompany() {
        isLoading = true
        
        Task {
            do {
                try await companyManager.addCompany(company)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Liquid Text Field
struct LiquidTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .stroke(isFocused ? .blue.opacity(0.5) : .clear, lineWidth: 1)
                )
        }
    }
}

// MARK: - Liquid Toggle Style
struct LiquidToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? .blue.gradient : .gray.opacity(0.3))
                .frame(width: 44, height: 26)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .offset(x: configuration.isOn ? 9 : -9)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

#Preview {
    CompanySelectorView()
        .environmentObject(CompanyManager())
        .padding()
}