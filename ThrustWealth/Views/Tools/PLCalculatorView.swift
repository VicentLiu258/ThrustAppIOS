import SwiftUI

struct PLCalculatorView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = PLCalculatorViewModel()
    @Environment(\.themed) private var themed
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSymbolPicker = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    FormDropdownField(
                        label: "Instrument",
                        hint: vm.currentInstrument.map { "Contract: \($0.contractHint)" },
                        value: vm.currentInstrument.map { "\($0.id) — \($0.name)" } ?? vm.symbolID
                    ) {
                        showSymbolPicker = true
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("DIRECTION")
                            .font(Theme.Fonts.sans(11.5, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(themed.textTertiary)
                        ThrustSegmentedControl(
                            options: TradeDirection.allCases.map { ($0, $0.displayNameFull) },
                            selection: $vm.direction,
                            longShortStyle: true
                        )
                    }

                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        FormInputField(label: "Entry Price", text: $vm.openPriceText)
                        FormInputField(label: "Exit Price", text: $vm.closePriceText)
                    }

                    FormInputField(
                        label: "Position Size (Lots)",
                        suffix: "lots",
                        text: $vm.lotsText
                    )

                    let r = vm.result
                    let color: Color? = r.isValid ? (r.isProfit ? Theme.Colors.profit : Theme.Colors.loss) : nil
                    let distanceText: String = {
                        guard r.isValid else { return "—" }
                        let pipSign = r.profitPips >= 0 ? "+" : ""
                        let deltaSign = r.priceDelta >= 0 ? "+" : ""
                        return "\(pipSign)\(r.profitPips) pips (\(deltaSign)\(r.priceDelta))"
                    }()
                    let returnText: String = {
                        guard r.isValid else { return "—" }
                        let sign = r.returnPercent >= 0 ? "+" : ""
                        return "\(sign)\(String(format: "%.2f", r.returnPercent))%"
                    }()

                    ResultShowcaseCard(
                        heroTitle: "Profit / Loss",
                        heroValue: r.isValid ? Formatters.money(r.profitAmount, currency: vm.currency, signed: true) : "—",
                        heroColor: color,
                        badge: "Calculated P/L",
                        stats: [
                            ("Price Distance", distanceText, color),
                            ("Return on Notional", returnText, color)
                        ],
                        isValid: r.isValid,
                        onReset: { vm.reset() },
                        onExport: { vm.exportCSV() },
                        onPrimary: { vm.saveToJournal() },
                        primaryTitle: "Save to Journal",
                        primarySystemImage: "plus"
                    )

                    ComplianceDisclaimer(text: "For calculation purposes only. Not investment advice. Calculation assumes zero slippage and benchmark spreads.")
                }
                .padding(Theme.Spacing.lg)
            }

            if let toast = vm.toastMessage {
                VStack {
                    ToastBanner(message: toast)
                        .padding(.top, 12)
                    Spacer()
                }
            }
        }
        .background(ThemedColors.resolve(for: colorScheme).bgApp.ignoresSafeArea())
        .environment(\.themed, ThemedColors.resolve(for: colorScheme))
        .navigationTitle("P/L Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { vm.reset() } label: { Image(systemName: "trash") }
                Button { vm.exportCSV() } label: { Image(systemName: "square.and.arrow.up") }
                Button { vm.saveToJournal() } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showSymbolPicker) {
            SymbolPickerSheet(
                instruments: vm.instruments,
                selectedID: vm.symbolID,
                onSelect: vm.selectSymbol
            )
        }
        .onAppear { vm.bind(appState: appState) }
    }
}
