//
//  PDFGenerator.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import Foundation
import UIKit
import PDFKit

@MainActor
class PDFGenerator: ObservableObject {
    static let shared = PDFGenerator()
    
    private init() {}
    
    // MARK: - PDF Generation
    func generateInvoicePDF(_ invoice: Invoice) async throws -> Data {
        let company = try await DataManager.shared.loadCompany()
        
        // Create PDF context
        let pdfData = NSMutableData()
        let pdfContext = CGContext(
            consumer: CGDataConsumer(data: pdfData)!,
            mediaBox: &CGRect(x: 0, y: 0, width: 595, height: 842), // A4 size
            nil
        )!
        
        pdfContext.beginPDFPage(nil)
        
        // Draw the invoice
        drawInvoice(invoice, company: company, in: pdfContext)
        
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        return pdfData as Data
    }
    
    private func drawInvoice(_ invoice: Invoice, company: Company, in context: CGContext) {
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 50
        var currentY: CGFloat = pageHeight - margin
        
        // Helper function to draw text
        func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor = .black, alignment: NSTextAlignment = .left, maxWidth: CGFloat = pageWidth - 2 * margin) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]
            
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedString.boundingRect(
                with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).size
            
            var drawPoint = point
            if alignment == .center {
                drawPoint.x = (pageWidth - textSize.width) / 2
            } else if alignment == .right {
                drawPoint.x = pageWidth - margin - textSize.width
            }
            
            // Flip Y coordinate for PDF context
            let flippedY = pageHeight - point.y - textSize.height
            drawPoint.y = flippedY
            
            context.saveGState()
            context.textMatrix = .identity
            context.translateBy(x: 0, y: pageHeight)
            context.scaleBy(x: 1, y: -1)
            
            attributedString.draw(at: CGPoint(x: drawPoint.x, y: pageHeight - point.y))
            
            context.restoreGState()
        }
        
        func drawLine(from start: CGPoint, to end: CGPoint, color: UIColor = .black, width: CGFloat = 1) {
            context.saveGState()
            context.setLineWidth(width)
            context.setStrokeColor(color.cgColor)
            context.move(to: CGPoint(x: start.x, y: pageHeight - start.y))
            context.addLine(to: CGPoint(x: end.x, y: pageHeight - end.y))
            context.strokePath()
            context.restoreGState()
        }
        
        // Fonts
        let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        let headerFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let bodyFont = UIFont.systemFont(ofSize: 12)
        let boldFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        
        // Company Header
        drawText(company.name, at: CGPoint(x: margin, y: currentY), font: titleFont, color: .systemBlue)
        currentY -= 35
        
        if !company.address.street.isEmpty {
            drawText(company.address.street, at: CGPoint(x: margin, y: currentY), font: bodyFont)
            currentY -= 18
        }
        
        if !company.address.postalCode.isEmpty {
            drawText("\(company.address.postalCode) \(company.address.city)", at: CGPoint(x: margin, y: currentY), font: bodyFont)
            currentY -= 18
        }
        
        if !company.phone.isEmpty {
            drawText("Tel: \(company.phone)", at: CGPoint(x: margin, y: currentY), font: bodyFont)
            currentY -= 18
        }
        
        if !company.email.isEmpty {
            drawText("E-post: \(company.email)", at: CGPoint(x: margin, y: currentY), font: bodyFont)
            currentY -= 18
        }
        
        // Invoice title and number
        currentY -= 30
        drawText("FAKTURA", at: CGPoint(x: margin, y: currentY), font: titleFont)
        drawText(invoice.formattedNumber, at: CGPoint(x: pageWidth - margin, y: currentY), font: titleFont, alignment: .right)
        currentY -= 50
        
        // Invoice details (right side)
        let detailsX: CGFloat = pageWidth - 200
        let startDetailsY = currentY
        
        drawText("Fakturadatum:", at: CGPoint(x: detailsX, y: currentY), font: boldFont)
        drawText(DateFormatter.invoiceFormatter.string(from: invoice.date),
                at: CGPoint(x: detailsX + 120, y: currentY), font: bodyFont)
        currentY -= 20
        
        drawText("Förfallodatum:", at: CGPoint(x: detailsX, y: currentY), font: boldFont)
        drawText(DateFormatter.invoiceFormatter.string(from: invoice.dueDate),
                at: CGPoint(x: detailsX + 120, y: currentY), font: bodyFont)
        currentY -= 20
        
        drawText("Betalningsvillkor:", at: CGPoint(x: detailsX, y: currentY), font: boldFont)
        drawText("\(invoice.paymentTerms) dagar",
                at: CGPoint(x: detailsX + 120, y: currentY), font: bodyFont)
        
        // Client information (left side)
        currentY = startDetailsY
        drawText("Kund:", at: CGPoint(x: margin, y: currentY), font: headerFont)
        currentY -= 25
        
        drawText(invoice.client.name, at: CGPoint(x: margin, y: currentY), font: boldFont)
        currentY -= 18
        
        if !invoice.client.contactPerson.isEmpty {
            drawText("Att: \(invoice.client.contactPerson)", at: CGPoint(x: margin, y: currentY), font: bodyFont)
            currentY -= 18
        }
        
        if !invoice.client.address.street.isEmpty {
            drawText(invoice.client.address.street, at: CGPoint(x: margin, y: currentY), font: bodyFont)
            currentY -= 18
            
            if !invoice.client.address.postalCode.isEmpty {
                drawText("\(invoice.client.address.postalCode) \(invoice.client.address.city)",
                        at: CGPoint(x: margin, y: currentY), font: bodyFont)
                currentY -= 18
            }
        }
        
        if !invoice.client.organizationNumber.isEmpty {
            drawText("Org.nr: \(invoice.client.organizationNumber)", at: CGPoint(x: margin, y: currentY), font: bodyFont)
            currentY -= 18
        }
        
        // Items table
        currentY -= 40
        let tableStartY = currentY
        
        // Table headers
        let col1X: CGFloat = margin
        let col2X: CGFloat = 200
        let col3X: CGFloat = 320
        let col4X: CGFloat = 380
        let col5X: CGFloat = 450
        let col6X: CGFloat = pageWidth - margin - 80
        
        drawText("Beskrivning", at: CGPoint(x: col1X, y: currentY), font: boldFont)
        drawText("Antal", at: CGPoint(x: col2X, y: currentY), font: boldFont)
        drawText("Enhet", at: CGPoint(x: col3X, y: currentY), font: boldFont)
        drawText("Pris", at: CGPoint(x: col4X, y: currentY), font: boldFont)
        drawText("Moms %", at: CGPoint(x: col5X, y: currentY), font: boldFont)
        drawText("Belopp", at: CGPoint(x: col6X, y: currentY), font: boldFont)
        currentY -= 8
        
        // Header line
        drawLine(from: CGPoint(x: margin, y: currentY), to: CGPoint(x: pageWidth - margin, y: currentY))
        currentY -= 20
        
        // Items
        for item in invoice.items {
            drawText(item.description, at: CGPoint(x: col1X, y: currentY), font: bodyFont)
            drawText(String(format: "%.1f", item.quantity), at: CGPoint(x: col2X, y: currentY), font: bodyFont)
            drawText(item.unit, at: CGPoint(x: col3X, y: currentY), font: bodyFont)
            drawText(String(format: "%.0f kr", item.unitPrice), at: CGPoint(x: col4X, y: currentY), font: bodyFont)
            drawText(String(format: "%.0f%%", item.vatRate), at: CGPoint(x: col5X, y: currentY), font: bodyFont)
            drawText(String(format: "%.0f kr", item.total), at: CGPoint(x: col6X, y: currentY), font: bodyFont, alignment: .right)
            currentY -= 22
        }
        
        // Totals
        currentY -= 20
        drawLine(from: CGPoint(x: col5X - 20, y: currentY), to: CGPoint(x: pageWidth - margin, y: currentY))
        currentY -= 20
        
        drawText("Exkl. moms:", at: CGPoint(x: col5X, y: currentY), font: boldFont)
        drawText(String(format: "%.0f kr", invoice.subtotal), at: CGPoint(x: col6X, y: currentY), font: boldFont, alignment: .right)
        currentY -= 20
        
        drawText("Moms (\(String(format: "%.0f", invoice.vatRate))%):", at: CGPoint(x: col5X, y: currentY), font: boldFont)
        drawText(String(format: "%.0f kr", invoice.vatAmount), at: CGPoint(x: col6X, y: currentY), font: boldFont, alignment: .right)
        currentY -= 8
        
        drawLine(from: CGPoint(x: col5X - 20, y: currentY), to: CGPoint(x: pageWidth - margin, y: currentY))
        currentY -= 20
        
        drawText("ATT BETALA:", at: CGPoint(x: col5X, y: currentY), font: titleFont.withSize(16), color: .systemBlue)
        drawText(String(format: "%.0f kr", invoice.total), at: CGPoint(x: col6X, y: currentY), font: titleFont.withSize(16), color: .systemBlue, alignment: .right)
        
        // Payment information
        if company.bankAccount.hasCompleteInfo {
            currentY -= 60
            drawText("Betalningsinformation:", at: CGPoint(x: margin, y: currentY), font: headerFont)
            currentY -= 25
            
            if !company.bankAccount.bankName.isEmpty {
                drawText("Bank: \(company.bankAccount.bankName)", at: CGPoint(x: margin, y: currentY), font: bodyFont)
                currentY -= 18
            }
            
            drawText("Kontonummer: \(company.bankAccount.formattedAccount)", at: CGPoint(x: margin, y: currentY), font: bodyFont)
            currentY -= 18
            
            if !company.bankAccount.iban.isEmpty {
                drawText("IBAN: \(company.bankAccount.iban)", at: CGPoint(x: margin, y: currentY), font: bodyFont)
                currentY -= 18
            }
            
            if !company.bankAccount.bic.isEmpty {
                drawText("BIC/SWIFT: \(company.bankAccount.bic)", at: CGPoint(x: margin, y: currentY), font: bodyFont)
                currentY -= 18
            }
        }
        
        // Notes
        if !invoice.notes.isEmpty {
            currentY -= 40
            drawText("Anmärkningar:", at: CGPoint(x: margin, y: currentY), font: headerFont)
            currentY -= 25
            drawText(invoice.notes, at: CGPoint(x: margin, y: currentY), font: bodyFont)
        }
        
        // Footer
        let footerY: CGFloat = 80
        if !company.vatNumber.isEmpty {
            drawText("VAT-nr: \(company.vatNumber)", at: CGPoint(x: margin, y: footerY), font: bodyFont.withSize(10), color: .gray)
        }
        
        if !company.organizationNumber.isEmpty {
            drawText("Org.nr: \(company.organizationNumber)", at: CGPoint(x: pageWidth - margin, y: footerY), font: bodyFont.withSize(10), color: .gray, alignment: .right)
        }
    }
    
    // MARK: - Preview Generation
    func generateInvoicePreview(_ invoice: Invoice, size: CGSize = CGSize(width: 300, height: 400)) async throws -> UIImage {
        let company = try await DataManager.shared.loadCompany()
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Scale down the invoice drawing to fit preview size
            let scale = min(size.width / 595, size.height / 842)
            cgContext.scaleBy(x: scale, y: scale)
            
            // Draw a simplified version for preview
            drawInvoicePreview(invoice, company: company, in: cgContext, bounds: CGRect(origin: .zero, size: size))
        }
    }
    
    private func drawInvoicePreview(_ invoice: Invoice, company: Company, in context: CGContext, bounds: CGRect) {
        context.setFillColor(UIColor.white.cgColor)
        context.fill(bounds)
        
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.stroke(bounds)
        
        // Draw simplified content
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.black
        ]
        
        let text = """
        \(company.name)
        
        FAKTURA \(invoice.formattedNumber)
        
        \(invoice.client.name)
        \(invoice.items.count) artiklar
        
        Totalt: \(String(format: "%.0f", invoice.total)) kr
        """
        
        text.draw(in: bounds.insetBy(dx: 10, dy: 10), withAttributes: attributes)
    }
    
    // MARK: - Export Options
    func generateMultipleInvoicesPDF(_ invoices: [Invoice]) async throws -> Data {
        let pdfData = NSMutableData()
        let pdfContext = CGContext(
            consumer: CGDataConsumer(data: pdfData)!,
            mediaBox: &CGRect(x: 0, y: 0, width: 595, height: 842),
            nil
        )!
        
        let company = try await DataManager.shared.loadCompany()
        
        for (index, invoice) in invoices.enumerated() {
            if index > 0 {
                pdfContext.beginPDFPage(nil)
            } else {
                pdfContext.beginPDFPage(nil)
            }
            
            drawInvoice(invoice, company: company, in: pdfContext)
            pdfContext.endPDFPage()
        }
        
        pdfContext.closePDF()
        return pdfData as Data
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let invoiceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter
    }()
}
