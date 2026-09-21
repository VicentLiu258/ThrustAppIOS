import Foundation
import Combine
import UIKit

@MainActor
final class PLCalculatorViewModel: ObservableObject {
    @Published var symbolID: String = "XAUUSD"
    @Published var direction: TradeDirection = .long
    @Published var openPriceText: String = "2350.00"
    @Published var closePriceText: String = "2360.00"
    @Published var lotsText: String = "0.20"
    @Published var takeProfitPriceText: String = ""
    @Published var stopLossPriceText: String = ""
    @Published var result: ProfitLossResult = .invalid
    @Published var toastMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private weak var appState: AppState?

    var instruments: [Instrument] { appState?.instruments ?? Instrument.defaults }
    var currentInstrument: Instrument? { instruments.first { $0.id == symbolID } }
    var currency: String { appState?.preferences.accountCurrency ?? "USD" }

    func bind(appState: AppState) {
        self.appState = appState
        symbolID = appState.preferences.defaultSymbol
        if let inst = currentInstrument {
            openPriceText = Formatters.price(inst.defaultPrice, digits: inst.digits)
            closePriceText = Formatters.price(inst.defaultPrice * 1.004, digits: inst.digits)
        }
        Publishers.MergeMany(
            $symbolID.map { _ in () }.eraseToAnyPublisher(),
            $direction.map { _ in () }.eraseToAnyPublisher(),
            $openPriceText.map { _ in () }.eraseToAnyPublisher(),
            $closePriceText.map { _ in () }.eraseToAnyPublisher(),
            $lotsText.map { _ in () }.eraseToAnyPublisher(),
            $takeProfitPriceText.map { _ in () }.eraseToAnyPublisher(),
            $stopLossPriceText.map { _ in () }.eraseToAnyPublisher()
        )
        .debounce(for: .milliseconds(280), scheduler: RunLoop.main)
        .sink { [weak self] in self?.recalc() }
        .store(in: &cancellables)
        recalc()
    }

    func selectSymbol(_ id: String) {
        symbolID = id
        if let inst = instruments.first(where: { $0.id == id }) {
            openPriceText = Formatters.price(inst.defaultPrice, digits: inst.digits)
            closePriceText = Formatters.price(inst.defaultPrice * 1.004, digits: inst.digits)
        }
        takeProfitPriceText = ""
        stopLossPriceText = ""
    }

    func recalc() {
        result = CalculatorEngine.calculateProfitLoss(
            instrument: currentInstrument,
            direction: direction,
            openPrice: Double(openPriceText) ?? 0,
            closePrice: Double(closePriceText) ?? 0,
            lotSize: Double(lotsText) ?? 0,
            takeProfitPrice: Double(takeProfitPriceText),
            stopLossPrice: Double(stopLossPriceText),
            accountCurrency: currency
        )
    }

    func reset() {
        direction = .long
        lotsText = "0.20"
        takeProfitPriceText = ""
        stopLossPriceText = ""
        if let inst = currentInstrument {
            openPriceText = Formatters.price(inst.defaultPrice, digits: inst.digits)
            closePriceText = Formatters.price(inst.defaultPrice * 1.004, digits: inst.digits)
        }
        recalc()
        toast("P/L inputs reset")
    }

    func saveToJournal() {
        guard result.isValid else { return }
        let trade = TradeEntry.make(
            symbol: symbolID,
            direction: direction,
            lots: Double(lotsText) ?? 0,
            openPrice: Double(openPriceText) ?? 0,
            closePrice: Double(closePriceText) ?? 0,
            pnl: result.profitAmount,
            note: "From P/L Calculator"
        )
        StorageService.shared.addJournalTrade(trade)
        toast("Saved to Trade Journal")
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func exportCSV() {
        guard result.isValid else { return }
        let rows: [[String]] = [
            ["Field", "Value"],
            ["Symbol", symbolID],
            ["Direction", direction.rawValue],
            ["Open", openPriceText],
            ["Close", closePriceText],
            ["Lots", lotsText],
            ["Take Profit Target", takeProfitPriceText],
            ["Stop Loss Target", stopLossPriceText],
            ["P/L", String(result.profitAmount)],
            ["Pips", String(result.profitPips)],
            ["Return %", String(result.returnPercent)],
            ["TP Target P/L", targetSummary(amount: result.takeProfitAmount, pips: result.takeProfitPips)],
            ["SL Target P/L", targetSummary(amount: result.stopLossAmount, pips: result.stopLossPips)],
            ["Disclaimer", "For calculation purposes only. Not investment advice."]
        ]
        if let url = ExportService.writeTempPublic(filename: "thrust_pnl_\(Int(Date().timeIntervalSince1970)).csv", content: ExportService.csvString(from: rows)) {
            ExportService.shareFile(at: url)
        }
    }

    private func toast(_ msg: String) {
        toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.toastMessage == msg { self?.toastMessage = nil }
        }
    }

    private func targetSummary(amount: Double?, pips: Double?) -> String {
        guard let amount, let pips else { return "—" }
        let money = Formatters.money(amount, currency: currency, signed: true)
        let pipSign = pips >= 0 ? "+" : "−"
        return "\(money) · \(pipSign)\(String(format: "%.1f", abs(pips))) pips"
    }
}

extension ExportService {
    static func writeTempPublic(filename: String, content: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
