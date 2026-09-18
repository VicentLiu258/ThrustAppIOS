import SwiftUI

struct SpecDetailSheet: View {
    let instrument: Instrument
    var currency: String = "USD"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themed) private var themed

    private var pipValue: Double {
        CalculatorEngine.calculatePipValue(instrument: instrument, accountCurrency: currency)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    detailRow("Symbol", instrument.id)
                    detailRow("Name", instrument.name)
                    detailRow("Category", instrument.category)
                    detailRow("Contract Size", "\(instrument.contractSize.formatted()) \(instrument.unit)")
                    detailRow("Pip Size", "\(instrument.pipSize)")
                    detailRow("Tick Size", "\(instrument.tickSize)")
                    detailRow("Digits", "\(instrument.digits)")
                    detailRow("Pip Value (1 lot)", Formatters.money(pipValue, currency: currency) + " / pip")
                    detailRow("Quote Currency", instrument.quoteCurrency)
                    detailRow("Default Price", Formatters.price(instrument.defaultPrice, digits: instrument.digits))
                    detailRow("Lot Conversions", "1 Std = 10 Mini = 100 Micro")

                    Text("Built-in specs are industry default references. Actual contract specifications may vary by broker.")
                        .font(Theme.Fonts.sans(12))
                        .foregroundStyle(themed.textTertiary)
                        .padding(.top, Theme.Spacing.md)
                }
                .padding(Theme.Spacing.lg)
            }
            .background(themed.bgApp)
            .navigationTitle(instrument.id)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .thrustTheme()
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Fonts.sans(14, weight: .semibold))
                .foregroundStyle(themed.textSecondary)
            Spacer()
            Text(value)
                .font(Theme.Fonts.mono(14, weight: .bold))
                .foregroundStyle(themed.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(themed.borderSubtle).frame(height: 1)
        }
    }
}
