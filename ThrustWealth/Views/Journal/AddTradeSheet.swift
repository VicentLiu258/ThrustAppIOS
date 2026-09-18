import SwiftUI

struct AddTradeSheet: View {
    var onSave: (TradeEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themed) private var themed
    @EnvironmentObject private var appState: AppState

    @State private var symbol = "XAUUSD"
    @State private var direction: TradeDirection = .long
    @State private var lots = "0.20"
    @State private var openPrice = "2350.00"
    @State private var closePrice = "2360.00"
    @State private var pnl = "200.00"
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    FormInputField(label: "Symbol", text: $symbol, keyboard: .default)

                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("DIRECTION")
                                .font(Theme.Fonts.sans(11.5, weight: .bold))
                                .foregroundStyle(themed.textTertiary)
                            ThrustSegmentedControl(
                                options: TradeDirection.allCases.map { ($0, $0.displayName) },
                                selection: $direction,
                                longShortStyle: true
                            )
                        }
                        FormInputField(label: "Lots", text: $lots)
                    }

                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        FormInputField(label: "Entry Price", text: $openPrice)
                        FormInputField(label: "Exit Price", text: $closePrice)
                    }

                    FormInputField(
                        label: "Realized P/L",
                        prefix: appState.preferences.currencySymbol,
                        text: $pnl
                    )

                    FormInputField(
                        label: "Trade Notes",
                        text: $note,
                        keyboard: .default
                    )

                    Button {
                        let trade = TradeEntry.make(
                            symbol: symbol.uppercased(),
                            direction: direction,
                            lots: Double(lots) ?? 0,
                            openPrice: Double(openPrice) ?? 0,
                            closePrice: Double(closePrice) ?? 0,
                            pnl: Double(pnl) ?? 0,
                            note: note
                        )
                        onSave(trade)
                        dismiss()
                    } label: {
                        Text("Save to Journal")
                            .font(Theme.Fonts.sans(14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Theme.Colors.brandPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(Theme.Spacing.lg)
            }
            .background(themed.bgApp)
            .navigationTitle("Log New Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .thrustTheme()
        .onChange(of: openPrice) { _, _ in autoCalcPnL() }
        .onChange(of: closePrice) { _, _ in autoCalcPnL() }
        .onChange(of: lots) { _, _ in autoCalcPnL() }
        .onChange(of: direction) { _, _ in autoCalcPnL() }
        .onChange(of: symbol) { _, _ in autoCalcPnL() }
    }

    private func autoCalcPnL() {
        let instruments = appState.instruments
        guard let inst = instruments.first(where: { $0.id == symbol.uppercased() }) else { return }
        let result = CalculatorEngine.calculateProfitLoss(
            instrument: inst,
            direction: direction,
            openPrice: Double(openPrice) ?? 0,
            closePrice: Double(closePrice) ?? 0,
            lotSize: Double(lots) ?? 0,
            accountCurrency: appState.preferences.accountCurrency
        )
        if result.isValid {
            pnl = String(format: "%.2f", result.profitAmount)
        }
    }
}
