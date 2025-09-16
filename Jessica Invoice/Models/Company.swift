//
//  Company.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
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
        logoData: Data? = nil
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
