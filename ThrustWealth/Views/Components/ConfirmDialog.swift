import SwiftUI

struct ConfirmDialog: View {
    let title: String
    let message: String
    var confirmTitle: String = "Confirm"
    var isDestructive: Bool = true
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @Environment(\.themed) private var themed

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isDestructive ? Theme.Colors.lossBg : Theme.Colors.accentSubtle)
                        .frame(width: 58, height: 58)
                    Image(systemName: isDestructive ? "trash" : "exclamationmark.triangle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isDestructive ? Theme.Colors.loss : Theme.Colors.warn)
                }
                .padding(.bottom, Theme.Spacing.md)

                Text(title)
                    .font(Theme.Fonts.sans(18, weight: .heavy))
                    .foregroundStyle(themed.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)

                Text(message)
                    .font(Theme.Fonts.sans(13.5))
                    .foregroundStyle(themed.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)

                HStack(spacing: 10) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(Theme.Fonts.sans(14, weight: .bold))
                            .foregroundStyle(themed.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(themed.bgSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                    .strokeBorder(themed.borderMedium, lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        onConfirm()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }) {
                        Text(confirmTitle)
                            .font(Theme.Fonts.sans(14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(isDestructive ? Theme.Colors.loss : Theme.Colors.brandPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Theme.Colors.brandPrimary)
                    .frame(height: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.35), radius: 24, y: 8)
        }
    }
}

struct ToastBanner: View {
    let message: String

    @Environment(\.themed) private var themed

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(themed.accentText)
                .frame(width: 7, height: 7)
            Text(message)
                .font(Theme.Fonts.sans(13, weight: .bold))
                .foregroundStyle(themed.textPrimary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial)
        .overlay(
            Capsule().strokeBorder(Theme.Colors.brandPrimary.opacity(0.3), lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}
