import SwiftUI

struct ComplianceDisclaimer: View {
    var text: String = "For calculation purposes only. Not investment advice, financial promotion, or a guarantee of returns."

    @Environment(\.themed) private var themed

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "shield")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(themed.textMuted)
                .padding(.top, 1)

            Text(text)
                .font(Theme.Fonts.sans(11))
                .foregroundStyle(themed.disclaimerText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Disclaimer: \(text)")
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themed.disclaimerBg)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .strokeBorder(themed.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }
}
