import SwiftUI

struct TradeJournalView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = JournalViewModel()
    @Environment(\.themed) private var themed
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    JournalSummaryGrid(stats: vm.stats, currency: appState.preferences.accountCurrency)

                    HStack {
                        Text("LOGGED TRADES")
                            .font(Theme.Fonts.sans(11, weight: .heavy))
                            .tracking(0.7)
                            .foregroundStyle(themed.textMuted)
                        Spacer()
                        Text("Local Storage")
                            .font(Theme.Fonts.sans(11))
                            .foregroundStyle(themed.textMuted)
                    }

                    if vm.trades.isEmpty {
                        EmptyStateView(
                            systemImage: "book.closed",
                            title: "No trades yet",
                            description: "Log your first trade to see performance stats.",
                            assetName: "EmptyJournal"
                        )
                    } else {
                        ForEach(vm.trades) { trade in
                            tradeRow(trade)
                        }
                    }

                    ComplianceDisclaimer(text: "All trade logs are stored locally on this device. Export available in CSV.")
                }
                .padding(Theme.Spacing.lg)
            }

            if vm.showClearConfirm {
                ConfirmDialog(
                    title: "Clear All Trades?",
                    message: "This will permanently delete all journal entries on this device.",
                    confirmTitle: "Clear All",
                    isDestructive: true,
                    onConfirm: {
                        vm.clearAll()
                        vm.showClearConfirm = false
                    },
                    onCancel: { vm.showClearConfirm = false }
                )
            }

            if let toast = vm.toastMessage {
                VStack {
                    ToastBanner(message: toast).padding(.top, 12)
                    Spacer()
                }
            }
        }
        .background(ThemedColors.resolve(for: colorScheme).bgApp.ignoresSafeArea())
        .environment(\.themed, ThemedColors.resolve(for: colorScheme))
        .navigationTitle("Trade Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { vm.showAddTrade = true } label: { Image(systemName: "plus") }
                Button { vm.exportCSV() } label: { Image(systemName: "square.and.arrow.up") }
                Button { vm.showClearConfirm = true } label: { Image(systemName: "trash") }
            }
        }
        .sheet(isPresented: $vm.showAddTrade) {
            AddTradeSheet { trade in
                vm.addTrade(trade)
            }
            .environmentObject(appState)
        }
        .onAppear { vm.load() }
    }

    private func tradeRow(_ trade: TradeEntry) -> some View {
        HStack {
            HStack(spacing: Theme.Spacing.md) {
                Text(trade.tradeDirection.displayName.uppercased())
                    .font(Theme.Fonts.sans(10, weight: .heavy))
                    .tracking(0.5)
                    .foregroundStyle(trade.tradeDirection == .long ? Theme.Colors.profit : Theme.Colors.loss)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        (trade.tradeDirection == .long ? Theme.Colors.profit : Theme.Colors.loss).opacity(0.15)
                    )
                    .overlay(
                        Capsule().strokeBorder(
                            trade.tradeDirection == .long ? Theme.Colors.profitBorder : Theme.Colors.lossBorder,
                            lineWidth: 1
                        )
                    )
                    .clipShape(Capsule())

                VStack(alignment: .leading, spacing: 2) {
                    Text(trade.symbol)
                        .font(Theme.Fonts.mono(14.5, weight: .bold))
                        .foregroundStyle(themed.textPrimary)
                    Text(trade.date)
                        .font(Theme.Fonts.sans(11))
                        .foregroundStyle(themed.textMuted)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.money(trade.pnl, currency: appState.preferences.accountCurrency, signed: true))
                    .font(Theme.Fonts.mono(15, weight: .heavy))
                    .foregroundStyle(trade.isProfit ? Theme.Colors.profit : Theme.Colors.loss)
                Text("\(Formatters.lots(trade.lots)) lots")
                    .font(Theme.Fonts.mono(11.5))
                    .foregroundStyle(themed.textMuted)
            }

            Button {
                vm.deleteTrade(id: trade.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(themed.textMuted)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete trade")
        }
        .padding(Theme.Spacing.md)
        .background(
            LinearGradient(colors: [themed.bgSurfaceElevated, themed.bgSurface], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(themed.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
    }
}
