import Foundation

/// SaleSmartly integration configuration.
/// Replace placeholder values with the values provided by the SaleSmartly admin console.
enum ChatConfig {
    /// Project JS address from SaleSmartly → Settings → Project Settings.
    /// Format: `https://assets.salesmartly.com/js/project_XXXXX_XXXXX_XXXXXXXXXX.js`
    static let scriptURL = "REPLACE_WITH_SALESMARTLY_PROJECT_SCRIPT_URL"

    /// Labels that must already exist in SaleSmartly → Customers → Tag Management.
    static let labelNames = ["ios", "thrust-wealth"]

    /// Custom field IDs from SaleSmartly → Settings → Custom Fields.
    /// Keys are field IDs (strings); values are placeholder keys used by ChatService.
    enum CustomFieldID {
        /// Text field for App version — replace with backend-assigned ID.
        static let appVersion = "REPLACE_APP_VERSION_FIELD_ID"
        /// Text field for traffic source — replace with backend-assigned ID.
        static let source = "REPLACE_SOURCE_FIELD_ID"
        /// Text field for device model — replace with backend-assigned ID.
        static let deviceModel = "REPLACE_DEVICE_MODEL_FIELD_ID"
    }

    static let sourceURL = "thrustwealth://home"
    static let userAgent = "ThrustWealth iOS"
    static let userDescription = "ThrustWealth iOS User"

    static var isConfigured: Bool {
        !scriptURL.hasPrefix("REPLACE_") && !scriptURL.isEmpty
    }
}
