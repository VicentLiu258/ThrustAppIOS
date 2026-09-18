import Foundation

#if DEBUG
enum CalculatorEngineSelfTest {
    /// Quick sanity checks for the documented formula examples.
    static func run() {
        let gold = Instrument.defaults.first { $0.id == "XAUUSD" }!
        let lot = CalculatorEngine.calculateLotSize(
            balance: 10_000,
            riskPercent: 1.0,
            stopPips: 50,
            instrument: gold,
            entryPrice: 2350,
            direction: .long,
            accountCurrency: "USD"
        )
        assert(lot.isValid)
        assert(abs(lot.suggestedLots - 0.20) < 0.001, "Expected 0.20 lots, got \(lot.suggestedLots)")
        assert(abs(lot.riskAmount - 100) < 0.01)
        assert(abs(lot.pipValue - 10) < 0.01)
        assert(abs((lot.stopLossPrice ?? 0) - 2345) < 0.01)

        let pl = CalculatorEngine.calculateProfitLoss(
            instrument: gold,
            direction: .long,
            openPrice: 2350,
            closePrice: 2360,
            lotSize: 0.20,
            accountCurrency: "USD"
        )
        assert(pl.isValid)
        assert(abs(pl.profitAmount - 200) < 0.01, "Expected +200, got \(pl.profitAmount)")
        assert(abs(pl.profitPips - 100) < 0.1)
        print("[ThrustWealth] CalculatorEngine self-test passed")
    }
}
#endif
