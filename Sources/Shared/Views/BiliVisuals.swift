import SwiftUI

struct BiliBackground<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.96, blue: 0.98),
                    Color(red: 0.93, green: 0.96, blue: 0.99),
                    Color(red: 0.96, green: 0.96, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color("AccentColor").opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
                .offset(x: -150, y: -250)

            Circle()
                .fill(Color.orange.opacity(0.08))
                .frame(width: 240, height: 240)
                .blur(radius: 34)
                .offset(x: 160, y: -160)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(width: 360, height: 160)
                .blur(radius: 28)
                .offset(x: 100, y: 320)

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
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 12)

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
    var foreground: Color = .primary

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tint.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.05), lineWidth: 0.8)
            )
    }
}

struct BiliGlassGroup<Content: View>: View {
    let spacing: CGFloat
    private let content: Content

    init(spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

struct BiliSymbolOrb: View {
    let systemImage: String
    var tint: Color = Color("AccentColor")
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Color(.systemBackground).opacity(0.72))
            )
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.05), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .modifier(BiliGlassSurfaceModifier(cornerRadius: size / 2, tint: tint, interactive: true))
    }
}

struct BiliQuickActionTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = Color("AccentColor")
    var badge: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                BiliSymbolOrb(systemImage: systemImage, tint: tint)

                Spacer(minLength: 8)

                if let badge, !badge.isEmpty {
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(tint.opacity(0.12), in: Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .biliCardStyle(tint: tint.opacity(0.5), interactive: true)
    }
}

private struct BiliGlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                content
                    .glassEffect(.regular.tint(tint.opacity(0.08)).interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                content
                    .glassEffect(.regular.tint(tint.opacity(0.08)), in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            content
        }
    }
}

struct BiliCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let interactive: Bool
    let shadowOpacity: Double

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(Color(.systemBackground).opacity(0.001))
                .modifier(BiliGlassSurfaceModifier(cornerRadius: cornerRadius, tint: tint, interactive: interactive))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(shadowOpacity * 0.9), radius: 14, x: 0, y: 8)
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(.systemBackground).opacity(0.78))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(shadowOpacity * 0.9), radius: 14, x: 0, y: 8)
        }
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
            .modifier(
                BiliGlassSurfaceModifier(
                    cornerRadius: 16,
                    tint: variant == .primary ? Color("AccentColor") : .white,
                    interactive: true
                )
            )
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
    func biliCardStyle(
        cornerRadius: CGFloat = 28,
        tint: Color = .white,
        interactive: Bool = false,
        shadowOpacity: Double = 0.08
    ) -> some View {
        modifier(
            BiliCardModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                interactive: interactive,
                shadowOpacity: shadowOpacity
            )
        )
    }

    func biliPrimaryActionButton(fillWidth: Bool = true) -> some View {
        modifier(BiliActionButtonModifier(variant: .primary, fillWidth: fillWidth))
    }

    func biliSecondaryActionButton(fillWidth: Bool = true) -> some View {
        modifier(BiliActionButtonModifier(variant: .secondary, fillWidth: fillWidth))
    }
}
