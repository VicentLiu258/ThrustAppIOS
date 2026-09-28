import Foundation
import AppsFlyerLib

/// AppsFlyer attribution. Started only after the user accepts the privacy policy.
final class AppsFlyerService {
    static let shared = AppsFlyerService()

    /// Numeric App Store ID without the `id` prefix. Dashboard matching needs this once the app exists in App Store Connect.
    static let appleAppID = ""
    static let devKey = "rk5rSYHn7GfJEcS3VXXJW3"
    static let searchJumpEvent = "af_ic"
    static let supportPhoneSubmittedEvent = "af_whats_leads"
    private static let guestIDKey = "thrust_wealth_salesmartly_guest_id"
    private var started = false

    private init() {}

    func start() {
        let lib = AppsFlyerLib.shared()
        lib.appsFlyerDevKey = Self.devKey
        lib.appleAppID = Self.appleAppID
        lib.customerUserID = guestUserId()
        #if DEBUG
        lib.isDebug = true
        #endif
        lib.start()
        started = true
    }

    /// Fired when a home-search result navigates the user into a tool.
    func logSearchJump(searchQuery: String, destination: String) {
        AppsFlyerLib.shared().logEvent(
            Self.searchJumpEvent,
            withValues: [
                "af_search_string": searchQuery,
                "af_content": destination
            ]
        )
    }

    /// Only the fact of submitting a phone field is sent, never its value.
    func logSupportPhoneSubmitted() {
        guard started else { return }
        AppsFlyerLib.shared().logEvent(Self.supportPhoneSubmittedEvent, withValues: [:])
    }

    private func guestUserId() -> String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: Self.guestIDKey), !existing.isEmpty {
            return existing
        }
        let generated = "tw_ios_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
        defaults.set(generated, forKey: Self.guestIDKey)
        return generated
    }
}
