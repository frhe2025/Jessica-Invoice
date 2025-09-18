//
//  Company.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16 v2.
//


import Foundation

struct Company: Identifiable, Codable {
    let id = UUID()
    var name: String
    var organizationNumber: String
    var vatNumber: String
    var address: Address
    var email: String
    var phone: String
    var website: String
    var bankAccount: BankAccount
    var defaultPaymentTerms: Int
    var defaultCurrency: String
    var defaultVatRate: Double
    var logoData: Data?
    var isPrimaryCompany: Bool
    var isActive: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, name, organizationNumber, vatNumber, address, email, phone, website, bankAccount, defaultPaymentTerms, defaultCurrency, defaultVatRate, logoData, isPrimaryCompany, isActive
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        organizationNumber = try container.decode(String.self, forKey: .organizationNumber)
        vatNumber = try container.decode(String.self, forKey: .vatNumber)
        address = try container.decode(Address.self, forKey: .address)
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decode(String.self, forKey: .phone)
        website = try container.decode(String.self, forKey: .website)
        bankAccount = try container.decode(BankAccount.self, forKey: .bankAccount)
        defaultPaymentTerms = try container.decode(Int.self, forKey: .defaultPaymentTerms)
        defaultCurrency = try container.decode(String.self, forKey: .defaultCurrency)
        defaultVatRate = try container.decode(Double.self, forKey: .defaultVatRate)
        logoData = try container.decodeIfPresent(Data.self, forKey: .logoData)
        isPrimaryCompany = (try? container.decode(Bool.self, forKey: .isPrimaryCompany)) ?? false
        isActive = (try? container.decode(Bool.self, forKey: .isActive)) ?? true
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(organizationNumber, forKey: .organizationNumber)
        try container.encode(vatNumber, forKey: .vatNumber)
        try container.encode(address, forKey: .address)
        try container.encode(email, forKey: .email)
        try container.encode(phone, forKey: .phone)
        try container.encode(website, forKey: .website)
        try container.encode(bankAccount, forKey: .bankAccount)
        try container.encode(defaultPaymentTerms, forKey: .defaultPaymentTerms)
        try container.encode(defaultCurrency, forKey: .defaultCurrency)
        try container.encode(defaultVatRate, forKey: .defaultVatRate)
        try container.encodeIfPresent(logoData, forKey: .logoData)
        try container.encode(isPrimaryCompany, forKey: .isPrimaryCompany)
        try container.encode(isActive, forKey: .isActive)
    }
    
    var hasCompletedSetup: Bool {
        !name.isEmpty &&
        !organizationNumber.isEmpty &&
        !address.street.isEmpty &&
        !email.isEmpty
    }
    
    init(
        name: String = "",
        organizationNumber: String = "",
        vatNumber: String = "",
        address: Address = Address(),
        email: String = "",
        phone: String = "",
        website: String = "",
        bankAccount: BankAccount = BankAccount(),
        defaultPaymentTerms: Int = 30,
        defaultCurrency: String = "SEK",
        defaultVatRate: Double = 25.0,
        logoData: Data? = nil,
        isPrimaryCompany: Bool = false,
        isActive: Bool = true
    ) {
        self.name = name
        self.organizationNumber = organizationNumber
        self.vatNumber = vatNumber
        self.address = address
        self.email = email
        self.phone = phone
        self.website = website
        self.bankAccount = bankAccount
        self.defaultPaymentTerms = defaultPaymentTerms
        self.defaultCurrency = defaultCurrency
        self.defaultVatRate = defaultVatRate
        self.logoData = logoData
        self.isPrimaryCompany = isPrimaryCompany
        self.isActive = isActive
    }
}

struct BankAccount: Codable {
    var bankName: String
    var accountNumber: String
    var clearingNumber: String
    var iban: String
    var bic: String
    
    var hasCompleteInfo: Bool {
        !accountNumber.isEmpty && !clearingNumber.isEmpty
    }
    
    var formattedAccount: String {
        if !clearingNumber.isEmpty && !accountNumber.isEmpty {
            return "\(clearingNumber)-\(accountNumber)"
        }
        return accountNumber
    }
    
    init(
        bankName: String = "",
        accountNumber: String = "",
        clearingNumber: String = "",
        iban: String = "",
        bic: String = ""
    ) {
        self.bankName = bankName
        self.accountNumber = accountNumber
        self.clearingNumber = clearingNumber
        self.iban = iban
        self.bic = bic
    }
}

enum Currency: String, CaseIterable, Codable {
    case sek = "SEK"
    case eur = "EUR"
    case usd = "USD"
    case nok = "NOK"
    case dkk = "DKK"
    
    var symbol: String {
        switch self {
        case .sek: return "kr"
        case .eur: return "€"
        case .usd: return "$"
        case .nok: return "kr"
        case .dkk: return "kr"
        }
    }
    
    var displayName: String {
        switch self {
        case .sek: return "Svenska kronor (SEK)"
        case .eur: return "Euro (EUR)"
        case .usd: return "US Dollar (USD)"
        case .nok: return "Norska kronor (NOK)"
        case .dkk: return "Danska kronor (DKK)"
        }
    }
}

