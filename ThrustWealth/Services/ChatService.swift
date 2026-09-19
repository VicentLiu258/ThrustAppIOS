import Foundation
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

    private static let guestIDKey = "thrust_wealth_salesmartly_guest_id"

    private init() {}

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
        isChatPresented = true
    }

    func dismissChat() {
        isChatPresented = false
    }

    /// Called after local data is purged, so the next chat session starts with
    /// a fresh SaleSmartly visitor identity.
    func resetAfterDataPurge() {
        UserDefaults.standard.removeObject(forKey: Self.guestIDKey)
        unreadCount = 0
        isChatPresented = false
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
            "user_id": persistedGuestUserId(),
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
        unreadCount = max(0, count)
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
                        onUnreadCount: chatService.setUnreadCount
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
        }
    }
}

/// Native wrapper for the SaleSmartly dedicated-link H5 page.
private struct SalesmartlyServiceWebView: UIViewRepresentable {
    let serviceURL: URL
    let loginInfo: [String: Any]
    let onUnreadCount: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(loginInfo: loginInfo, onUnreadCount: onUnreadCount)
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
        webView.load(URLRequest(url: serviceURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "salesmartlyBridge")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        private let loginInfo: [String: Any]
        private let onUnreadCount: (Int) -> Void
        private var didSendLogin = false

        init(loginInfo: [String: Any], onUnreadCount: @escaping (Int) -> Void) {
            self.loginInfo = loginInfo
            self.onUnreadCount = onUnreadCount
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !didSendLogin else { return }
            didSendLogin = true
            sendLoginInfo(to: webView)
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
                  payload["type"] as? String == "unread" else {
                return
            }
            let count = (payload["count"] as? NSNumber)?.intValue ?? 0
            DispatchQueue.main.async { [onUnreadCount] in
                onUnreadCount(count)
            }
        }

        private func sendLoginInfo(to webView: WKWebView) {
            guard JSONSerialization.isValidJSONObject(loginInfo),
                  let data = try? JSONSerialization.data(withJSONObject: loginInfo),
                  let loginJSON = String(data: data, encoding: .utf8) else {
                return
            }

            // The service page expects a JSON *string* with this shape. Register
            // the unread listener before posting so its callback is queued with ssq.
            let script = """
            (function () {
              window.ssq = window.ssq || [];
              window.ssq.push('onUnRead', function (value) {
                var count = value && Number(value.num);
                if (window.webkit && window.webkit.messageHandlers.salesmartlyBridge) {
                  window.webkit.messageHandlers.salesmartlyBridge.postMessage({ type: 'unread', count: isNaN(count) ? 0 : count });
                }
              });
              window.postMessage(JSON.stringify({ type: 'service-link-login', version: 1, payload: \(loginJSON) }), window.location.origin);
            })();
            """
            webView.evaluateJavaScript(script)
        }
    }
}
