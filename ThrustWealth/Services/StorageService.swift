import Foundation

@MainActor
final class StorageService {
    static let shared = StorageService()

    private enum Keys {
        static let preferences = "thrust_wealth_preferences"
        static let history = "thrust_wealth_calc_history"
        static let journal = "thrust_wealth_trade_journal"
        static let customInstruments = "thrust_wealth_custom_instruments"
        static let favorites = "thrust_wealth_favorites"
        static let guestID = "thrust_wealth_salesmartly_guest_id"
    }

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - Preferences

    func getPreferences() -> AppPreferences {
        guard let data = defaults.data(forKey: Keys.preferences),
              let prefs = try? decoder.decode(AppPreferences.self, from: data) else {
            return .default
        }
        return prefs
    }

    func savePreferences(_ prefs: AppPreferences) {
        if let data = try? encoder.encode(prefs) {
            defaults.set(data, forKey: Keys.preferences)
        }
    }

    // MARK: - History (max 50)

    func getHistory() -> [CalculationRecord] {
        guard let data = defaults.data(forKey: Keys.history),
              let list = try? decoder.decode([CalculationRecord].self, from: data) else {
            return []
        }
        return list
    }

    @discardableResult
    func saveCalculation(_ record: CalculationRecord) -> [CalculationRecord] {
        var history = getHistory()

        if let last = history.first,
           last.symbol == record.symbol,
           last.balance == record.balance,
           last.riskPercent == record.riskPercent,
           last.stopPips == record.stopPips,
           record.timestamp - last.timestamp < 3000 {
            return history
        }

        history.insert(record, at: 0)
        let trimmed = Array(history.prefix(50))
        persist(trimmed, key: Keys.history)
        return trimmed
    }

    @discardableResult
    func deleteHistoryItem(id: String) -> [CalculationRecord] {
        var history = getHistory().filter { $0.id != id }
        persist(history, key: Keys.history)
        return history
    }

    @discardableResult
    func clearHistory() -> [CalculationRecord] {
        defaults.removeObject(forKey: Keys.history)
        return []
    }

    // MARK: - Journal

    func getJournalTrades() -> [TradeEntry] {
        if let data = defaults.data(forKey: Keys.journal),
           let list = try? decoder.decode([TradeEntry].self, from: data) {
            return list
        }
        let sample = Self.sampleTrades
        persist(sample, key: Keys.journal)
        return sample
    }

    @discardableResult
    func addJournalTrade(_ trade: TradeEntry) -> [TradeEntry] {
        var trades = getJournalTrades()
        trades.insert(trade, at: 0)
        persist(trades, key: Keys.journal)
        return trades
    }

    @discardableResult
    func deleteJournalTrade(id: String) -> [TradeEntry] {
        let trades = getJournalTrades().filter { $0.id != id }
        persist(trades, key: Keys.journal)
        return trades
    }

    @discardableResult
    func clearJournalTrades() -> [TradeEntry] {
        let empty: [TradeEntry] = []
        persist(empty, key: Keys.journal)
        return empty
    }

    func getJournalStats() -> JournalStats {
        let trades = getJournalTrades()
        guard !trades.isEmpty else { return .empty }

        var netPnl = 0.0
        var winning = 0
        var totalWin = 0.0
        var totalLoss = 0.0
        var peak = 0.0
        var maxDD = 0.0
        var equity = 0.0

        // Chronological for drawdown (oldest first)
        let chronological = trades.reversed()
        for t in chronological {
            let pnl = t.pnl
            netPnl += pnl
            equity += pnl
            if equity > peak { peak = equity }
            let dd = peak - equity
            if dd > maxDD { maxDD = dd }

            if pnl > 0 {
                winning += 1
                totalWin += pnl
            } else if pnl < 0 {
                totalLoss += abs(pnl)
            }
        }

        let winRate = Int(round(Double(winning) / Double(trades.count) * 100))
        let avgWin = winning > 0 ? totalWin / Double(winning) : 0
        let losingCount = trades.count - winning
        let avgLoss = losingCount > 0 ? totalLoss / Double(losingCount) : 1
        let avgRR = avgLoss > 0 ? String(format: "%.1f", avgWin / avgLoss) : "1.0"

        return JournalStats(
            netPnl: netPnl.rounded(),
            winRate: winRate,
            avgRR: avgRR,
            maxDrawdown: maxDD > 0 ? maxDD.rounded() : 0,
            totalTrades: trades.count
        )
    }

    // MARK: - Instruments

    func getCustomInstruments() -> [Instrument] {
        guard let data = defaults.data(forKey: Keys.customInstruments),
              let list = try? decoder.decode([Instrument].self, from: data) else {
            return []
        }
        return list
    }

    func getFavoriteIDs() -> Set<String> {
        if let arr = defaults.array(forKey: Keys.favorites) as? [String] {
            return Set(arr)
        }
        return Set(Instrument.defaults.filter(\.isFavorite).map(\.id))
    }

    func setFavorite(id: String, isFavorite: Bool) {
        var favs = getFavoriteIDs()
        if isFavorite {
            favs.insert(id)
        } else {
            favs.remove(id)
        }
        defaults.set(Array(favs), forKey: Keys.favorites)
    }

    func getInstruments() -> [Instrument] {
        let favs = getFavoriteIDs()
        let builtins = Instrument.defaults.map { inst -> Instrument in
            var copy = inst
            copy.isFavorite = favs.contains(inst.id)
            return copy
        }
        let custom = getCustomInstruments().map { inst -> Instrument in
            var copy = inst
            copy.isFavorite = favs.contains(inst.id)
            copy.isCustom = true
            return copy
        }
        return builtins + custom
    }

    @discardableResult
    func saveCustomInstrument(_ instrument: Instrument) -> [Instrument] {
        var custom = getCustomInstruments()
        var inst = instrument
        inst.isCustom = true
        custom.append(inst)
        persist(custom, key: Keys.customInstruments)
        return getInstruments()
    }

    @discardableResult
    func deleteCustomInstrument(id: String) -> [Instrument] {
        let custom = getCustomInstruments().filter { $0.id != id }
        persist(custom, key: Keys.customInstruments)
        return getInstruments()
    }

    // MARK: - Reset

    func resetAllData() {
        defaults.removeObject(forKey: Keys.history)
        defaults.removeObject(forKey: Keys.journal)
        defaults.removeObject(forKey: Keys.customInstruments)
        defaults.removeObject(forKey: Keys.preferences)
        defaults.removeObject(forKey: Keys.favorites)
        // Guest ID is cleared so a fresh SaleSmartly visitor identity is created after purge.
        defaults.removeObject(forKey: Keys.guestID)
        ChatService.shared.resetAfterDataPurge()
    }

    // MARK: - Full backup payload

    func fullBackupPayload() -> [String: Any] {
        [
            "preferences": (try? encoder.encode(getPreferences())).flatMap { try? JSONSerialization.jsonObject(with: $0) } ?? [:],
            "history": (try? encoder.encode(getHistory())).flatMap { try? JSONSerialization.jsonObject(with: $0) } ?? [],
            "journal": (try? encoder.encode(getJournalTrades())).flatMap { try? JSONSerialization.jsonObject(with: $0) } ?? [],
            "customInstruments": (try? encoder.encode(getCustomInstruments())).flatMap { try? JSONSerialization.jsonObject(with: $0) } ?? [],
            "exportedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }

    // MARK: - Helpers

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static let sampleTrades: [TradeEntry] = [
        TradeEntry(id: "t1", date: "2026-09-08", symbol: "XAUUSD", direction: "long", lots: 0.20, openPrice: 2350, closePrice: 2360, pnl: 200, note: "Trend breakout"),
        TradeEntry(id: "t2", date: "2026-09-07", symbol: "EURUSD", direction: "short", lots: 1.00, openPrice: 1.0880, closePrice: 1.0888, pnl: -85, note: "Tight SL hit"),
        TradeEntry(id: "t3", date: "2026-09-05", symbol: "XAGUSD", direction: "long", lots: 0.50, openPrice: 28.10, closePrice: 28.22, pnl: 310, note: "Bounce from support"),
        TradeEntry(id: "t4", date: "2026-09-03", symbol: "US30", direction: "long", lots: 0.50, openPrice: 40200, closePrice: 40380, pnl: 815, note: "Opening bell momentum")
    ]
}
