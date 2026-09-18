import Foundation
import UIKit
#if canImport(SalesmartlyChat)
import SalesmartlyChat
#endif

/// Thin wrapper around SaleSmartly Chat SDK.
/// All SDK calls are gated behind privacy consent and `#if canImport(SalesmartlyChat)`.
@MainActor
final class ChatService: ObservableObject {
    static let shared = ChatService()

    @Published private(set) var isReady = false
    @Published private(set) var isInitializing = false
    @Published private(set) var unreadCount = 0
    @Published private(set) var lastError: String?

    private var didRegisterCallbacks = false

    private init() {}

    // MARK: - Guest ID persistence

    private static let guestIDKey = "thrust_wealth_salesmartly_guest_id"

    /// Returns a stable guest ID; generates and persists on first call.
    func persistedGuestUserId() -> String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: Self.guestIDKey), !existing.isEmpty {
            return existing
        }
        let generated = UUID().uuidString
        defaults.set(generated, forKey: Self.guestIDKey)
        return generated
    }

    func clearGuestUserId() {
        UserDefaults.standard.removeObject(forKey: Self.guestIDKey)
    }

    // MARK: - Lifecycle

    /// Initializes the SDK only after privacy consent. Safe to call repeatedly.
    func initializeIfAllowed(privacyConsentAccepted: Bool) async {
        guard privacyConsentAccepted else {
            lastError = nil
            return
        }
        guard ChatConfig.isConfigured else {
            lastError = "SaleSmartly scriptURL is not configured yet."
            return
        }
        guard !isReady, !isInitializing else { return }

        #if canImport(SalesmartlyChat)
        isInitializing = true
        lastError = nil
        registerCallbacksIfNeeded()

        do {
            let context = SalesmartlyNativeBootstrapContext(
                sourceURL: ChatConfig.sourceURL,
                userAgent: ChatConfig.userAgent,
                navigatorLanguage: Locale.current.identifier,
                beforeSourceURL: "",
                guestUserId: persistedGuestUserId()
            )
            try await SalesmartlyChat.initialize(
                scriptURL: ChatConfig.scriptURL,
                nativeBootstrapContext: context
            )
            applyLoginInfo()
            isReady = true
        } catch {
            lastError = error.localizedDescription
            isReady = false
        }
        isInitializing = false
        #else
        lastError = "SalesmartlyChat package is not linked. Add the SwiftPM dependency."
        #endif
    }

    func openChat() {
        #if canImport(SalesmartlyChat)
        guard isReady else {
            lastError = "Chat is not ready. Check privacy consent and scriptURL."
            return
        }
        applyLoginInfo()
        SalesmartlyChat.openChat()
        #else
        lastError = "SalesmartlyChat package is not linked."
        #endif
    }

    func setWindowVisible(_ visible: Bool) {
        #if canImport(SalesmartlyChat)
        guard isReady else { return }
        SalesmartlyChat.setWindowVisible(visible)
        #endif
    }

    func clearUser() {
        #if canImport(SalesmartlyChat)
        SalesmartlyChat.clearUser()
        #endif
    }

    /// Called after full local data purge; tears down chat identity for next consent cycle.
    func resetAfterDataPurge() {
        clearUser()
        clearGuestUserId()
        isReady = false
        isInitializing = false
        unreadCount = 0
        lastError = nil
    }

    // MARK: - Login / identity

    func applyLoginInfo() {
        #if canImport(SalesmartlyChat)
        guard isReady || isInitializing else { return }

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let deviceModel = UIDevice.current.model

        var customFields: [String: String] = [:]
        if !ChatConfig.CustomFieldID.appVersion.hasPrefix("REPLACE_") {
            customFields[ChatConfig.CustomFieldID.appVersion] = appVersion
        }
        if !ChatConfig.CustomFieldID.source.hasPrefix("REPLACE_") {
            customFields[ChatConfig.CustomFieldID.source] = "ios-app"
        }
        if !ChatConfig.CustomFieldID.deviceModel.hasPrefix("REPLACE_") {
            customFields[ChatConfig.CustomFieldID.deviceModel] = deviceModel
        }

        let userId = persistedGuestUserId()
        SalesmartlyChat.setLoginInfo(
            LoginInfo(
                userId: userId,
                userName: "ThrustWealth User",
                language: "en-US",
                phone: "",
                email: "",
                description: ChatConfig.userDescription,
                labelNames: ChatConfig.labelNames,
                customFieldsExt: customFields
            )
        )
        #endif
    }

    // MARK: - Callbacks

    private func registerCallbacksIfNeeded() {
        #if canImport(SalesmartlyChat)
        guard !didRegisterCallbacks else { return }
        didRegisterCallbacks = true

        SalesmartlyChat.push("onReady") { [weak self] _ in
            Task { @MainActor in
                self?.isReady = true
            }
        }

        SalesmartlyChat.push("onUnRead") { [weak self] payload in
            Task { @MainActor in
                if let dict = payload as? [String: Any],
                   let num = dict["num"] as? Int {
                    self?.unreadCount = num
                } else if let num = payload as? Int {
                    self?.unreadCount = num
                }
            }
        }
        #endif
    }
}
