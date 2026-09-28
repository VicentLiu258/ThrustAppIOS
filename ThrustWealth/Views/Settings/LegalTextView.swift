import SwiftUI
import WebKit

enum LegalConfig {
    static let privacyPolicyURL = "https://www.thrustwealth.com/legal/privacy-policy"
    static let termsOfUseURL = "https://www.thrustwealth.com/legal/terms-of-use"
}

enum LegalKind: String, Identifiable, CaseIterable {
    case privacy
    case terms
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: return "Privacy Policy"
        case .terms: return "Terms of Use"
        case .about: return "About Thrust Wealth"
        }
    }

    var webURL: URL? {
        switch self {
        case .privacy: return URL(string: LegalConfig.privacyPolicyURL)
        case .terms: return URL(string: LegalConfig.termsOfUseURL)
        case .about: return nil
        }
    }
}

struct LegalTextView: View {
    let kind: LegalKind
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themed) private var themed
    @State private var showOfflineFallback = false

    var body: some View {
        NavigationStack {
            ZStack {
                themed.bgApp.ignoresSafeArea()

                switch kind {
                case .privacy, .terms:
                    if let url = kind.webURL, !showOfflineFallback {
                        LegalWebContentView(url: url) {
                            showOfflineFallback = true
                        }
                    } else {
                        offlineContent
                    }
                case .about:
                    aboutContent
                }
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }

                if let url = kind.webURL {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                UIApplication.shared.open(url)
                            } label: {
                                Label("Open in Browser", systemImage: "safari")
                            }

                            if showOfflineFallback {
                                Button {
                                    showOfflineFallback = false
                                } label: {
                                    Label("View Online Page", systemImage: "globe")
                                }
                            } else {
                                Button {
                                    showOfflineFallback = true
                                } label: {
                                    Label("View Offline Summary", systemImage: "doc.text")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 16))
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .thrustTheme()
    }

    // MARK: - About Content

    private var aboutContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if UIImage(named: "Logo") != nil {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 36)
                        .frame(maxWidth: 180)
                } else {
                    Text("Thrust Wealth")
                        .font(Theme.Fonts.sans(22, weight: .heavy))
                        .foregroundStyle(Theme.Colors.brandPrimary)
                }
                Text("Thrust Wealth — Risk & Position Utility")
                    .font(Theme.Fonts.sans(15, weight: .bold))
                    .foregroundStyle(themed.textPrimary)
                Text("Version 1.0.0 (Build 2026.09)")
                    .font(Theme.Fonts.sans(12))
                    .foregroundStyle(themed.textTertiary)
                Text("A professional risk management and position sizing utility designed for active traders who prioritise disciplined risk management.")
                    .font(Theme.Fonts.sans(13))
                    .foregroundStyle(themed.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.xl)
        }
    }

    // MARK: - Offline Fallback Content

    private var offlineContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch kind {
                case .privacy:
                    section(
                        "Your Privacy",
                        "Thrust Wealth is primarily a standalone offline utility. Trade entries, balance numbers, and calculation parameters are stored on your device and are not uploaded to Thrust Wealth servers."
                    )
                    section(
                        "Online Document",
                        "The full and updated Privacy Policy is available online at: \(LegalConfig.privacyPolicyURL)"
                    )
                    section(
                        "Data Retention",
                        "You may export or permanently purge all history and journal records at any time from the Settings tab."
                    )
                    section(
                        "Optional Support Chat (SaleSmartly)",
                        """
                        If you use in-app Contact Support, the chat feature is provided by SaleSmartly's service-link web page (Guangzhou Biaopin Software Co., Ltd.).

                        Purpose: online customer support inside the App.

                        Data that may be collected by the SDK for basic chat functionality:
                        • Device and system information (OS type/version, app bundle ID/version, device type/manufacturer/model, network type)
                        • Network identity information (IP address)

                        Optional data, collected only when you actively send attachments in chat:
                        • Images and videos you choose to upload

                        Collection method: collected by the SDK after you agree to this Privacy Policy.

                        Permissions used on iOS:
                        • User Notifications (optional) — unread support message alerts
                        • UserDefaults / local storage — session ID and unread counts inside the app sandbox
                        • Privacy Accessed API Category: NSPrivacyAccessedAPICategoryUserDefaults

                        Official site: https://www.salesmartly.cn
                        SaleSmartly native SDK privacy policy: https://www.salesmartly.com/html/sdk/privacy_native_cn.html

                        The SDK is initialized only after you tap Agree on the first-launch privacy consent screen. Declining consent keeps calculator features available without support chat networking.
                        """
                    )
                    section(
                        "Attribution (AppsFlyer)",
                        """
                        After you agree, AppsFlyer measures installs and in-app actions such as search navigation (event af_ic) and phone submissions in support chat (event af_whats_leads). The phone number itself is not sent to AppsFlyer.

                        Data that may be collected: device identifiers, app version, IP address, and the search destination you open.

                        Collection starts only after privacy consent.
                        Privacy policy: https://www.appsflyer.com/legal/privacy-policy/
                        """
                    )
                case .terms:
                    section("About This Tool", "Thrust Wealth provides mathematical calculations based on standard contract specifications. It does not provide trade executions, investment recommendations, or portfolio guarantees.")
                    section(
                        "Online Document",
                        "The full and updated Terms of Use are available online at: \(LegalConfig.termsOfUseURL)"
                    )
                    section("Risk of Capital Loss", "Trading financial contracts (Forex, CFDs, precious metals) involves significant market risk. Users are solely responsible for setting appropriate stop-loss orders with their executing brokers.")
                    section("Support Chat", "In-app support chat is an optional assistance channel. Messages you send may be processed by SaleSmartly and our support staff to respond to your inquiry. Support chat does not constitute investment advice.")
                case .about:
                    EmptyView()
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private func section(_ heading: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(heading)
                .font(Theme.Fonts.sans(16, weight: .bold))
                .foregroundStyle(themed.textPrimary)
            Text(body)
                .font(Theme.Fonts.sans(14))
                .foregroundStyle(themed.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Web Content View

private struct LegalWebContentView: View {
    let url: URL
    let onFallbackRequest: () -> Void

    @State private var isLoading = true
    @State private var loadProgress: Double = 0.0
    @State private var hasError = false
    @State private var reloadToken = 0
    @Environment(\.themed) private var themed

    var body: some View {
        ZStack(alignment: .top) {
            LegalWKWebView(
                url: url,
                reloadToken: reloadToken,
                isLoading: $isLoading,
                progress: $loadProgress,
                hasError: $hasError
            )

            if isLoading {
                ProgressView(value: loadProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: Theme.Colors.brandPrimary))
                    .frame(height: 2)
                    .zIndex(1)
            }

            if hasError {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundStyle(themed.textTertiary)

                    Text("Unable to Load Web Page")
                        .font(Theme.Fonts.sans(16, weight: .bold))
                        .foregroundStyle(themed.textPrimary)

                    Text("Please check your internet connection or view the offline summary.")
                        .font(Theme.Fonts.sans(13))
                        .foregroundStyle(themed.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 12) {
                        Button("Retry") {
                            hasError = false
                            reloadToken += 1
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.Colors.brandPrimary)

                        Button("View Offline Summary") {
                            onFallbackRequest()
                        }
                        .buttonStyle(.bordered)
                        .tint(themed.textPrimary)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(themed.bgApp)
                .zIndex(2)
            }
        }
    }
}

private struct LegalWKWebView: UIViewRepresentable {
    let url: URL
    let reloadToken: Int
    @Binding var isLoading: Bool
    @Binding var progress: Double
    @Binding var hasError: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        context.coordinator.observeProgress(webView)

        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 15)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.lastReloadToken != reloadToken {
            context.coordinator.lastReloadToken = reloadToken
            let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 15)
            uiView.load(request)
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.cleanup()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: LegalWKWebView
        var lastReloadToken = 0
        private var observation: NSKeyValueObservation?

        init(_ parent: LegalWKWebView) {
            self.parent = parent
        }

        func observeProgress(_ webView: WKWebView) {
            observation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.parent.progress = webView.estimatedProgress
                    self.parent.isLoading = webView.estimatedProgress < 1.0
                }
            }
        }

        func cleanup() {
            observation?.invalidate()
            observation = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.hasError = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.hasError = true
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            if nsError.code != NSURLErrorCancelled {
                parent.isLoading = false
                parent.hasError = true
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let targetURL = navigationAction.request.url {
                let scheme = targetURL.scheme?.lowercased() ?? ""
                if scheme != "http" && scheme != "https" && scheme != "about" {
                    if UIApplication.shared.canOpenURL(targetURL) {
                        UIApplication.shared.open(targetURL, options: [:], completionHandler: nil)
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        deinit {
            cleanup()
        }
    }
}
