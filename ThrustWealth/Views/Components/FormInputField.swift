import SwiftUI

struct FormInputField: View {
    let label: String
    var hint: String? = nil
    var prefix: String? = nil
    var suffix: String? = nil
    @Binding var text: String
    var keyboard: UIKeyboardType = .decimalPad
    var isError: Bool = false
    var errorMessage: String? = nil
    var isDisabled: Bool = false

    @Environment(\.themed) private var themed
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label.uppercased())
                    .font(Theme.Fonts.sans(11.5, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(focused ? themed.accentText : themed.textTertiary)
                Spacer()
                if let hint {
                    Text(hint)
                        .font(Theme.Fonts.sans(11))
                        .foregroundStyle(themed.textMuted)
                }
            }

            HStack(spacing: 0) {
                if let prefix {
                    Text(prefix)
                        .font(Theme.Fonts.mono(14, weight: .bold))
                        .foregroundStyle(focused ? themed.accentText : themed.textTertiary)
                        .padding(.leading, Theme.Spacing.md)
                }

                TextField("", text: $text)
                    .keyboardType(keyboard)
                    .font(Theme.Fonts.mono(15, weight: .bold))
                    .foregroundStyle(themed.textPrimary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .frame(height: 46)
                    .focused($focused)
                    .disabled(isDisabled)
                    .accessibilityLabel(label)

                if let suffix {
                    Text(suffix)
                        .font(Theme.Fonts.mono(14, weight: .bold))
                        .foregroundStyle(focused ? themed.accentText : themed.textTertiary)
                        .padding(.trailing, Theme.Spacing.md)
                }
            }
            .background(themed.bgSurface)
            .overlay(alignment: .leading) {
                if focused {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Colors.brandPrimary)
                        .frame(width: 3)
                        .padding(.vertical, 8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(
                        isError ? Theme.Colors.loss : (focused ? Theme.Colors.brandPrimary.opacity(0.45) : themed.borderSubtle),
                        lineWidth: 1.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .opacity(isDisabled ? 0.55 : 1)

            if isError, let errorMessage {
                Text(errorMessage)
                    .font(Theme.Fonts.sans(11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.loss)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Theme.Colors.lossBg)
                    .clipShape(Capsule())
            }
        }
    }
}

struct FormDropdownField: View {
    let label: String
    var hint: String? = nil
    let value: String
    let action: () -> Void

    @Environment(\.themed) private var themed

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label.uppercased())
                    .font(Theme.Fonts.sans(11.5, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(themed.textTertiary)
                Spacer()
                if let hint {
                    Text(hint)
                        .font(Theme.Fonts.sans(11))
                        .foregroundStyle(themed.textMuted)
                }
            }

            Button(action: action) {
                HStack {
                    Text(value)
                        .font(Theme.Fonts.sans(15, weight: .bold))
                        .foregroundStyle(themed.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(themed.textTertiary)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .frame(height: 46)
                .background(themed.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .strokeBorder(themed.borderSubtle, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label): \(value)")
        }
    }
}
