import Foundation

/// How close what the user said is to the expected phrase, word by word.
///
///     let score = PronunciationScore(expected: "Encantado de conocerte", heard: "encantado de conocer")
///     score.percent   // 67
///     score.verdict   // .almostThere
public struct PronunciationScore: Sendable, Equatable {
    public enum Verdict: Sendable, Equatable {
        /// 90 % or more of the words.
        case perfect
        /// 60 % or more.
        case almostThere
        case tryAgain
        /// Nothing was heard.
        case notHeard

        public var isPass: Bool {
            self == .perfect || self == .almostThere
        }
    }

    /// One word of the expected phrase, as written, and whether the user said it.
    public struct Word: Sendable, Equatable {
        public let text: String
        public let isMatched: Bool
    }

    /// From 0 to 1.
    public let value: Double
    public let words: [Word]
    public let verdict: Verdict

    public init(expected: String, heard: String) {
        let written = expected.split(whereSeparator: \.isWhitespace).map(String.init)
        let spoken = Self.normalizedWords(heard)
        let matched = Self.matches(written.map(Self.normalized), spoken)
        words = zip(written, matched).map { Word(text: $0, isMatched: $1) }
        let total = words.filter { !Self.normalized($0.text).isEmpty }.count
        value = total == 0 ? 0 : Double(matched.filter { $0 }.count) / Double(total)
        if spoken.isEmpty {
            verdict = .notHeard
        } else if value >= 0.9 {
            verdict = .perfect
        } else if value >= 0.6 {
            verdict = .almostThere
        } else {
            verdict = .tryAgain
        }
    }

    /// 0 to 100, for "Almost there! (94%)".
    public var percent: Int {
        Int((value * 100).rounded())
    }

    /// Lowercased, without punctuation or accents, so "¡Hola!" matches "hola".
    static func normalized(_ word: String) -> String {
        word.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .filter { $0.isLetter || $0.isNumber }
    }

    static func normalizedWords(_ text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace).map { normalized(String($0)) }.filter { !$0.isEmpty }
    }

    /// Marks the expected words found in order in what was heard (longest common subsequence),
    /// so a skipped or extra word doesn't throw off the rest.
    static func matches(_ expected: [String], _ heard: [String]) -> [Bool] {
        let rows = expected.count, columns = heard.count
        var table = Array(repeating: Array(repeating: 0, count: columns + 1), count: rows + 1)
        for row in stride(from: rows - 1, through: 0, by: -1) {
            for column in stride(from: columns - 1, through: 0, by: -1) {
                table[row][column] = !expected[row].isEmpty && expected[row] == heard[column]
                    ? table[row + 1][column + 1] + 1
                    : max(table[row + 1][column], table[row][column + 1])
            }
        }
        var result = Array(repeating: false, count: rows)
        var row = 0, column = 0
        while row < rows, column < columns {
            if !expected[row].isEmpty, expected[row] == heard[column] {
                result[row] = true
                row += 1
                column += 1
            } else if table[row + 1][column] >= table[row][column + 1] {
                row += 1
            } else {
                column += 1
            }
        }
        return result
    }
}
