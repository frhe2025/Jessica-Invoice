import Foundation

extension Date {
    // MARK: - Display Formats
    var displayFormat: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.locale = Locale(identifier: "sv_SE")
        return fmt.string(from: self)
    }
    
    var invoiceTimeString: String {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .short
        return fmt.localizedString(for: self, relativeTo: Date())
    }
    
    var dueDateString: String {
        displayFormat
    }
    
    // MARK: - Ranges and Components
    var startOfWeek: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: comps) ?? self
    }
    
    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }
    
    var startOfMonth: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: self)
        return cal.date(from: comps) ?? self
    }
    
    var endOfMonth: Date {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.month = 1
        comps.day = -1
        return cal.date(byAdding: comps, to: startOfMonth) ?? self
    }
    
    var startOfYear: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year], from: self)
        return cal.date(from: comps) ?? self
    }
    
    var endOfYear: Date {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.year = 1
        comps.day = -1
        return cal.date(byAdding: comps, to: startOfYear) ?? self
    }
    
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    func daysUntil(_ to: Date = Date()) -> Int {
        Calendar.current.dateComponents([.day], from: to, to: self).day ?? 0
    }
    
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
}
