import Foundation

struct TradeEntry: Identifiable, Codable, Hashable {
    var id: String
    var date: String
    var symbol: String
    var direction: String
    var lots: Double
    var openPrice: Double
    var closePrice: Double
    var pnl: Double
    var note: String

    var tradeDirection: TradeDirection {
        TradeDirection(rawValue: direction) ?? .long
    }

    var isProfit: Bool { pnl >= 0 }

    static func make(
        symbol: String,
        direction: TradeDirection,
        lots: Double,
        openPrice: Double,
        closePrice: Double,
        pnl: Double,
        note: String,
        date: Date = Date()
    ) -> TradeEntry {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return TradeEntry(
            id: "trade_\(Int(Date().timeIntervalSince1970 * 1000))",
            date: formatter.string(from: date),
            symbol: symbol,
            direction: direction.rawValue,
            lots: lots,
            openPrice: openPrice,
            closePrice: closePrice,
            pnl: pnl,
            note: note
        )
    }
}

struct JournalStats: Equatable {
    var netPnl: Double
    var winRate: Int
    var avgRR: String
    var maxDrawdown: Double
    var totalTrades: Int

    static let empty = JournalStats(netPnl: 0, winRate: 0, avgRR: "0.0", maxDrawdown: 0, totalTrades: 0)
}
