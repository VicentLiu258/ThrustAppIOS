import SwiftUI

struct SymbolPickerSheet: View {
    let instruments: [Instrument]
    let selectedID: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themed) private var themed
    @State private var query = ""

    private var filtered: [Instrument] {
        let q = query.lowercased()
        if q.isEmpty { return instruments }
        return instruments.filter {
            $0.id.lowercased().contains(q) || $0.name.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $query, placeholder: "Search symbol or name...")
                    .padding(Theme.Spacing.lg)

                List {
                    ForEach(filtered) { inst in
                        Button {
                            onSelect(inst.id)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(inst.id)
                                        .font(Theme.Fonts.mono(15, weight: .heavy))
                                        .foregroundStyle(themed.textPrimary)
                                    Text(inst.name)
                                        .font(Theme.Fonts.sans(12))
                                        .foregroundStyle(themed.textTertiary)
                                }
                                Spacer()
                                Text(inst.contractHint)
                                    .font(Theme.Fonts.mono(12))
                                    .foregroundStyle(themed.textSecondary)
                                if selectedID == inst.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.Colors.brandPrimary)
                                        .padding(.leading, 8)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(themed.bgSurface)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(themed.bgApp)
            .navigationTitle("Select Instrument")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .thrustTheme()
    }
}
