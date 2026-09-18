import SwiftUI

struct ThrustSegmentedControl<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    var longShortStyle: Bool = false

    @Environment(\.themed) private var themed

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { option in
                let isActive = selection == option.0
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selection = option.0
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(option.1)
                        .font(Theme.Fonts.sans(13, weight: isActive ? .bold : .semibold))
                        .foregroundStyle(labelColor(option: option.0, isActive: isActive))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(background(option: option.0, isActive: isActive))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg - 3, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.lg - 3, style: .continuous)
                                .strokeBorder(borderColor(option: option.0, isActive: isActive), lineWidth: longShortStyle && isActive ? 1 : 0)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(themed.bgSurface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .strokeBorder(themed.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func labelColor(option: T, isActive: Bool) -> Color {
        guard isActive else { return themed.textTertiary }
        if longShortStyle, let dir = option as? TradeDirection {
            return dir == .long ? Theme.Colors.profit : Theme.Colors.loss
        }
        return .white
    }

    @ViewBuilder
    private func background(option: T, isActive: Bool) -> some View {
        if isActive {
            if longShortStyle, let dir = option as? TradeDirection {
                (dir == .long ? Theme.Colors.profit : Theme.Colors.loss).opacity(0.18)
            } else {
                Theme.Colors.brandPrimary
            }
        } else {
            Color.clear
        }
    }

    private func borderColor(option: T, isActive: Bool) -> Color {
        guard isActive, longShortStyle, let dir = option as? TradeDirection else { return .clear }
        return dir == .long ? Theme.Colors.profitBorder : Theme.Colors.lossBorder
    }
}
