import Foundation

/// SaleSmartly iOS integration configuration.
///
/// iOS follows the dedicated service-link/WebView flow. Do not use the Android
/// project JavaScript URL here: it is only required by the Android native SDK.
enum ChatConfig {
    /// Copy this from SaleSmartly → Chat Plugin → Service Link.
    /// Example: `https://chat.example.com/service/example-id`
    static let serviceLinkURL = "REPLACE_WITH_SALESMARTLY_SERVICE_LINK"

    /// These tags must exist in SaleSmartly → Customers → Tag Management.
    static let labelNames = ["ios", "thrust_wealth"]

    /// Fill the IDs only after the corresponding custom fields are created in
    /// SaleSmartly. Empty IDs intentionally prevent an invalid field from being sent.
    enum CustomFieldID {
        static let appVersion = ""
        static let source = ""
        static let deviceModel = ""
    }

    static let userDescription = "Thrust Wealth iOS App User"

    static var serviceLink: URL? {
        guard !serviceLinkURL.hasPrefix("REPLACE_"),
              let url = URL(string: serviceLinkURL),
              url.scheme?.lowercased() == "https",
              url.host != nil else {
            return nil
        }
        return url
    }
}
