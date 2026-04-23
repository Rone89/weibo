import SwiftUI

struct BiliBackground<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.97, blue: 0.98),
                    Color(red: 0.99, green: 0.98, blue: 0.95),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            Group {
                Ellipse()
                    .fill(Color("AccentColor").opacity(0.08))
                    .frame(width: 360, height: 260)
                    .blur(radius: 44)
                    .offset(x: 190, y: -235)

                Ellipse()
                    .fill(Color.orange.opacity(0.06))
                    .frame(width: 280, height: 210)
                    .blur(radius: 54)
                    .offset(x: -190, y: 250)
            }
            .allowsHitTesting(false)

            content
        }
    }
}

struct BiliSectionHeader: View {
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?

    init(title: String, subtitle: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AccentColor"))
            }
        }
    }
}

struct BiliMetricPill: View {
    let text: String
    let systemImage: String
    var tint: Color = Color("AccentColor")

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tint.opacity(0.12))
            )
    }
}

struct BiliCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 10)
    }
}

private enum BiliActionButtonVariant {
    case primary
    case secondary
}

private struct BiliActionButtonModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    let variant: BiliActionButtonVariant
    let fillWidth: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(foregroundColor.opacity(isEnabled ? 1 : 0.7))
            .frame(maxWidth: fillWidth ? .infinity : nil)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(backgroundColor.opacity(isEnabled ? 1 : 0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(borderColor.opacity(isEnabled ? 1 : 0.55), lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.82)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return .white
        case .secondary:
            return Color("AccentColor")
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return Color("AccentColor")
        case .secondary:
            return Color(.secondarySystemBackground)
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary:
            return Color("AccentColor").opacity(0.18)
        case .secondary:
            return Color("AccentColor").opacity(0.16)
        }
    }
}

extension View {
    func biliCardStyle() -> some View {
        modifier(BiliCardModifier())
    }

    func biliPrimaryActionButton(fillWidth: Bool = true) -> some View {
        modifier(BiliActionButtonModifier(variant: .primary, fillWidth: fillWidth))
    }

    func biliSecondaryActionButton(fillWidth: Bool = true) -> some View {
        modifier(BiliActionButtonModifier(variant: .secondary, fillWidth: fillWidth))
    }
}
