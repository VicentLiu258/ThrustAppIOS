import Foundation

struct AppPreferences: Codable, Equatable {
    var accountCurrency: String
    var defaultSymbol: String
    var defaultLeverage: String
    var lotUnitDisplay: String
    var theme: AppThemeOption
    /// Required before SaleSmartly SDK initialization (compliance).
    var privacyConsentAccepted: Bool
    /// Whether the floating support chat button is shown on the home page.
    var showHomeChatButton: Bool

    static let `default` = AppPreferences(
        accountCurrency: "USD",
        defaultSymbol: "XAUUSD",
        defaultLeverage: "1:100",
        lotUnitDisplay: "Standard",
        theme: .dark,
        privacyConsentAccepted: false,
        showHomeChatButton: true
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

    /// Backward-compatible decoding for preferences saved before privacyConsentAccepted existed.
    enum CodingKeys: String, CodingKey {
        case accountCurrency, defaultSymbol, defaultLeverage, lotUnitDisplay, theme, privacyConsentAccepted, showHomeChatButton
    }

    init(
        accountCurrency: String,
        defaultSymbol: String,
        defaultLeverage: String,
        lotUnitDisplay: String,
        theme: AppThemeOption,
        privacyConsentAccepted: Bool,
        showHomeChatButton: Bool = true
    ) {
        self.accountCurrency = accountCurrency
        self.defaultSymbol = defaultSymbol
        self.defaultLeverage = defaultLeverage
        self.lotUnitDisplay = lotUnitDisplay
        self.theme = theme
        self.privacyConsentAccepted = privacyConsentAccepted
        self.showHomeChatButton = showHomeChatButton
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountCurrency = try container.decodeIfPresent(String.self, forKey: .accountCurrency) ?? "USD"
        defaultSymbol = try container.decodeIfPresent(String.self, forKey: .defaultSymbol) ?? "XAUUSD"
        defaultLeverage = try container.decodeIfPresent(String.self, forKey: .defaultLeverage) ?? "1:100"
        lotUnitDisplay = try container.decodeIfPresent(String.self, forKey: .lotUnitDisplay) ?? "Standard"
        theme = try container.decodeIfPresent(AppThemeOption.self, forKey: .theme) ?? .dark
        privacyConsentAccepted = try container.decodeIfPresent(Bool.self, forKey: .privacyConsentAccepted) ?? false
        showHomeChatButton = try container.decodeIfPresent(Bool.self, forKey: .showHomeChatButton) ?? true
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
