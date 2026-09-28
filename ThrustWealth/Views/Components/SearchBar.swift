import SwiftUI
import UIKit

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var isLoading: Bool = false
    var onClear: (() -> Void)? = nil
    var onSubmit: (() -> Void)? = nil

    @Environment(\.themed) private var themed
    @State private var isEditing = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.75)
                    .frame(width: 14, height: 14)
            } else {
                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isEditing ? Theme.Colors.brandPrimary : themed.textTertiary)
                        .scaleEffect(isEditing ? 1.08 : 1)
                        .frame(width: 28, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search")
            }

            CenteredSearchTextField(
                text: $text,
                placeholder: placeholder,
                textColor: UIColor(themed.textPrimary),
                placeholderColor: UIColor(themed.textMuted),
                tintColor: UIColor(Theme.Colors.brandPrimary),
                isEditing: isEditing,
                onEditingChanged: { isEditing = $0 },
                onSubmit: { onSubmit?() }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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
        .frame(height: 44)
        .background(isEditing ? Theme.Colors.brandPrimary.opacity(0.10) : themed.bgSurface)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(
                    isEditing ? Theme.Colors.brandPrimary : themed.borderSubtle,
                    lineWidth: isEditing ? 1.5 : 1
                )
        }
        .shadow(color: isEditing ? Theme.Colors.brandPrimary.opacity(0.35) : .clear, radius: isEditing ? 6 : 0, y: 0)
        .animation(.easeOut(duration: 0.16), value: isEditing)
    }
}

/// UITextField keeps the caret vertically centered. SwiftUI TextField in a fixed-height capsule sits high.
private struct CenteredSearchTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var textColor: UIColor
    var placeholderColor: UIColor
    var tintColor: UIColor
    var isEditing: Bool
    var onEditingChanged: (Bool) -> Void
    var onSubmit: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.contentVerticalAlignment = .center
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .search
        field.font = .systemFont(ofSize: 13.5)
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        if field.text != text {
            field.text = text
        }
        field.textColor = textColor
        field.tintColor = tintColor
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: placeholderColor, .font: UIFont.systemFont(ofSize: 13.5)]
        )
        // Resigning here cancels the tap that just made the field first responder,
        // because FocusState is still false until textFieldDidBeginEditing runs.
        guard isEditing, !field.isFirstResponder else { return }
        DispatchQueue.main.async {
            guard field.window != nil, !field.isFirstResponder else { return }
            field.becomeFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CenteredSearchTextField

        init(parent: CenteredSearchTextField) {
            self.parent = parent
        }

        @objc func editingChanged(_ field: UITextField) {
            parent.text = field.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            guard !parent.isEditing else { return }
            parent.onEditingChanged(true)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            guard parent.isEditing else { return }
            parent.onEditingChanged(false)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
            textField.resignFirstResponder()
            return true
        }
    }
}
