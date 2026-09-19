import SwiftUI

enum LegalKind {
    case privacy, terms, about
}

struct LegalTextView: View {
    let kind: LegalKind
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themed) private var themed

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch kind {
                    case .privacy:
                        section(
                            "Your Privacy",
                            "Thrust Wealth is primarily a standalone offline utility. Trade entries, balance numbers, and calculation parameters are stored on your device and are not uploaded to Thrust Wealth servers."
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
                    case .terms:
                        section("About This Tool", "Thrust Wealth provides mathematical calculations based on standard contract specifications. It does not provide trade executions, investment recommendations, or portfolio guarantees.")
                        section("Risk of Capital Loss", "Trading financial contracts (Forex, CFDs, precious metals) involves significant market risk. Users are solely responsible for setting appropriate stop-loss orders with their executing brokers.")
                        section("Support Chat", "In-app support chat is an optional assistance channel. Messages you send may be processed by SaleSmartly and our support staff to respond to your inquiry. Support chat does not constitute investment advice.")
                    case .about:
                        VStack(spacing: 12) {
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
                        .padding(.vertical, 16)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(themed.bgApp)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .thrustTheme()
    }

    private var title: String {
        switch kind {
        case .privacy: return "Privacy Policy"
        case .terms: return "Terms of Service"
        case .about: return "About Thrust Wealth"
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
