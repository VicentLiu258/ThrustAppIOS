import Foundation

struct CalculationRecord: Identifiable, Codable, Hashable {
    var id: String
    var timestamp: TimeInterval
    var dateStr: String
    var symbol: String
    var mode: String
    var balance: Double
    var riskPercent: Double
    var riskAmount: Double
    var stopPips: Double
    var entryPrice: Double
    var direction: String
    var lotSize: Double
    var suggestedLots: Double
    var pipValue: Double
    var notionalValue: Double
    var stopLossPrice: Double?

    var date: Date {
        Date(timeIntervalSince1970: timestamp / 1000)
    }

    static func make(
        symbol: String,
        mode: CalculatorMode,
        balance: Double,
        riskPercent: Double,
        riskAmount: Double,
        stopPips: Double,
        entryPrice: Double,
        direction: TradeDirection,
        lotSize: Double,
        suggestedLots: Double,
        pipValue: Double,
        notionalValue: Double,
        stopLossPrice: Double?
    ) -> CalculationRecord {
        let now = Date()
        return CalculationRecord(
            id: "hist_\(Int(now.timeIntervalSince1970 * 1000))",
            timestamp: now.timeIntervalSince1970 * 1000,
            dateStr: ISO8601DateFormatter().string(from: now),
            symbol: symbol,
            mode: mode.rawValue,
            balance: balance,
            riskPercent: riskPercent,
            riskAmount: riskAmount,
            stopPips: stopPips,
            entryPrice: entryPrice,
            direction: direction.rawValue,
            lotSize: lotSize,
            suggestedLots: suggestedLots,
            pipValue: pipValue,
            notionalValue: notionalValue,
            stopLossPrice: stopLossPrice
        )
    }
}
