import Foundation

/// SaleSmartly iOS integration configuration.
///
/// iOS follows the hosted H5/WebView flow. Do not use the Android project
/// JavaScript URL as the WebView address; the H5 bridge loads it after login.
enum ChatConfig {
    /// Hosted H5 bridge used by the iOS WebView. The page loads the
    /// SaleSmartly project script after receiving the native login payload.
    static let serviceLinkURL = "https://www.compoundmatrix.com/salesmartly-chat/"

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
