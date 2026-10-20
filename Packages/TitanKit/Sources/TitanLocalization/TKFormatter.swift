import Foundation

/// Dates, numbers and money in the current language's style.
/// In-app purchase prices come from StoreKit's `displayPrice`, not from here.
public struct TKFormatter: Sendable {
    public let locale: Locale

    public init(locale: Locale) {
        self.locale = locale
    }

    public func date(
        _ date: Date,
        date dateStyle: Date.FormatStyle.DateStyle = .abbreviated,
        time timeStyle: Date.FormatStyle.TimeStyle = .omitted
    ) -> String {
        date.formatted(Date.FormatStyle(date: dateStyle, time: timeStyle, locale: locale))
    }

    public func number(_ value: Double, fractionDigits: Int = 0) -> String {
        value.formatted(.number.precision(.fractionLength(fractionDigits)).locale(locale))
    }

    /// `0.25` → "25%".
    public func percent(_ value: Double, fractionDigits: Int = 0) -> String {
        value.formatted(.percent.precision(.fractionLength(fractionDigits)).locale(locale))
    }

    public func currency(_ value: Decimal, code: String) -> String {
        value.formatted(.currency(code: code).locale(locale))
    }
}
