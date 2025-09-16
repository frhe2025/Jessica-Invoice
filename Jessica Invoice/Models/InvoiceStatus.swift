//
//  InvoiceStatus.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import SwiftUI

enum InvoiceStatus: String, CaseIterable, Codable {
    case draft = "draft"
    case sent = "sent"
    case paid = "paid"
    case overdue = "overdue"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .draft: return "Utkast"
        case .sent: return "Skickad"
        case .paid: return "Betald"
        case .overdue: return "Förfallen"
        case .cancelled: return "Avbruten"
        }
    }
    
    var color: Color {
        switch self {
        case .draft: return .gray
        case .sent: return .blue
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .draft: return "doc.text"
        case .sent: return "paperplane.fill"
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .draft: return "Fakturan är sparad som utkast"
        case .sent: return "Fakturan har skickats till kund"
        case .paid: return "Fakturan är betald"
        case .overdue: return "Fakturan har passerat förfallodatum"
        case .cancelled: return "Fakturan är avbruten"
        }
    }
    
    var nextActions: [String] {
        switch self {
        case .draft: return ["Skicka", "Redigera", "Ta bort"]
        case .sent: return ["Markera som betald", "Skicka påminnelse", "Avbryt"]
        case .paid: return ["Visa kvitto", "Skapa kopia"]
        case .overdue: return ["Markera som betald", "Skicka inkasso", "Avbryt"]
        case .cancelled: return ["Återställ", "Ta bort"]
        }
    }
}
