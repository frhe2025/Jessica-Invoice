//
//  Date+Helpers.swift
//  Created to provide useful Date extensions for calendar calculations.
//

import Foundation

public extension Date {
    /// Returns true if the date is in the current calendar month and year.
    var isThisMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        let selfComponents = calendar.dateComponents([.year, .month], from: self)
        let nowComponents = calendar.dateComponents([.year, .month], from: now)
        return selfComponents.year == nowComponents.year && selfComponents.month == nowComponents.month
    }
    
    /// Returns the start of the week for the date, using the specified calendar (default is current).
    /// If the calendar does not have a week start, it returns the date itself.
    /// - Parameter calendar: The calendar to use for calculation.
    /// - Returns: The start of the week date.
    func startOfWeek(using calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Returns the end of the week for the date, using the specified calendar (default is current).
    /// The end of the week is considered the start of the next week minus one second.
    /// - Parameter calendar: The calendar to use for calculation.
    /// - Returns: The end of the week date.
    func endOfWeek(using calendar: Calendar = .current) -> Date {
        let startOfWeek = self.startOfWeek(using: calendar)
        guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) else {
            return self
        }
        return nextWeek.addingTimeInterval(-1)
    }
    
    /// Returns the start of the month for the date, using the specified calendar (default is current).
    /// - Parameter calendar: The calendar to use for calculation.
    /// - Returns: The start of the month date.
    func startOfMonth(using calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Returns the end of the month for the date, using the specified calendar (default is current).
    /// The end of the month is considered the start of the next month minus one second.
    /// - Parameter calendar: The calendar to use for calculation.
    /// - Returns: The end of the month date.
    func endOfMonth(using calendar: Calendar = .current) -> Date {
        let startOfMonth = self.startOfMonth(using: calendar)
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return self
        }
        return nextMonth.addingTimeInterval(-1)
    }
    
    /// Returns the start of the year for the date, using the specified calendar (default is current).
    /// - Parameter calendar: The calendar to use for calculation.
    /// - Returns: The start of the year date.
    func startOfYear(using calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Returns the end of the year for the date, using the specified calendar (default is current).
    /// The end of the year is considered the start of the next year minus one second.
    /// - Parameter calendar: The calendar to use for calculation.
    /// - Returns: The end of the year date.
    func endOfYear(using calendar: Calendar = .current) -> Date {
        let startOfYear = self.startOfYear(using: calendar)
        guard let nextYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) else {
            return self
        }
        return nextYear.addingTimeInterval(-1)
    }
    
    /// Returns a new date by adding the specified value to the given calendar component.
    /// - Parameters:
    ///   - component: The calendar component to add to.
    ///   - value: The amount to add.
    ///   - calendar: The calendar to use for calculation (default is current).
    /// - Returns: A new date if addition succeeds, otherwise nil.
    func adding(_ component: Calendar.Component, value: Int, using calendar: Calendar = .current) -> Date? {
        return calendar.date(byAdding: component, value: value, to: self)
    }
    
    /// A localized, medium-style date string used in invoice UI (e.g., "23 sep. 2025")
    var invoiceTimeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// A localized medium date string for general display (e.g., 23 sep. 2025)
    var displayFormat: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Returns a human-friendly due date string, e.g. "Förfaller om 3 dagar" or "Förföll för 2 dagar sedan"
    var dueDateString: String {
        let days = daysUntil
        if days > 0 {
            return "Förfaller om \(days) dagar"
        } else if days == 0 {
            return "Förfaller idag"
        } else {
            return "Förföll för \(-days) dagar sedan"
        }
    }
    
    /// Number of whole days from now until this date (negative if in the past)
    var daysUntil: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTarget = calendar.startOfDay(for: self)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget)
        return components.day ?? 0
    }
    
    /// This month range: startOfMonth...endOfMonth for today
    static var thisMonth: ClosedRange<Date> {
        let now = Date()
        return now.startOfMonth()...now.endOfMonth()
    }

    /// Last 30 days range: (now - 30 days)...now
    static var last30Days: ClosedRange<Date> {
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        return start...now
    }

    /// This year range: startOfYear...endOfYear for today
    static var thisYear: ClosedRange<Date> {
        let now = Date()
        return now.startOfYear()...now.endOfYear()
    }

    /// Last year range: the full previous calendar year
    static var lastYear: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        let currentYearStart = now.startOfYear()
        let lastYearEnd = calendar.date(byAdding: .day, value: -1, to: currentYearStart) ?? now
        let lastYearStart = calendar.date(byAdding: .year, value: -1, to: currentYearStart) ?? currentYearStart
        return lastYearStart...lastYearEnd
    }
}

extension Date {
    /// A localized, short relative time string (e.g., "2h ago", "in 3d")
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

