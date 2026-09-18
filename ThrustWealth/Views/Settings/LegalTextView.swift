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
                        section("Your Privacy", "Thrust Wealth is a standalone offline utility. No trade entries, balance numbers, or calculation parameters are transmitted to any remote servers. All data remains exclusively in your device's local storage.")
                        section("Data Retention", "You may export or permanently purge all history and journal records at any time from the Settings tab.")
                    case .terms:
                        section("About This Tool", "Thrust Wealth provides mathematical calculations based on standard contract specifications. It does not provide trade executions, investment recommendations, or portfolio guarantees.")
                        section("Risk of Capital Loss", "Trading financial contracts (Forex, CFDs, precious metals) involves significant market risk. Users are solely responsible for setting appropriate stop-loss orders with their executing brokers.")
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
