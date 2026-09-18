import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onClear: (() -> Void)? = nil

    @Environment(\.themed) private var themed
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(focused ? Theme.Colors.brandPrimary : themed.textTertiary)

            TextField(placeholder, text: $text)
                .font(Theme.Fonts.sans(13.5))
                .foregroundStyle(themed.textPrimary)
                .focused($focused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    text = ""
                    onClear?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(themed.textMuted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(themed.bgSurface)
        .overlay(
            Capsule()
                .strokeBorder(focused ? Theme.Colors.brandPrimary : themed.borderSubtle, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}
