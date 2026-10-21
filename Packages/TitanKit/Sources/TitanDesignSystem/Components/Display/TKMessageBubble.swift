import SwiftUI
import TitanIcons

/// Figma "Message": a chat bubble. Incoming bubbles sit on the left in grey, with the sender's
/// name in group chats; outgoing ones sit on the right in the brand colour with a read tick.
///
///     TKMessageBubble("Chào bạn!", time: "09:41", direction: .incoming, sender: "Anna")
///     TKMessageBubble("Mình đây", time: "09:42", direction: .outgoing, status: .read)
public struct TKMessageBubble: View {
    public enum Direction: String, CaseIterable, Sendable {
        case incoming, outgoing
    }

    /// Delivery state of an outgoing message.
    public enum Status: String, CaseIterable, Sendable {
        case sent, read
    }

    private let text: Text
    private let time: Text?
    private let direction: Direction
    private let sender: Text?
    private let status: Status?

    @Environment(\.theme) private var theme

    /// - Parameters:
    ///   - sender: shown above the text of incoming bubbles, for group chats.
    ///   - status: tick shown after the time of outgoing bubbles.
    public init(
        _ text: String,
        time: String? = nil,
        direction: Direction,
        sender: String? = nil,
        status: Status? = nil
    ) {
        self.init(text: Text(text), time: time.map { Text($0) }, direction: direction,
                  sender: sender.map { Text($0) }, status: status)
    }

    public init(text: Text, time: Text? = nil, direction: Direction, sender: Text? = nil, status: Status? = nil) {
        self.text = text
        self.time = time
        self.direction = direction
        self.sender = sender
        self.status = status
    }

    private var isOutgoing: Bool { direction == .outgoing }

    public var body: some View {
        let shape = TKBubbleShape(tailOnTrailing: isOutgoing)
        let foreground = isOutgoing ? theme.colors.actionOnPrimary : theme.colors.textPrimary
        VStack(alignment: .leading, spacing: 6) {
            if !isOutgoing, let sender {
                sender
                    .font(theme.typography.font(size: 14, weight: .semibold, relativeTo: .caption))
                    .foregroundStyle(theme.colors.actionPrimary.color)
            }
            HStack(alignment: .lastTextBaseline, spacing: Spacing.sm) {
                text
                    .font(theme.typography.font(size: 18, weight: .regular, relativeTo: .body))
                    .foregroundStyle(foreground.color)
                    .fixedSize(horizontal: false, vertical: true)
                if time != nil || (isOutgoing && status != nil) {
                    HStack(spacing: 6) {
                        time?
                            .font(theme.typography.font(size: 12, weight: .medium, relativeTo: .caption))
                        if isOutgoing, let status {
                            Image(tk: status == .read ? TKSymbol.doubleCheck : TKSymbol.check)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 16, height: 16)
                                .accessibilityHidden(true)
                        }
                    }
                    .foregroundStyle((isOutgoing ? theme.colors.actionOnPrimary : theme.colors.textSecondary).color)
                }
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background {
            if isOutgoing {
                // Darker bottom edge, like the 3D button.
                ZStack {
                    shape.fill(theme.colors.actionPrimaryPressed.color).offset(y: 3)
                    shape.fill(theme.colors.actionPrimary.color)
                }
            } else {
                shape.fill(theme.colors.surfaceInput.color)
            }
        }
        .padding(.bottom, isOutgoing ? 3 : 0)
        .accessibilityElement(children: .combine)
        .padding(isOutgoing ? .leading : .trailing, Spacing.xxl)
        .frame(maxWidth: .infinity, alignment: isOutgoing ? .trailing : .leading)
    }
}

/// Rounded rectangle with a smaller corner at the top on the speaker's side.
/// (`UnevenRoundedRectangle` needs iOS 17.)
struct TKBubbleShape: Shape {
    var tailOnTrailing: Bool
    var radius: CGFloat = 8
    var tailRadius: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        let topLeft = tailOnTrailing ? radius : tailRadius
        let topRight = tailOnTrailing ? tailRadius : radius
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                    tangent2End: CGPoint(x: rect.maxX, y: rect.minY + topRight), radius: topRight)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                    tangent2End: CGPoint(x: rect.maxX - radius, y: rect.maxY), radius: radius)
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                    tangent2End: CGPoint(x: rect.minX, y: rect.maxY - radius), radius: radius)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                    tangent2End: CGPoint(x: rect.minX + topLeft, y: rect.minY), radius: topLeft)
        path.closeSubpath()
        return path
    }
}
