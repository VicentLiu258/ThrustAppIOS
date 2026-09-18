import SwiftUI
import UIKit

/// Floating action button for customer support chat, styled after the SaleSmartly launcher.
/// Positioned at the bottom-trailing corner of the home view with unread badge and haptic feedback.
struct FloatingChatButton: View {
    let unreadCount: Int
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            ZStack(alignment: .topTrailing) {
                // Main circular floating button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: 0x4B82F6), // Sky blue
                                Color(hex: 0x2563EB)  // Vibrant royal blue
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "ellipsis.message.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: Color(hex: 0x2563EB).opacity(0.38), radius: 8, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.12), radius: 3, x: 0, y: 1)

                // Unread notification badge
                if unreadCount > 0 {
                    badgeView
                        .offset(x: 3, y: -3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(FloatingPressStyle())
        .accessibilityLabel("Support Chat")
        .accessibilityValue(unreadCount > 0 ? "\(unreadCount) unread messages" : "No unread messages")
        .accessibilityHint("Opens customer support chat")
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: unreadCount)
    }

    private var badgeView: some View {
        let badgeText = unreadCount > 99 ? "99+" : "\(unreadCount)"
        return Text(badgeText)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, unreadCount > 9 ? 5 : 0)
            .frame(minWidth: 19, minHeight: 19)
            .background(Color(hex: 0xEF4444))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
    }
}

private struct FloatingPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

#Preview("FloatingChatButton - States") {
    VStack(spacing: 30) {
        HStack(spacing: 30) {
            FloatingChatButton(unreadCount: 2, action: {})
            FloatingChatButton(unreadCount: 0, action: {})
            FloatingChatButton(unreadCount: 120, action: {})
        }
    }
    .padding(40)
    .background(Color(hex: 0x060A12))
}
