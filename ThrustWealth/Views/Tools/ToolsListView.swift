import SwiftUI

struct ToolsListView: View {
    @Environment(\.themed) private var themed
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                toolCard(
                    icon: "dollarsign.circle",
                    title: "P/L Calculator",
                    desc: "Calculate profit, loss, price delta, and return on notional by open and close prices.",
                    destination: AnyView(PLCalculatorView())
                )

                toolCard(
                    icon: "square.grid.2x2",
                    title: "Market Specs",
                    desc: "Search and inspect contract sizes, tick sizes, and pip values across all instruments.",
                    destination: AnyView(MarketSpecsView())
                )

                disabledToolCard(
                    icon: "function",
                    title: "Required Margin (V2.0)",
                    desc: "Determine exact required margin and free margin leverage requirements."
                )

                ComplianceDisclaimer(text: "For calculation purposes only. Not investment advice. Always manage trade risk prudently.")
                    .padding(.top, Theme.Spacing.xl)
            }
            .padding(Theme.Spacing.lg)
        }
        .background(ThemedColors.resolve(for: colorScheme).bgApp.ignoresSafeArea())
        .environment(\.themed, ThemedColors.resolve(for: colorScheme))
        .navigationTitle("Tools")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toolCard(icon: String, title: String, desc: String, destination: AnyView) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .fill(Theme.Colors.brandPrimary.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                .strokeBorder(Theme.Colors.brandPrimary.opacity(0.2), lineWidth: 1)
                        )
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(themed.accentText)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.Fonts.sans(16, weight: .bold))
                        .foregroundStyle(themed.textPrimary)
                    Text(desc)
                        .font(Theme.Fonts.sans(12.5))
                        .foregroundStyle(themed.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .foregroundStyle(themed.textMuted)
            }
            .padding(Theme.Spacing.lg)
            .background(
                LinearGradient(colors: [themed.bgSurfaceElevated, themed.bgSurface], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                    .strokeBorder(themed.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func disabledToolCard(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(themed.borderMedium)
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(themed.textMuted)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.Fonts.sans(16, weight: .bold))
                    .foregroundStyle(themed.textPrimary)
                Text(desc)
                    .font(Theme.Fonts.sans(12.5))
                    .foregroundStyle(themed.textSecondary)
            }
            Spacer()
        }
        .padding(Theme.Spacing.lg)
        .background(themed.bgSurface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                .strokeBorder(themed.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .opacity(0.6)
    }
}
