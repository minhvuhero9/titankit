import Foundation

public extension Collection {
    /// Returns nil instead of crashing when the index is out of range.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public extension String {
    /// True for an empty string or one made only of spaces and new lines.
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// nil when the string is blank, otherwise the trimmed string.
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

public extension Duration {
    /// The duration as seconds, for APIs that still take TimeInterval.
    var timeInterval: TimeInterval {
        let parts = components
        return TimeInterval(parts.seconds) + TimeInterval(parts.attoseconds) / 1e18
    }
}
