import Foundation
import CryptoKit
import OSLog
import SwiftUI
import UIKit
import WebKit

/// SaleSmartly service-link session for the iOS WebView integration.
/// The service link is opened only after privacy consent, then receives the
/// visitor identity using the documented `service-link-login` postMessage flow.
@MainActor
final class ChatService: ObservableObject {
    static let shared = ChatService()

    @Published var isChatPresented = false
    @Published private(set) var unreadCount = 0
    @Published private(set) var connectionState: ChatConnectionState = .idle
    @Published private(set) var retryToken = 0

    private static let guestIDKey = "thrust_wealth_salesmartly_guest_id"
    private static let unreadCountKey = "thrust_wealth_salesmartly_unread_count"

    private init() {
        unreadCount = UserDefaults.standard.integer(forKey: Self.unreadCountKey)
    }

    func requestOpenChat(
        privacyConsentAccepted: Bool,
        onToast: @escaping (String) -> Void
    ) {
        guard privacyConsentAccepted else {
            onToast("Please accept the Privacy Policy first.")
            return
        }
        guard ChatConfig.serviceLink != nil else {
            onToast("Support chat needs the SaleSmartly service link configured in ChatConfig.swift.")
            return
        }
        connectionState = .loading
        isChatPresented = true
    }

    func dismissChat() {
        isChatPresented = false
    }

    func retryChat() {
        retryToken += 1
        connectionState = .loading
        isChatPresented = true
    }

    fileprivate func updateConnectionState(_ state: ChatConnectionState) {
        connectionState = state
    }

    /// Called after local data is purged, so the next chat session starts with
    /// a fresh SaleSmartly visitor identity.
    func resetAfterDataPurge() {
        UserDefaults.standard.removeObject(forKey: Self.guestIDKey)
        UserDefaults.standard.removeObject(forKey: Self.unreadCountKey)
        unreadCount = 0
        isChatPresented = false
        connectionState = .idle
    }

    fileprivate func serviceLinkWithLoginSource() -> URL? {
        guard let serviceLink = ChatConfig.serviceLink,
              var components = URLComponents(url: serviceLink, resolvingAgainstBaseURL: false) else {
            return nil
        }
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "loginSource" }
        items.append(URLQueryItem(name: "loginSource", value: "postMessage"))
        components.queryItems = items
        return components.url
    }

    fileprivate func loginInfo() -> [String: Any] {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        var customFields: [String: Any] = [:]
        addCustomField(ChatConfig.CustomFieldID.appVersion, value: appVersion, to: &customFields)
        addCustomField(ChatConfig.CustomFieldID.source, value: "ios-app", to: &customFields)
        addCustomField(ChatConfig.CustomFieldID.deviceModel, value: UIDevice.current.model, to: &customFields)

        return [
            "user_id": hashedGuestUserId(),
            "user_name": "Thrust Wealth User",
            "language": Locale.current.identifier,
            "phone": "",
            "email": "",
            "description": ChatConfig.userDescription,
            "label_names": ChatConfig.labelNames,
            "update_label_type": "update",
            "custom_fields_ext": customFields,
        ]
    }

    fileprivate func setUnreadCount(_ count: Int) {
        let normalizedCount = max(0, count)
        unreadCount = normalizedCount
        UserDefaults.standard.set(normalizedCount, forKey: Self.unreadCountKey)
    }

    private func persistedGuestUserId() -> String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: Self.guestIDKey), !existing.isEmpty {
            return existing
        }
        let generated = "tw_ios_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
        defaults.set(generated, forKey: Self.guestIDKey)
        return generated
    }

    private func hashedGuestUserId() -> String {
        let rawID = persistedGuestUserId()
        let digest = SHA256.hash(data: Data(rawID.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func addCustomField(_ id: String, value: Any, to fields: inout [String: Any]) {
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        fields[id] = value
    }
}

struct SalesmartlyChatSheet: View {
    @EnvironmentObject private var chatService: ChatService

    var body: some View {
        NavigationStack {
            Group {
                if let url = chatService.serviceLinkWithLoginSource() {
                    SalesmartlyServiceWebView(
                        serviceURL: url,
                        loginInfo: chatService.loginInfo(),
                        isPresented: chatService.isChatPresented,
                        retryToken: chatService.retryToken,
                        onUnreadCount: chatService.setUnreadCount,
                        onStatus: chatService.updateConnectionState
                    )
                } else {
                    ContentUnavailableView(
                        "Support unavailable",
                        systemImage: "exclamationmark.bubble",
                        description: Text("Add the SaleSmartly service link in ChatConfig.swift.")
                    )
                }
            }
            .navigationTitle("Customer Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { chatService.dismissChat() }
                }
            }
            .overlay(alignment: .bottom) {
                if case let .failed(message) = chatService.connectionState {
                    ChatFailureBanner(message: message, retry: chatService.retryChat)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
        }
    }
}

enum ChatConnectionState: Equatable {
    case idle
    case loading
    case signingIn
    case ready
    case failed(String)
}

private struct ChatFailureBanner: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(.orange)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 4)
            Button("Retry", action: retry)
                .font(.system(size: 13, weight: .bold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
    }
}

/// Native wrapper for the SaleSmartly dedicated-link H5 page.
private struct SalesmartlyServiceWebView: UIViewRepresentable {
    let serviceURL: URL
    let loginInfo: [String: Any]
    let isPresented: Bool
    let retryToken: Int
    let onUnreadCount: (Int) -> Void
    let onStatus: (ChatConnectionState) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            serviceURL: serviceURL,
            loginInfo: loginInfo,
            onUnreadCount: onUnreadCount,
            onStatus: onStatus
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "salesmartlyBridge")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        let request = URLRequest(
            url: serviceURL,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 30
        )
        webView.load(request)
        context.coordinator.updatePresentation(isPresented, in: webView)
        context.coordinator.updateRetryToken(retryToken, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.updatePresentation(isPresented, in: webView)
        context.coordinator.updateRetryToken(retryToken, in: webView)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "salesmartlyBridge")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        private static let logger = Logger(subsystem: "com.thrustwealth.app", category: "SaleSmartly")
        private let serviceURL: URL
        private let serviceHost: String?
        private let loginInfo: [String: Any]
        private let onUnreadCount: (Int) -> Void
        private let onStatus: (ChatConnectionState) -> Void
        private var didSendLogin = false
        private var pageLoaded = false
        private var requestedPresentation = false
        private var sentPresentation: Bool?
        private var lastRetryToken = 0

        init(
            serviceURL: URL,
            loginInfo: [String: Any],
            onUnreadCount: @escaping (Int) -> Void,
            onStatus: @escaping (ChatConnectionState) -> Void
        ) {
            self.serviceURL = serviceURL
            self.serviceHost = serviceURL.host
            self.loginInfo = loginInfo
            self.onUnreadCount = onUnreadCount
            self.onStatus = onStatus
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            didSendLogin = false
            pageLoaded = false
            sentPresentation = nil
            onStatus(.loading)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard webView.url?.host == serviceHost else { return }
            pageLoaded = true
            Self.logger.info("H5 page loaded")
            onStatus(.loading)
            guard !didSendLogin else { return }
            sendLoginInfo(to: webView)
            sendPresentationIfNeeded(to: webView)
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            Self.logger.error("H5 navigation failed: \(error.localizedDescription, privacy: .public)")
            onStatus(.failed("Support page failed to load. Check your connection and try again."))
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            Self.logger.error("H5 provisional navigation failed: \(error.localizedDescription, privacy: .public)")
            onStatus(.failed("Support service is unavailable. Check your connection and try again."))
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            if navigationAction.navigationType == .linkActivated,
               url.host != webView.url?.host {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "salesmartlyBridge",
                  let payload = message.body as? [String: Any],
                  let type = payload["type"] as? String else {
                return
            }

            switch type {
            case "unread":
                let count = (payload["count"] as? NSNumber)?.intValue ?? 0
                Self.logger.info("Unread count updated: \(count)")
                DispatchQueue.main.async { [onUnreadCount] in
                    onUnreadCount(count)
                }
            case "received":
                Self.logger.info("Agent message received by H5")
            case "diagnostic":
                let stage = payload["stage"] as? String ?? "unknown"
                Self.logger.info("H5 stage: \(stage, privacy: .public)")
                updateStatus(for: stage)
            default:
                Self.logger.debug("Ignored bridge message: \(type, privacy: .public)")
            }
        }

        func updatePresentation(_ isPresented: Bool, in webView: WKWebView) {
            requestedPresentation = isPresented
            sendPresentationIfNeeded(to: webView)
        }

        func updateRetryToken(_ token: Int, in webView: WKWebView) {
            guard token != lastRetryToken else { return }
            lastRetryToken = token
            webView.load(URLRequest(
                url: serviceURL,
                cachePolicy: .reloadIgnoringLocalCacheData,
                timeoutInterval: 30
            ))
        }

        private func updateStatus(for stage: String) {
            switch stage {
            case "sdk-ready":
                onStatus(.signingIn)
            case "login-success", "chat-open-success":
                if stage == "chat-open-success" {
                    onUnreadCount(0)
                }
                onStatus(.ready)
            case "sdk-load-failed":
                onStatus(.failed("Support component failed to load. Check your connection and try again."))
            case "login-failed":
                onStatus(.failed("Support sign-in failed. Please try again."))
            case "chat-open-failed":
                onStatus(.failed("Support chat failed to open. Please try again."))
            default:
                break
            }
        }

        private func sendLoginInfo(to webView: WKWebView) {
            guard JSONSerialization.isValidJSONObject(loginInfo),
                  let data = try? JSONSerialization.data(withJSONObject: loginInfo),
                  let loginJSON = String(data: data, encoding: .utf8) else {
                return
            }

            // The hosted H5 bridge receives this JSON string and registers the
            // SaleSmartly unread callback after it creates the SDK queue.
            let script = """
            (function () {
              window.postMessage(JSON.stringify({ type: 'service-link-login', version: 1, payload: \(loginJSON) }), window.location.origin);
            })();
            """
            webView.evaluateJavaScript(script) { _, error in
                DispatchQueue.main.async {
                    if let error {
                        Self.logger.error("Failed to send app identity: \(error.localizedDescription, privacy: .public)")
                        self.didSendLogin = false
                        self.onStatus(.failed("Support identity initialization failed. Please try again."))
                    } else {
                        self.didSendLogin = true
                        Self.logger.info("App identity sent to H5")
                    }
                }
            }
        }

        private func sendPresentationIfNeeded(to webView: WKWebView) {
            guard pageLoaded, sentPresentation != requestedPresentation else { return }
            sentPresentation = requestedPresentation
            let type = requestedPresentation ? "service-link-open" : "service-link-close"
            let script = """
            (function () {
              window.postMessage(JSON.stringify({ type: '\(type)', version: 1 }), window.location.origin);
            })();
            """
            webView.evaluateJavaScript(script) { _, error in
                DispatchQueue.main.async {
                    if let error {
                        self.sentPresentation = nil
                        Self.logger.error("Failed to send presentation state: \(error.localizedDescription, privacy: .public)")
                        self.onStatus(.failed("Support window state could not be updated. Please retry."))
                    } else {
                        Self.logger.info("Sent H5 command: \(type, privacy: .public)")
                    }
                }
            }
        }
    }
}
