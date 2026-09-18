import SwiftUI

struct JournalSummaryGrid: View {
    let stats: JournalStats
    var currency: String = "USD"

    @Environment(\.themed) private var themed

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
            summaryCard(
                title: "Net P/L",
                value: Formatters.money(stats.netPnl, currency: currency, signed: true),
                valueColor: stats.netPnl >= 0 ? Theme.Colors.profit : Theme.Colors.loss,
                accent: Theme.Colors.profit
            )
            summaryCard(
                title: "Win Rate",
                value: "\(stats.winRate)%",
                valueColor: themed.textPrimary,
                accent: Theme.Colors.brandPrimary
            )
            summaryCard(
                title: "Avg R:R Ratio",
                value: stats.avgRR,
                valueColor: themed.textPrimary,
                accent: Theme.Colors.brandPrimary
            )
            summaryCard(
                title: "Max Drawdown",
                value: Formatters.money(stats.maxDrawdown, currency: currency),
                valueColor: themed.textPrimary,
                accent: Theme.Colors.warn
            )
        }
    }

    private func summaryCard(title: String, value: String, valueColor: Color, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(Theme.Fonts.sans(10.5, weight: .heavy))
                .tracking(0.7)
                .foregroundStyle(themed.textMuted)
            Text(value)
                .font(Theme.Fonts.mono(24, weight: .heavy))
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [themed.bgSurfaceElevated, themed.bgSurface], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(alignment: .top) {
            Rectangle().fill(accent).frame(height: 3)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .strokeBorder(themed.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
    }
}
