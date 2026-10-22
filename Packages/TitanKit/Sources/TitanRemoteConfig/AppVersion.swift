import Foundation

/// A dotted version such as "1.10.2". Missing parts count as zero, so "2.0" equals "2.0.0".
public struct AppVersion: Comparable, Sendable, CustomStringConvertible {
    public let parts: [Int]

    /// nil for anything that isn't numbers separated by dots.
    public init?(_ string: String) {
        let pieces = string.trimmingCharacters(in: .whitespaces).split(separator: ".", omittingEmptySubsequences: false)
        let numbers = pieces.compactMap { Int($0) }
        guard !pieces.isEmpty, numbers.count == pieces.count, numbers.allSatisfy({ $0 >= 0 }) else { return nil }
        parts = numbers
    }

    public var description: String { parts.map(String.init).joined(separator: ".") }

    public static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        compare(lhs, rhs) == 0
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        compare(lhs, rhs) < 0
    }

    private static func compare(_ lhs: AppVersion, _ rhs: AppVersion) -> Int {
        for index in 0..<max(lhs.parts.count, rhs.parts.count) {
            let left = index < lhs.parts.count ? lhs.parts[index] : 0
            let right = index < rhs.parts.count ? rhs.parts[index] : 0
            if left != right { return left < right ? -1 : 1 }
        }
        return 0
    }
}
