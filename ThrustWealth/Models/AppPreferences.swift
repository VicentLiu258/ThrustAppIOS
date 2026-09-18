import Foundation

struct AppPreferences: Codable, Equatable {
    var accountCurrency: String
    var defaultSymbol: String
    var defaultLeverage: String
    var lotUnitDisplay: String
    var theme: AppThemeOption

    static let `default` = AppPreferences(
        accountCurrency: "USD",
        defaultSymbol: "XAUUSD",
        defaultLeverage: "1:100",
        lotUnitDisplay: "Standard",
        theme: .dark
    )

    static let currencies = ["USD", "EUR", "GBP", "JPY"]
    static let leverages = ["1:50", "1:100", "1:200", "1:500"]
    static let lotUnits = ["Standard", "Mini", "Micro"]

    var currencySymbol: String {
        switch accountCurrency {
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        default: return "$"
        }
    }
}

enum ReferenceRates {
    static let rates: [String: Double] = [
        "USDJPY": 154.50,
        "EURUSD": 1.0850,
        "GBPUSD": 1.2950,
        "AUDUSD": 0.6650,
        "USDCAD": 1.3650,
        "USDCHF": 0.8950
    ]
}
