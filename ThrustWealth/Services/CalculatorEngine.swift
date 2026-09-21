import Foundation

// MARK: - Result Types

struct LotSizeResult: Equatable {
    var isValid: Bool
    var suggestedLots: Double
    var rawLots: Double
    var miniLots: Double
    var microLots: Double
    var riskAmount: Double
    var riskPercent: Double
    var pipValue: Double
    var notionalValue: Double
    var stopLossPrice: Double?
    var error: String?

    static let invalid = LotSizeResult(
        isValid: false, suggestedLots: 0, rawLots: 0, miniLots: 0, microLots: 0,
        riskAmount: 0, riskPercent: 0, pipValue: 0, notionalValue: 0,
        stopLossPrice: nil, error: "Enter positive balance, risk %, and stop loss pips"
    )
}

struct ProfitLossResult: Equatable {
    var isValid: Bool
    var profitAmount: Double
    var profitPips: Double
    var priceDelta: Double
    var returnPercent: Double
    var notionalValue: Double
    var isProfit: Bool
    var takeProfitAmount: Double?
    var takeProfitPips: Double?
    var stopLossAmount: Double?
    var stopLossPips: Double?
    var error: String?

    static let invalid = ProfitLossResult(
        isValid: false, profitAmount: 0, profitPips: 0, priceDelta: 0,
        returnPercent: 0, notionalValue: 0, isProfit: false,
        takeProfitAmount: nil, takeProfitPips: nil,
        stopLossAmount: nil, stopLossPips: nil, error: nil
    )
}

// MARK: - Engine

enum CalculatorEngine {

    /// Pip value for 1.00 standard lot in account currency.
    static func calculatePipValue(instrument: Instrument, accountCurrency: String = "USD") -> Double {
        guard instrument.contractSize > 0, instrument.pipSize > 0 else { return 0 }

        let pipValueQuote = instrument.contractSize * instrument.pipSize

        if instrument.quoteCurrency == accountCurrency {
            return pipValueQuote
        }

        if instrument.quoteCurrency == "JPY" && accountCurrency == "USD" {
            let rate = ReferenceRates.rates["USDJPY"] ?? 154.50
            return pipValueQuote / rate
        }

        let pairDirect = "\(accountCurrency)\(instrument.quoteCurrency)"
        if let rate = ReferenceRates.rates[pairDirect] {
            return pipValueQuote / rate
        }

        let pairInverse = "\(instrument.quoteCurrency)\(accountCurrency)"
        if let rate = ReferenceRates.rates[pairInverse] {
            return pipValueQuote * rate
        }

        return pipValueQuote
    }

    /// By Risk: risk budget → suggested lots
    static func calculateLotSize(
        balance: Double,
        riskPercent: Double,
        stopPips: Double,
        instrument: Instrument?,
        entryPrice: Double = 0,
        direction: TradeDirection = .long,
        accountCurrency: String = "USD"
    ) -> LotSizeResult {
        guard let instrument else {
            return .invalid
        }

        let numEntry = entryPrice > 0 ? entryPrice : instrument.defaultPrice

        guard balance > 0, (0.01...100).contains(riskPercent), stopPips > 0 else {
            return LotSizeResult(
                isValid: false,
                suggestedLots: 0,
                rawLots: 0,
                miniLots: 0,
                microLots: 0,
                riskAmount: balance * (riskPercent / 100),
                riskPercent: riskPercent,
                pipValue: 0,
                notionalValue: 0,
                stopLossPrice: nil,
                error: "Balance must be positive; risk must be 0.01–100%; stop loss must be positive"
            )
        }

        let riskAmount = balance * (riskPercent / 100)
        let pipValue = calculatePipValue(instrument: instrument, accountCurrency: accountCurrency)
        guard pipValue > 0 else {
            return LotSizeResult(
                isValid: false, suggestedLots: 0, rawLots: 0, miniLots: 0, microLots: 0,
                riskAmount: riskAmount, riskPercent: riskPercent, pipValue: 0, notionalValue: 0,
                stopLossPrice: nil, error: "Invalid instrument pip value"
            )
        }

        let rawLots = riskAmount / (stopPips * pipValue)
        guard rawLots <= 100 else {
            return LotSizeResult(
                isValid: false, suggestedLots: 0, rawLots: rawLots, miniLots: 0, microLots: 0,
                riskAmount: riskAmount, riskPercent: riskPercent, pipValue: pipValue, notionalValue: 0,
                stopLossPrice: nil, error: "Calculated lot size exceeds the 100-lot maximum"
            )
        }
        let suggestedLots = max(0.01, floor(rawLots * 100) / 100)
        let notional = suggestedLots * instrument.contractSize * numEntry

        var slPrice: Double?
        if numEntry > 0 {
            let shift = stopPips * instrument.pipSize
            let raw = direction == .long ? numEntry - shift : numEntry + shift
            slPrice = round(raw, digits: instrument.digits)
        }

        return LotSizeResult(
            isValid: true,
            suggestedLots: suggestedLots,
            rawLots: rawLots,
            miniLots: round(suggestedLots * 10, digits: 1),
            microLots: round(suggestedLots * 100, digits: 0),
            riskAmount: riskAmount,
            riskPercent: riskPercent,
            pipValue: pipValue,
            notionalValue: notional,
            stopLossPrice: slPrice,
            error: nil
        )
    }

    /// By Lots: known lots → risk amount & %
    static func calculateRiskFromLots(
        balance: Double,
        lotSize: Double,
        stopPips: Double,
        instrument: Instrument?,
        entryPrice: Double = 0,
        direction: TradeDirection = .long,
        accountCurrency: String = "USD"
    ) -> LotSizeResult {
        guard let instrument else { return .invalid }

        let numEntry = entryPrice > 0 ? entryPrice : instrument.defaultPrice

        guard balance > 0, (0.01...100).contains(lotSize), stopPips > 0 else {
            return LotSizeResult(
                isValid: false, suggestedLots: lotSize, rawLots: lotSize, miniLots: 0, microLots: 0,
                riskAmount: 0, riskPercent: 0, pipValue: 0, notionalValue: 0,
                stopLossPrice: nil, error: "Balance must be positive; lots must be 0.01–100; stop loss must be positive"
            )
        }

        let pipValue = calculatePipValue(instrument: instrument, accountCurrency: accountCurrency)
        let riskAmount = stopPips * pipValue * lotSize
        let riskPercent = (riskAmount / balance) * 100
        let notional = lotSize * instrument.contractSize * numEntry
        guard riskPercent <= 100 else {
            return LotSizeResult(
                isValid: false, suggestedLots: lotSize, rawLots: lotSize, miniLots: 0, microLots: 0,
                riskAmount: riskAmount, riskPercent: riskPercent, pipValue: pipValue, notionalValue: notional,
                stopLossPrice: nil, error: "Calculated risk exceeds the 100% maximum"
            )
        }

        var slPrice: Double?
        if numEntry > 0 {
            let shift = stopPips * instrument.pipSize
            let raw = direction == .long ? numEntry - shift : numEntry + shift
            slPrice = round(raw, digits: instrument.digits)
        }

        return LotSizeResult(
            isValid: true,
            suggestedLots: lotSize,
            rawLots: lotSize,
            miniLots: round(lotSize * 10, digits: 1),
            microLots: round(lotSize * 100, digits: 0),
            riskAmount: riskAmount,
            riskPercent: round(riskPercent, digits: 2),
            pipValue: pipValue,
            notionalValue: notional,
            stopLossPrice: slPrice,
            error: nil
        )
    }

    /// P/L Calculator
    static func calculateProfitLoss(
        instrument: Instrument?,
        direction: TradeDirection = .long,
        openPrice: Double,
        closePrice: Double,
        lotSize: Double,
        takeProfitPrice: Double? = nil,
        stopLossPrice: Double? = nil,
        accountCurrency: String = "USD"
    ) -> ProfitLossResult {
        guard let instrument, openPrice > 0, closePrice > 0, (0.01...100).contains(lotSize) else {
            return .invalid
        }

        let priceDelta = direction == .long ? (closePrice - openPrice) : (openPrice - closePrice)
        let profitPips = priceDelta / instrument.pipSize
        let pipValue = calculatePipValue(instrument: instrument, accountCurrency: accountCurrency)
        let profitAmount = profitPips * pipValue * lotSize
        let notional = lotSize * instrument.contractSize * openPrice
        let returnPercent = notional > 0 ? (profitAmount / notional) * 100 : 0
        let takeProfit = calculateTarget(
            price: takeProfitPrice, openPrice: openPrice, lotSize: lotSize,
            instrument: instrument, direction: direction, pipValue: pipValue
        )
        let stopLoss = calculateTarget(
            price: stopLossPrice, openPrice: openPrice, lotSize: lotSize,
            instrument: instrument, direction: direction, pipValue: pipValue
        )

        return ProfitLossResult(
            isValid: true,
            profitAmount: round(profitAmount, digits: 2),
            profitPips: round(profitPips, digits: 1),
            priceDelta: round(priceDelta, digits: instrument.digits),
            returnPercent: round(returnPercent, digits: 2),
            notionalValue: notional,
            isProfit: profitAmount >= 0,
            takeProfitAmount: takeProfit?.amount,
            takeProfitPips: takeProfit?.pips,
            stopLossAmount: stopLoss?.amount,
            stopLossPips: stopLoss?.pips,
            error: nil
        )
    }

    private static func calculateTarget(
        price: Double?, openPrice: Double, lotSize: Double, instrument: Instrument,
        direction: TradeDirection, pipValue: Double
    ) -> (amount: Double, pips: Double)? {
        guard let price, price > 0 else { return nil }
        let delta = direction == .long ? price - openPrice : openPrice - price
        let pips = delta / instrument.pipSize
        return (
            round(pips * pipValue * lotSize, digits: 2),
            round(pips, digits: 1)
        )
    }

    private static func round(_ value: Double, digits: Int) -> Double {
        let factor = pow(10.0, Double(digits))
        return (value * factor).rounded() / factor
    }
}

// MARK: - Formatting helpers

enum Formatters {
    static func money(_ value: Double, currency: String = "USD", signed: Bool = false) -> String {
        let symbol: String
        switch currency {
        case "EUR": symbol = "€"
        case "GBP": symbol = "£"
        case "JPY": symbol = "¥"
        default: symbol = "$"
        }
        let abs = abs(value)
        let body: String
        if currency == "JPY" {
            body = String(format: "%.0f", abs)
        } else {
            body = String(format: "%.2f", abs)
        }
        if signed {
            let sign = value >= 0 ? "+" : "−"
            return "\(sign)\(symbol)\(body)"
        }
        if value < 0 {
            return "−\(symbol)\(body)"
        }
        return "\(symbol)\(body)"
    }

    static func lots(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    static func percent(_ value: Double, digits: Int = 1) -> String {
        String(format: "%.\(digits)f%%", value)
    }

    static func price(_ value: Double, digits: Int) -> String {
        String(format: "%.\(digits)f", value)
    }

    static func compactNotional(_ value: Double, currency: String = "USD") -> String {
        let symbol = currency == "EUR" ? "€" : (currency == "GBP" ? "£" : (currency == "JPY" ? "¥" : "$"))
        if abs(value) >= 1000 {
            let k = value / 1000
            if abs(k) >= 100 {
                return "\(symbol)\(String(format: "%.0f", k))k"
            }
            return "\(symbol)\(String(format: "%.1f", k).replacingOccurrences(of: ".0", with: ""))k"
        }
        return money(value, currency: currency)
    }
}
