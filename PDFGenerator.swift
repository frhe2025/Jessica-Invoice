#if false
import Foundation
import UIKit
import CoreGraphics

final class PDFGenerator {
    static let shared = PDFGenerator()

    enum PDFGeneratorError: Error, LocalizedError {
        case dataConsumerCreationFailed
        case pdfContextCreationFailed
        case failedToCloseContext
        
        var errorDescription: String? {
            switch self {
            case .dataConsumerCreationFailed:
                return "Failed to create CGDataConsumer."
            case .pdfContextCreationFailed:
                return "Failed to create CGPDFContext."
            case .failedToCloseContext:
                return "Failed to properly close PDF context."
            }
        }
    }

    private init() {}

    @MainActor
    func generateInvoicePDF(_ invoice: Invoice) async throws -> Data {
        var data = Data()
        guard let consumer = CGDataConsumer(data: &data) else {
            throw PDFGeneratorError.dataConsumerCreationFailed
        }

        let mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size points
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFGeneratorError.pdfContextCreationFailed
        }

        context.beginPDFPage(nil)

        defer {
            context.endPDFPage()
            context.closePDF()
        }

        // Flip context coordinates to have origin top-left
        context.translateBy(x: 0, y: mediaBox.height)
        context.scaleBy(x: 1, y: -1)

        // Draw invoice content
        drawInvoice(invoice, in: context, mediaBox: mediaBox)

        return data
    }

    // MARK: - Drawing Helpers

    private func drawInvoice(_ invoice: Invoice, in context: CGContext, mediaBox: CGRect) {
        // Define margins and positions
        let margin: CGFloat = 40
        let width = mediaBox.width - 2 * margin

        // Start Y position from top margin
        var currentY: CGFloat = margin

        // Draw title "Faktura"
        drawText("Faktura",
                 at: CGPoint(x: margin, y: currentY),
                 font: UIFont.boldSystemFont(ofSize: 28),
                 color: .black,
                 in: context)
        currentY += 36

        // Draw invoice number and date
        drawText("Fakturanummer: \(invoice.number)",
                 at: CGPoint(x: margin, y: currentY),
                 font: UIFont.systemFont(ofSize: 14),
                 color: .black,
                 in: context)
        currentY += 20

        if let dateString = dateFormatter.string(from: invoice.date) as String? {
            drawText("Datum: \(dateString)",
                     at: CGPoint(x: margin, y: currentY),
                     font: UIFont.systemFont(ofSize: 14),
                     color: .black,
                     in: context)
            currentY += 30
        } else {
            currentY += 30
        }

        // Draw client name and address
        drawText("Kund:",
                 at: CGPoint(x: margin, y: currentY),
                 font: UIFont.boldSystemFont(ofSize: 16),
                 color: .black,
                 in: context)
        currentY += 20

        drawText(invoice.client.name,
                 at: CGPoint(x: margin + 10, y: currentY),
                 font: UIFont.systemFont(ofSize: 14),
                 color: .black,
                 in: context)
        currentY += 18

        for line in invoice.client.addressLines {
            drawText(line,
                     at: CGPoint(x: margin + 10, y: currentY),
                     font: UIFont.systemFont(ofSize: 14),
                     color: .black,
                     in: context)
            currentY += 18
        }
        currentY += 10

        // Draw table headers
        let colDescX = margin
        let colQtyX = margin + width * 0.55
        let colUnitX = margin + width * 0.75
        let colTotalX = margin + width * 0.9

        drawText("Beskrivning",
                 at: CGPoint(x: colDescX, y: currentY),
                 font: UIFont.boldSystemFont(ofSize: 14),
                 color: .black,
                 in: context)
        drawText("Antal",
                 at: CGPoint(x: colQtyX, y: currentY),
                 font: UIFont.boldSystemFont(ofSize: 14),
                 color: .black,
                 in: context)
        drawText("Enhetspris",
                 at: CGPoint(x: colUnitX, y: currentY),
                 font: UIFont.boldSystemFont(ofSize: 14),
                 color: .black,
                 in: context)
        drawText("Summa",
                 at: CGPoint(x: colTotalX, y: currentY),
                 font: UIFont.boldSystemFont(ofSize: 14),
                 color: .black,
                 in: context)

        currentY += 20

        // Draw separator line below headers
        drawLine(from: CGPoint(x: margin, y: currentY - 5),
                 to: CGPoint(x: margin + width, y: currentY - 5),
                 color: UIColor.black,
                 lineWidth: 1,
                 in: context)

        // Draw items
        for item in invoice.items {
            drawText(item.description,
                     at: CGPoint(x: colDescX, y: currentY),
                     font: UIFont.systemFont(ofSize: 13),
                     color: .black,
                     in: context)

            drawText("\(item.quantity)",
                     at: CGPoint(x: colQtyX, y: currentY),
                     font: UIFont.systemFont(ofSize: 13),
                     color: .black,
                     in: context)

            drawText(formatCurrency(item.unitPrice),
                     at: CGPoint(x: colUnitX, y: currentY),
                     font: UIFont.systemFont(ofSize: 13),
                     color: .black,
                     in: context)

            let lineTotal = item.unitPrice * Double(item.quantity)
            drawText(formatCurrency(lineTotal),
                     at: CGPoint(x: colTotalX, y: currentY),
                     font: UIFont.systemFont(ofSize: 13),
                     color: .black,
                     in: context)

            currentY += 18
        }

        currentY += 10
        drawLine(from: CGPoint(x: margin, y: currentY),
                 to: CGPoint(x: margin + width, y: currentY),
                 color: UIColor.black,
                 lineWidth: 1,
                 in: context)
        currentY += 10

        // Draw totals: subtotal, VAT, total
        let labelX = colUnitX
        let valueX = colTotalX

        drawText("Delsumma:",
                 at: CGPoint(x: labelX, y: currentY),
                 font: UIFont.boldSystemFont(ofSize: 14),
                 color: .black,
                 in: context)
        drawText(formatCurrency(invoice.subtotal),
                 at: CGPoint(x: valueX, y: currentY),
                 font: UIFont.boldSystemFont(ofSize: 14),
                 color: .black,
                 in: context)
        currentY += 20

        drawText("Moms:",
                 at: CGPoint(x: labelX, y: currentY),
                 font: UIFont.boldSystemFont(ofSize: 14),
                 color: .black,
                 in: context)
        drawText(formatCurrency(invoice.vat),
                 at: CGPoint(x: valueX, y: currentY),
                 font: UIFont.boldSystemFont(ofSize: 14),
                 color: .black,
                 in: context)
        currentY += 20

        drawText("Totalt:",
                 at: CGPoint(x: labelX, y: currentY),
                 font: UIFont.boldSystemFont(ofSize: 16),
                 color: .black,
                 in: context)
        drawText(formatCurrency(invoice.total),
                 at: CGPoint(x: valueX, y: currentY),
                 font: UIFont.boldSystemFont(ofSize: 16),
                 color: .black,
                 in: context)
    }

    private func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor, in context: CGContext) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)

        // Flip coordinate system for text drawing
        let line = CTLineCreateWithAttributedString(attributedString)
        context.textPosition = CGPoint(x: point.x, y: point.y)
        CTLineDraw(line, context)
    }

    private func drawLine(from start: CGPoint, to end: CGPoint, color: UIColor, lineWidth: CGFloat, in context: CGContext) {
        context.saveGState()
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        context.restoreGState()
    }

    private func formatCurrency(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: round(value))) ?? "\(Int(round(value))) kr"
    }

    private lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "SEK"
        formatter.currencySymbol = "kr"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = " " // Non-breaking space
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.positiveSuffix = " kr"
        formatter.negativeSuffix = " kr"
        // Use grouping separator as non-breaking space
        return formatter
    }()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter
    }()
}

// MARK: - Supporting types for Invoice (for type completeness)

public struct Invoice {
    public let number: String
    public let date: Date
    public let client: Client
    public let items: [InvoiceItem]
    public let subtotal: Double
    public let vat: Double
    public let total: Double

    public init(number: String, date: Date, client: Client, items: [InvoiceItem], subtotal: Double, vat: Double, total: Double) {
        self.number = number
        self.date = date
        self.client = client
        self.items = items
        self.subtotal = subtotal
        self.vat = vat
        self.total = total
    }
}

public struct Client {
    public let name: String
    public let addressLines: [String]

    public init(name: String, addressLines: [String]) {
        self.name = name
        self.addressLines = addressLines
    }
}

public struct InvoiceItem {
    public let description: String
    public let quantity: Int
    public let unitPrice: Double

    public init(description: String, quantity: Int, unitPrice: Double) {
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
    }
}
#endif
