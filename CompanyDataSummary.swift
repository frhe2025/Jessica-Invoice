import Foundation

struct CompanyDataSummary: Codable, Identifiable {
    var id: UUID { companyId }
    let companyId: UUID
    let invoiceCount: Int
    let productCount: Int
    let totalInvoiced: Double
    let lastActivity: Date
    
    init(companyId: UUID, invoiceCount: Int, productCount: Int, totalInvoiced: Double, lastActivity: Date) {
        self.companyId = companyId
        self.invoiceCount = invoiceCount
        self.productCount = productCount
        self.totalInvoiced = totalInvoiced
        self.lastActivity = lastActivity
    }
}
