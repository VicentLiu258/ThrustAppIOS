import SwiftUI

/// First-launch privacy consent gate required before SaleSmartly SDK initialization.
struct PrivacyConsentView: View {
    let onAccept: () -> Void
    let onViewPrivacy: () -> Void

    @Environment(\.themed) private var themed
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            themed.bgApp.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(spacing: Theme.Spacing.lg) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Theme.Colors.brandPrimary)

                    Text("Privacy & Support Chat")
                        .font(Theme.Fonts.sans(22, weight: .heavy))
                        .foregroundStyle(themed.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Thrust Wealth stores calculations locally on your device. Optional in-app support chat is powered by SaleSmartly and collects limited device information only after you agree.")
                        .font(Theme.Fonts.sans(14))
                        .foregroundStyle(themed.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 10) {
                        bullet("Local calculator data stays on device")
                        bullet("Support chat may collect OS version, app version, device model, network type, and IP address")
                        bullet("Images/videos are sent only when you choose to attach them in chat")
                    }
                    .padding(Theme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(themed.bgSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                            .strokeBorder(themed.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                }
                .padding(.horizontal, Theme.Spacing.lg)

                Spacer(minLength: 24)

                VStack(spacing: Theme.Spacing.sm) {
                    Button(action: onAccept) {
                        Text("Agree & Continue")
                            .font(Theme.Fonts.sans(16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.brandPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: onViewPrivacy) {
                        Text("View Privacy Policy")
                            .font(Theme.Fonts.sans(14, weight: .semibold))
                            .foregroundStyle(themed.accentText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    Text("By continuing you agree to the Privacy Policy and Terms of Service. You can open support chat later from Settings.")
                        .font(Theme.Fonts.sans(11))
                        .foregroundStyle(themed.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .environment(\.themed, ThemedColors.resolve(for: colorScheme))
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(Theme.Fonts.sans(14, weight: .bold))
                .foregroundStyle(Theme.Colors.brandPrimary)
            Text(text)
                .font(Theme.Fonts.sans(13))
                .foregroundStyle(themed.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
