//
//  Invoice.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16
//


//
//  Invoice.swift
//  Jessica Invoice
//
//  Created by Fredrik Hemlin on 2025-09-13.
//

import Foundation

struct Invoice: Identifiable, Codable, Hashable {
    let id = UUID()
    var number: String
    var date: Date
    var dueDate: Date
    var client: Client
    var items: [InvoiceItem]
    var status: InvoiceStatus
    var notes: String
    var paymentTerms: Int // days
    var currency: String
    var vatRate: Double // percentage
    
    // Computed properties
    var subtotal: Double {
        items.reduce(0) { $0 + $1.total }
    }
    
    var vatAmount: Double {
        subtotal * (vatRate / 100)
    }
    
    var total: Double {
        subtotal + vatAmount
    }
    
    var formattedNumber: String {
        "FAK-\(number)"
    }
    
    var isOverdue: Bool {
        Date() > dueDate && status == .sent
    }
    
    init(
        number: String = "",
        date: Date = Date(),
        client: Client = Client(),
        items: [InvoiceItem] = [],
        status: InvoiceStatus = .draft,
        notes: String = "",
        paymentTerms: Int = 30,
        currency: String = "SEK",
        vatRate: Double = 25.0
    ) {
        self.number = number
        self.date = date
        self.dueDate = Calendar.current.date(byAdding: .day, value: paymentTerms, to: date) ?? date
        self.client = client
        self.items = items
        self.status = status
        self.notes = notes
        self.paymentTerms = paymentTerms
        self.currency = currency
        self.vatRate = vatRate
    }
}

struct Client: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var contactPerson: String
    var email: String
    var phone: String
    var address: Address
    var organizationNumber: String
    var vatNumber: String
    
    init(
        name: String = "",
        contactPerson: String = "",
        email: String = "",
        phone: String = "",
        address: Address = Address(),
        organizationNumber: String = "",
        vatNumber: String = ""
    ) {
        self.name = name
        self.contactPerson = contactPerson
        self.email = email
        self.phone = phone
        self.address = address
        self.organizationNumber = organizationNumber
        self.vatNumber = vatNumber
    }
}

struct InvoiceItem: Identifiable, Codable, Hashable {
    let id = UUID()
    var description: String
    var quantity: Double
    var unit: String
    var unitPrice: Double
    var vatRate: Double // percentage
    
    var subtotal: Double {
        quantity * unitPrice
    }
    
    var vatAmount: Double {
        subtotal * (vatRate / 100)
    }
    
    var total: Double {
        subtotal + vatAmount
    }
    
    init(
        description: String = "",
        quantity: Double = 1.0,
        unit: String = "st",
        unitPrice: Double = 0.0,
        vatRate: Double = 25.0
    ) {
        self.description = description
        self.quantity = quantity
        self.unit = unit
        self.unitPrice = unitPrice
        self.vatRate = vatRate
    }
}

struct Address: Codable, Hashable {
    var street: String
    var postalCode: String
    var city: String
    var country: String
    
    var formatted: String {
        "\(street), \(postalCode) \(city)"
    }
    
    init(
        street: String = "",
        postalCode: String = "",
        city: String = "",
        country: String = "Sverige"
    ) {
        self.street = street
        self.postalCode = postalCode
        self.city = city
        self.country = country
    }
}
