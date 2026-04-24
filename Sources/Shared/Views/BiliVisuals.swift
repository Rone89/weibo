import SwiftUI

struct BiliBackground<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color("AccentColor").opacity(colorScheme == .dark ? 0.16 : 0.12), .clear],
                center: .topLeading,
                startRadius: 12,
                endRadius: 260
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.orange.opacity(colorScheme == .dark ? 0.12 : 0.08), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 240
            )
            .ignoresSafeArea()

            content
        }
    }

    private var backgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.09, green: 0.10, blue: 0.14),
                Color(red: 0.08, green: 0.11, blue: 0.16),
                Color(red: 0.11, green: 0.10, blue: 0.13)
            ]
        }

        return [
            Color(red: 0.97, green: 0.96, blue: 0.98),
            Color(red: 0.93, green: 0.96, blue: 0.99),
            Color(red: 0.96, green: 0.96, blue: 0.95)
        ]
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
    var lightweight = false

    var body: some View {
        let orb = Image(systemName: systemImage)
            .symbolRenderingMode(.monochrome)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundColor(tint)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Color(.systemBackground).opacity(lightweight ? 0.96 : 0.78))
            )
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.05), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(lightweight ? 0.015 : 0.04), radius: lightweight ? 2 : 7, x: 0, y: lightweight ? 1 : 3)

        if lightweight {
            orb
        } else {
            orb.modifier(
                BiliGlassSurfaceModifier(
                    cornerRadius: size / 2,
                    tint: tint,
                    interactive: true
                )
            )
        }
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
                quickActionIcon

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
        .biliListCardStyle(tint: tint, interactive: true)
    }

    private var quickActionIcon: some View {
        Image(systemName: systemImage)
            .symbolRenderingMode(.monochrome)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(tint)
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(Color(.secondarySystemBackground).opacity(0.96))
            )
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.05), lineWidth: 0.8)
            )
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
                .shadow(color: Color.black.opacity(shadowOpacity * 0.8), radius: 7, x: 0, y: 4)
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
                .shadow(color: Color.black.opacity(shadowOpacity * 0.8), radius: 7, x: 0, y: 4)
        }
    }
}

struct BiliListCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let interactive: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.86))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(tint.opacity(0.08), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(interactive ? 0.03 : 0.015), radius: 3, x: 0, y: 2)
    }
}

struct BiliHeroCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let shadowOpacity: Double

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(tint.opacity(0.12), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(shadowOpacity * 0.85), radius: 6, x: 0, y: 3)
    }
}

struct BiliPanelCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let interactive: Bool
    let shadowOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(tint.opacity(0.1), lineWidth: 0.9)
            )
            .shadow(color: Color.black.opacity(shadowOpacity * 0.72), radius: 6, x: 0, y: 3)
            .opacity(interactive ? 1 : 0.98)
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
            return Color("AccentColor").opacity(0.1)
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

    func biliPanelCardStyle(
        cornerRadius: CGFloat = 28,
        tint: Color = .white,
        interactive: Bool = false,
        shadowOpacity: Double = 0.08
    ) -> some View {
        modifier(
            BiliPanelCardModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                interactive: interactive,
                shadowOpacity: shadowOpacity
            )
        )
    }

    func biliListCardStyle(
        cornerRadius: CGFloat = 24,
        tint: Color = Color("AccentColor"),
        interactive: Bool = false
    ) -> some View {
        modifier(
            BiliListCardModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                interactive: interactive
            )
        )
    }

    func biliHeroCardStyle(
        cornerRadius: CGFloat = 28,
        tint: Color = Color("AccentColor"),
        shadowOpacity: Double = 0.06
    ) -> some View {
        modifier(
            BiliHeroCardModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                shadowOpacity: shadowOpacity
            )
        )
    }
}
