import SwiftUI

struct EmptyStateView: View {
    var systemImage: String
    var title: String
    var description: String
    var assetName: String? = nil

    @Environment(\.themed) private var themed

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            if let assetName, UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 100)
                    .opacity(0.6)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(themed.textMuted)
                    .frame(width: 120, height: 100)
            }

            Text(title)
                .font(Theme.Fonts.sans(16, weight: .bold))
                .foregroundStyle(themed.textPrimary)

            Text(description)
                .font(Theme.Fonts.sans(13))
                .foregroundStyle(themed.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
        }
        .padding(.vertical, Theme.Spacing.xxxl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
