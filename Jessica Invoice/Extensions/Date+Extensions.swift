//
//  Date+Extensions.swift
//  Jessica Invoice
//
//  Created by Claude on 2025-09-16.
//

import Foundation

// MARK: - Date Calculations
extension Date {
    
    /// Add days to date
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// Add weeks to date
    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }
    
    /// Add months to date
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    /// Add years to date
    func adding(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }
    
    /// Get start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Get end of day
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
    
    /// Get start of week
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Get end of week
    var endOfWeek: Date {
        startOfWeek.adding(days: 6).endOfDay
    }
    
    /// Get start of month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Get end of month
    var endOfMonth: Date {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return self }
        return calendar.date(byAdding: .day, value: -1, to: nextMonth)?.endOfDay ?? self
    }
    
    /// Get start of year
    var startOfYear: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Get end of year
    var endOfYear: Date {
        let calendar = Calendar.current
        guard let nextYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) else { return self }
        return calendar.date(byAdding: .day, value: -1, to: nextYear)?.endOfDay ?? self
    }
}

// MARK: - Date Comparisons
extension Date {
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Check if date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// Check if date is this week
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Check if date is this month
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// Check if date is this year
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    /// Check if date is in the past
    var isPast: Bool {
        self < Date()
    }
    
    /// Check if date is in the future
    var isFuture: Bool {
        self > Date()
    }
    
    /// Check if date is weekend
    var isWeekend: Bool {
        Calendar.current.isDateInWeekend(self)
    }
    
    /// Check if date is weekday
    var isWeekday: Bool {
        !isWeekend
    }
}

// MARK: - Date Components
extension Date {
    
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
    
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
    
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
    
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
    
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }
    
    var second: Int {
        Calendar.current.component(.second, from: self)
    }
    
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }
    
    var weekOfYear: Int {
        Calendar.current.component(.weekOfYear, from: self)
    }
    
    var monthName: String {
        DateFormatter.monthFormatter.string(from: self)
    }
    
    var monthShortName: String {
        DateFormatter.monthShortFormatter.string(from: self)
    }
    
    var weekdayName: String {
        DateFormatter.weekdayFormatter.string(from: self)
    }
    
    var weekdayShortName: String {
        DateFormatter.weekdayShortFormatter.string(from: self)
    }
}

// MARK: - Time Since/Until
extension Date {
    
    /// Days since this date
    func daysSince() -> Int {
        Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
    }
    
    /// Days until this date
    func daysUntil() -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: self).day ?? 0
    }
    
    /// Weeks since this date
    func weeksSince() -> Int {
        Calendar.current.dateComponents([.weekOfYear], from: self, to: Date()).weekOfYear ?? 0
    }
    
    /// Weeks until this date
    func weeksUntil() -> Int {
        Calendar.current.dateComponents([.weekOfYear], from: Date(), to: self).weekOfYear ?? 0
    }
    
    /// Months since this date
    func monthsSince() -> Int {
        Calendar.current.dateComponents([.month], from: self, to: Date()).month ?? 0
    }
    
    /// Months until this date
    func monthsUntil() -> Int {
        Calendar.current.dateComponents([.month], from: Date(), to: self).month ?? 0
    }
    
    /// Years since this date
    func yearsSince() -> Int {
        Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0
    }
    
    /// Years until this date
    func yearsUntil() -> Int {
        Calendar.current.dateComponents([.year], from: Date(), to: self).year ?? 0
    }
}

// MARK: - Relative Date Strings
extension Date {
    
    /// Get relative string (e.g., "2 days ago", "in 3 days")
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Get short relative string (e.g., "2d ago", "in 3d")
    var shortRelativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Get time ago string for invoice context
    var invoiceTimeString: String {
        if isToday {
            return "Idag"
        } else if isYesterday {
            return "Igår"
        } else if daysSince() <= 7 {
            return "\(daysSince()) dagar sedan"
        } else if daysSince() <= 30 {
            let weeks = weeksSince()
            return weeks == 1 ? "1 vecka sedan" : "\(weeks) veckor sedan"
        } else if daysSince() <= 365 {
            let months = monthsSince()
            return months == 1 ? "1 månad sedan" : "\(months) månader sedan"
        } else {
            let years = yearsSince()
            return years == 1 ? "1 år sedan" : "\(years) år sedan"
        }
    }
    
    /// Get due date status string
    var dueDateString: String {
        if isToday {
            return "Förfaller idag"
        } else if isTomorrow {
            return "Förfaller imorgon"
        } else if isPast {
            let days = daysSince()
            return days == 1 ? "Förföll igår" : "Förföll \(days) dagar sedan"
        } else {
            let days = daysUntil()
            return days == 1 ? "Förfaller imorgon" : "Förfaller om \(days) dagar"
        }
    }
}

// MARK: - Formatting Helpers
extension Date {
    
    /// Format date for invoices
    var invoiceFormat: String {
        DateFormatter.invoiceDateFormatter.string(from: self)
    }
    
    /// Format date for display
    var displayFormat: String {
        DateFormatter.displayFormatter.string(from: self)
    }
    
    /// Format date shortly
    var shortFormat: String {
        DateFormatter.shortFormatter.string(from: self)
    }
    
    /// Format time only
    var timeFormat: String {
        DateFormatter.timeFormatter.string(from: self)
    }
    
    /// Format for file names
    var fileNameFormat: String {
        DateFormatter.fileNameFormatter.string(from: self)
    }
    
    /// ISO format
    var isoFormat: String {
        DateFormatter.isoFormatter.string(from: self)
    }
}

// MARK: - Date Ranges
extension Date {
    
    /// Create date range from start date with duration
    func dateRange(days: Int) -> ClosedRange<Date> {
        return self...self.adding(days: days)
    }
    
    /// Create date range for current week
    static var thisWeek: ClosedRange<Date> {
        let today = Date()
        return today.startOfWeek...today.endOfWeek
    }
    
    /// Create date range for current month
    static var thisMonth: ClosedRange<Date> {
        let today = Date()
        return today.startOfMonth...today.endOfMonth
    }
    
    /// Create date range for current year
    static var thisYear: ClosedRange<Date> {
        let today = Date()
        return today.startOfYear...today.endOfYear
    }
    
    /// Create date range for last 30 days
    static var last30Days: ClosedRange<Date> {
        let today = Date()
        return today.adding(days: -30)...today
    }
    
    /// Create date range for last 90 days
    static var last90Days: ClosedRange<Date> {
        let today = Date()
        return today.adding(days: -90)...today
    }
    
    /// Create date range for last year
    static var lastYear: ClosedRange<Date> {
        let today = Date()
        let lastYear = today.adding(years: -1)
        return lastYear.startOfYear...lastYear.endOfYear
    }
}

// MARK: - Business Date Logic
extension Date {
    
    /// Get next business day
    var nextBusinessDay: Date {
        var date = self.adding(days: 1)
        while date.isWeekend {
            date = date.adding(days: 1)
        }
        return date
    }
    
    /// Get previous business day
    var previousBusinessDay: Date {
        var date = self.adding(days: -1)
        while date.isWeekend {
            date = date.adding(days: -1)
        }
        return date
    }
    
    /// Calculate business days between two dates
    func businessDays(until endDate: Date) -> Int {
        let calendar = Calendar.current
        var businessDays = 0
        var currentDate = self
        
        while currentDate <= endDate {
            if !currentDate.isWeekend {
                businessDays += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return businessDays
    }
    
    /// Add business days to date
    func addingBusinessDays(_ days: Int) -> Date {
        var date = self
        var remainingDays = days
        
        while remainingDays > 0 {
            date = date.adding(days: 1)
            if !date.isWeekend {
                remainingDays -= 1
            }
        }
        
        return date
    }
}

// MARK: - DateFormatter Extensions
extension DateFormatter {
    
    static let invoiceDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter
    }()
    
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter
    }()
    
    static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter
    }()
    
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
    
    static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter
    }()
    
    static let monthShortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter
    }()
    
    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter
    }()
    
    static let weekdayShortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter
    }()
}

// MARK: - Swedish Specific Extensions
extension Date {
    
    /// Swedish month names
    var swedishMonthName: String {
        let months = [
            "januari", "februari", "mars", "april", "maj", "juni",
            "juli", "augusti", "september", "oktober", "november", "december"
        ]
        return months[month - 1]
    }
    
    /// Swedish weekday names
    var swedishWeekdayName: String {
        let weekdays = [
            "", "söndag", "måndag", "tisdag", "onsdag", "torsdag", "fredag", "lördag"
        ]
        return weekdays[weekday]
    }
    
    /// Swedish short weekday names
    var swedishWeekdayShort: String {
        let weekdays = [
            "", "sön", "mån", "tis", "ons", "tor", "fre", "lör"
        ]
        return weekdays[weekday]
    }
    
    /// Format date in Swedish style
    var swedishFormat: String {
        return "\(day) \(swedishMonthName) \(year)"
    }
}
