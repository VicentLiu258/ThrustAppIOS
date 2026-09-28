import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published var mode: CalculatorMode = .byRisk
    @Published var symbolID: String = "XAUUSD"
    @Published var balanceText: String = "10000"
    @Published var riskPercentText: String = "1.0"
    @Published var riskAmountText: String = "100.00"
    @Published var lotSizeText: String = "0.20"
    @Published var stopPipsText: String = "50"
    @Published var entryPriceText: String = "2350.00"
    @Published var direction: TradeDirection = .long
    @Published var selectedPreset: Double = 1.0
    @Published var result: LotSizeResult = .invalid
    @Published var toastMessage: String?
    @Published var searchText: String = ""
    @Published var isUpdatingFields = false

    private var cancellables = Set<AnyCancellable>()
    private weak var appState: AppState?
    private var syncingRisk = false

    var instruments: [Instrument] {
        appState?.instruments ?? Instrument.defaults
    }

    var currentInstrument: Instrument? {
        instruments.first { $0.id == symbolID }
    }

    var currency: String {
        appState?.preferences.accountCurrency ?? "USD"
    }

    var currencySymbol: String {
        appState?.preferences.currencySymbol ?? "$"
    }

    var quickSymbols: [String] {
        let favs = instruments.filter(\.isFavorite).map(\.id)
        if favs.count >= 4 { return favs }
        return Array((favs + instruments.map(\.id)).uniqued().prefix(8))
    }

    var searchHits: [(title: String, desc: String, route: String)] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        let tools: [(String, String, String)] = [
            ("P/L Calculator", "Profit / loss by open & close", "pnl"),
            ("Market Specs", "Contract size & pip value", "specs"),
            ("Trade Journal", "Local trade log & stats", "journal"),
            ("Lot Size Calculator", "Risk → position sizing", "calc")
        ]
        var hits = tools.filter { $0.0.lowercased().contains(q) || $0.1.lowercased().contains(q) }
            .map { (title: $0.0, desc: $0.1, route: $0.2) }

        hits.append((title: "Search \"\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\"", desc: "Search and jump", route: "jump_search"))
        return hits
    }

    func bind(appState: AppState) {
        self.appState = appState
        symbolID = appState.preferences.defaultSymbol
        if let inst = currentInstrument {
            entryPriceText = Formatters.price(inst.defaultPrice, digits: inst.digits)
        }
        setupDebouncedRecalc()
        recalc()
    }

    private func setupDebouncedRecalc() {
        Publishers.MergeMany(
            $balanceText.map { _ in () }.eraseToAnyPublisher(),
            $riskPercentText.map { _ in () }.eraseToAnyPublisher(),
            $riskAmountText.map { _ in () }.eraseToAnyPublisher(),
            $lotSizeText.map { _ in () }.eraseToAnyPublisher(),
            $stopPipsText.map { _ in () }.eraseToAnyPublisher(),
            $entryPriceText.map { _ in () }.eraseToAnyPublisher(),
            $mode.map { _ in () }.eraseToAnyPublisher(),
            $direction.map { _ in () }.eraseToAnyPublisher(),
            $symbolID.map { _ in () }.eraseToAnyPublisher()
        )
        .debounce(for: .milliseconds(280), scheduler: RunLoop.main)
        .sink { [weak self] in self?.recalc() }
        .store(in: &cancellables)
    }

    func selectSymbol(_ id: String) {
        symbolID = id
        if let inst = instruments.first(where: { $0.id == id }) {
            entryPriceText = Formatters.price(inst.defaultPrice, digits: inst.digits)
        }
    }

    func applyPreset(_ value: Double) {
        selectedPreset = value
        riskPercentText = String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", value)
        syncRiskAmountFromPercent()
    }

    func syncRiskAmountFromPercent() {
        guard !syncingRisk else { return }
        syncingRisk = true
        let balance = Double(balanceText.replacingOccurrences(of: ",", with: "")) ?? 0
        let pct = Double(riskPercentText) ?? 0
        riskAmountText = String(format: "%.2f", balance * pct / 100)
        selectedPreset = pct
        syncingRisk = false
    }

    func syncRiskPercentFromAmount() {
        guard !syncingRisk else { return }
        syncingRisk = true
        let balance = Double(balanceText.replacingOccurrences(of: ",", with: "")) ?? 0
        let amount = Double(riskAmountText) ?? 0
        if balance > 0 {
            let pct = amount / balance * 100
            riskPercentText = String(format: "%.2f", pct)
            selectedPreset = pct
        }
        syncingRisk = false
    }

    func recalc() {
        let balance = Double(balanceText.replacingOccurrences(of: ",", with: "")) ?? 0
        let stop = Double(stopPipsText) ?? 0
        let entry = Double(entryPriceText.replacingOccurrences(of: ",", with: "")) ?? 0

        switch mode {
        case .byRisk:
            let pct = Double(riskPercentText) ?? 0
            result = CalculatorEngine.calculateLotSize(
                balance: balance,
                riskPercent: pct,
                stopPips: stop,
                instrument: currentInstrument,
                entryPrice: entry,
                direction: direction,
                accountCurrency: currency
            )
        case .byLots:
            let lots = Double(lotSizeText) ?? 0
            result = CalculatorEngine.calculateRiskFromLots(
                balance: balance,
                lotSize: lots,
                stopPips: stop,
                instrument: currentInstrument,
                entryPrice: entry,
                direction: direction,
                accountCurrency: currency
            )
        }
    }

    func reset() {
        mode = .byRisk
        balanceText = "10000"
        riskPercentText = "1.0"
        riskAmountText = "100.00"
        lotSizeText = "0.20"
        stopPipsText = "50"
        direction = .long
        selectedPreset = 1.0
        if let inst = currentInstrument {
            entryPriceText = Formatters.price(inst.defaultPrice, digits: inst.digits)
        }
        recalc()
        showToast("Calculator reset")
    }

    func saveRecord() {
        guard result.isValid, let symbol = currentInstrument?.id else {
            showToast("Nothing to save")
            return
        }
        let record = CalculationRecord.make(
            symbol: symbol,
            mode: mode,
            balance: Double(balanceText) ?? 0,
            riskPercent: result.riskPercent,
            riskAmount: result.riskAmount,
            stopPips: Double(stopPipsText) ?? 0,
            entryPrice: Double(entryPriceText) ?? 0,
            direction: direction,
            lotSize: result.suggestedLots,
            suggestedLots: result.suggestedLots,
            pipValue: result.pipValue,
            notionalValue: result.notionalValue,
            stopLossPrice: result.stopLossPrice
        )
        StorageService.shared.saveCalculation(record)
        showToast("Saved to history")
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func exportCurrent() {
        guard result.isValid else {
            showToast("Nothing to export")
            return
        }
        let record = CalculationRecord.make(
            symbol: symbolID,
            mode: mode,
            balance: Double(balanceText) ?? 0,
            riskPercent: result.riskPercent,
            riskAmount: result.riskAmount,
            stopPips: Double(stopPipsText) ?? 0,
            entryPrice: Double(entryPriceText) ?? 0,
            direction: direction,
            lotSize: result.suggestedLots,
            suggestedLots: result.suggestedLots,
            pipValue: result.pipValue,
            notionalValue: result.notionalValue,
            stopLossPrice: result.stopLossPrice
        )
        if let url = ExportService.exportSingleCalculationCSV(record) {
            ExportService.shareFile(at: url)
        }
    }

    func shareSummary() {
        guard result.isValid else { return }
        let text = """
        Thrust Wealth — Lot Size Result
        Symbol: \(symbolID)
        Suggested Lots: \(Formatters.lots(result.suggestedLots))
        Risk: \(Formatters.money(result.riskAmount, currency: currency)) (\(Formatters.percent(result.riskPercent)))
        Stop: \(stopPipsText) pips | Pip Value: \(Formatters.money(result.pipValue, currency: currency))/pip
        Notional: \(Formatters.money(result.notionalValue, currency: currency))
        """
        ExportService.shareText(text)
    }

    func restore(_ record: CalculationRecord) {
        symbolID = record.symbol
        mode = CalculatorMode(rawValue: record.mode) ?? .byRisk
        balanceText = String(format: "%.0f", record.balance)
        riskPercentText = String(format: "%.2f", record.riskPercent)
        riskAmountText = String(format: "%.2f", record.riskAmount)
        lotSizeText = Formatters.lots(record.lotSize > 0 ? record.lotSize : record.suggestedLots)
        stopPipsText = String(format: "%.0f", record.stopPips)
        entryPriceText = String(record.entryPrice)
        direction = TradeDirection(rawValue: record.direction) ?? .long
        selectedPreset = record.riskPercent
        recalc()
        showToast("Parameters restored")
    }

    func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.toastMessage == message {
                self?.toastMessage = nil
            }
        }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
