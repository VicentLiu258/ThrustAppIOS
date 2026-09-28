import SwiftUI

struct ResultShowcaseCard: View {
    let heroTitle: String
    let heroValue: String
    var heroSub: String? = nil
    var heroColor: Color? = nil
    let badge: String
    let stats: [(String, String, Color?)]
    var isValid: Bool = true
    var onReset: (() -> Void)? = nil
    var onExport: (() -> Void)? = nil
    var onPrimary: (() -> Void)? = nil
    var primaryTitle: String = "Save Record"
    var primarySystemImage: String = "bookmark"

    @Environment(\.themed) private var themed

    private func statCell(_ stat: (String, String, Color?)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stat.0.uppercased())
                .font(Theme.Fonts.sans(10.5, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(themed.textMuted)
            Text(stat.1)
                .font(Theme.Fonts.mono(15, weight: .heavy))
                .foregroundStyle(stat.2 ?? themed.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .strokeBorder(themed.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(badge.uppercased())
                    .font(Theme.Fonts.sans(10.5, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.brandPrimary)
                    .clipShape(Capsule())
                Spacer()
                Text("Live Update")
                    .font(Theme.Fonts.sans(11))
                    .foregroundStyle(themed.textMuted)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(heroTitle.uppercased())
                    .font(Theme.Fonts.sans(11, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(themed.textTertiary)
                    .padding(.top, Theme.Spacing.sm)

                Text(heroValue)
                    .font(Theme.Fonts.mono(42, weight: .heavy))
                    .foregroundStyle(isValid ? (heroColor ?? themed.textPrimary) : themed.textMuted)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .opacity(isValid ? 1 : 0.45)

                if let heroSub {
                    Text(heroSub)
                        .font(Theme.Fonts.mono(13))
                        .foregroundStyle(themed.textTertiary)
                }
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, themed.borderSubtle, themed.borderSubtle, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.vertical, Theme.Spacing.sm)

            VStack(spacing: Theme.Spacing.sm) {
                let pairCount = stats.count / 2
                ForEach(0..<pairCount, id: \.self) { row in
                    HStack(spacing: Theme.Spacing.sm) {
                        statCell(stats[row * 2])
                        statCell(stats[row * 2 + 1])
                    }
                }
                if stats.count % 2 == 1, let last = stats.last {
                    statCell(last)
                }
            }
            .opacity(isValid ? 1 : 0.45)

            if onReset != nil || onExport != nil || onPrimary != nil {
                HStack(spacing: Theme.Spacing.sm) {
                    if let onReset {
                        actionButton(title: "Reset", systemImage: "trash", style: .danger, action: onReset)
                    }
                    if let onExport {
                        actionButton(title: "Export CSV", systemImage: "square.and.arrow.up", style: .outline, action: onExport)
                    }
                    if let onPrimary {
                        actionButton(title: primaryTitle, systemImage: primarySystemImage, style: .primary, action: onPrimary)
                    }
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [themed.bgSurfaceElevated, themed.bgSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.Colors.brandPrimary)
                .frame(height: 3)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                .strokeBorder(themed.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 2, y: 1)
    }

    private enum BtnStyle { case primary, outline, danger }

    private func actionButton(title: String, systemImage: String, style: BtnStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(Theme.Fonts.sans(12.5, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(foreground(for: style))
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(background(for: style))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(border(for: style), lineWidth: style == .primary ? 0 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func foreground(for style: BtnStyle) -> Color {
        switch style {
        case .primary: return .white
        case .outline: return themed.textPrimary
        case .danger: return themed.textTertiary
        }
    }

    private func background(for style: BtnStyle) -> Color {
        switch style {
        case .primary: return Theme.Colors.brandPrimary
        case .outline: return themed.bgSurfaceElevated
        case .danger: return .clear
        }
    }

    private func border(for style: BtnStyle) -> Color {
        switch style {
        case .primary: return .clear
        default: return themed.borderMedium
        }
    }
}
