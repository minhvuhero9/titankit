import SwiftUI
import TitanIcons

/// Figma "Avatar": a round profile picture with an optional status badge.
/// Without a picture it shows the person's initials on the brand tint.
///
///     TKAvatar(image: Image("me"), badge: .online)
///     TKAvatar(name: "Nguyễn Văn An", size: 64, badge: .edit)
public struct TKAvatar: View {
    public enum Badge: String, CaseIterable, Sendable {
        /// Brand dot, bottom right.
        case online
        /// Grey dot, bottom right.
        case offline
        /// Edit icon, bottom right, for the user's own profile picture.
        case edit
        /// Red ring with a "LIVE" tag under the picture.
        case live
    }

    private let image: Image?
    private let name: String?
    private let size: CGFloat
    private let badge: Badge?

    @Environment(\.theme) private var theme

    /// - Parameters:
    ///   - image: the picture. nil shows the initials of `name`, or a profile icon.
    ///   - name: used for the initials and read out by VoiceOver.
    ///   - size: diameter in points. Figma's avatar is 48.
    public init(image: Image? = nil, name: String? = nil, size: CGFloat = 48, badge: Badge? = nil) {
        self.image = image
        self.name = name
        self.size = size
        self.badge = badge
    }

    public var body: some View {
        picture
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay {
                if badge == .live {
                    Circle()
                        .strokeBorder(theme.colors.feedbackError.color, lineWidth: max(2, size / 24))
                        .padding(-max(2, size / 24))
                }
            }
            .overlay(alignment: badge == .live ? Alignment.bottom : Alignment.bottomTrailing) { badgeView }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(name.map { Text($0) } ?? Text(""))
    }

    @ViewBuilder
    private var picture: some View {
        if let image {
            image.resizable().scaledToFill()
        } else if let name, !Self.initials(from: name).isEmpty {
            Text(Self.initials(from: name))
                .font(theme.typography.font(size: size * 0.4, weight: .bold, relativeTo: .headline))
                .minimumScaleFactor(0.5)
                .foregroundStyle(theme.colors.actionOnSecondary.color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.colors.actionSecondary.color)
        } else {
            Image(tk: TKIcon.profile, style: .bold)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .padding(size * 0.25)
                .foregroundStyle(theme.colors.actionOnSecondary.color)
                .background(theme.colors.actionSecondary.color)
        }
    }

    @ViewBuilder
    private var badgeView: some View {
        let dot = size / 4
        switch badge {
        case .online, .offline:
            Circle()
                .fill((badge == .online ? theme.colors.actionPrimary : theme.colors.textDisabled).color)
                .frame(width: dot, height: dot)
                .overlay { Circle().strokeBorder(theme.colors.surfaceBackground.color, lineWidth: max(1, dot / 7.5)) }
        case .edit:
            Image(tk: TKIcon.editSquare, style: .bold)
                .renderingMode(.template)
                .resizable()
                .frame(width: dot, height: dot)
                .foregroundStyle(theme.colors.actionPrimary.color)
                .background(theme.colors.surfaceBackground.color, in: RoundedRectangle(cornerRadius: dot / 4))
        case .live:
            TKTag(title: Text(verbatim: "LIVE"), tone: .error, style: .solid, size: .small)
                .fixedSize()
                .offset(y: size / 4)
        case nil:
            EmptyView()
        }
    }

    /// First letters of the first and last word, e.g. "Nguyễn Văn An" → "NA".
    nonisolated static func initials(from name: String) -> String {
        let words = name.split(whereSeparator: \.isWhitespace)
        let letters = [words.first, words.count > 1 ? words.last : nil].compactMap { $0?.first }
        return String(letters).uppercased()
    }
}
