import SwiftUI

struct QuickSymbolBar: View {
    let symbols: [String]
    @Binding var selected: String
    let onSelect: (String) -> Void

    @Environment(\.themed) private var themed

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(symbols, id: \.self) { symbol in
                    let isActive = selected == symbol
                    Button {
                        selected = symbol
                        onSelect(symbol)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(symbol)
                            .font(Theme.Fonts.mono(12, weight: isActive ? .heavy : .bold))
                            .foregroundStyle(isActive ? .white : themed.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(isActive ? Theme.Colors.brandPrimary : themed.bgSurfaceElevated)
                            .overlay(
                                Capsule().strokeBorder(isActive ? Color.clear : themed.borderSubtle, lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, 10)
        }
        .background(themed.bgSurface)
        .overlay(alignment: .top) {
            Rectangle().fill(themed.borderSubtle).frame(height: 1)
        }
    }
}
