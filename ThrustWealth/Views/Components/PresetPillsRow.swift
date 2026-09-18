import SwiftUI

struct PresetPillsRow: View {
    let presets: [Double]
    @Binding var selected: Double
    let onSelect: (Double) -> Void

    @Environment(\.themed) private var themed

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(presets, id: \.self) { value in
                let isActive = abs(selected - value) < 0.001
                Button {
                    selected = value
                    onSelect(value)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f%%" : "%.1f%%", value))
                        .font(Theme.Fonts.mono(12, weight: isActive ? .bold : .semibold))
                        .foregroundStyle(isActive ? .white : themed.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(isActive ? Theme.Colors.brandPrimary : themed.bgSurface)
                        .overlay(
                            Capsule().strokeBorder(isActive ? Color.clear : themed.borderSubtle, lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
