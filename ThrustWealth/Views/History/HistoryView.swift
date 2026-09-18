import SwiftUI

struct HistoryView: View {
    var onRestore: ((CalculationRecord) -> Void)?
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = HistoryViewModel()
    @Environment(\.themed) private var themed
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Automatically saved locally (last 50 calculations). Tap any record to restore its parameters to the calculator.")
                        .font(Theme.Fonts.sans(13))
                        .foregroundStyle(themed.textTertiary)

                    if vm.records.isEmpty {
                        EmptyStateView(
                            systemImage: "clock",
                            title: "No history yet",
                            description: "Save a calculation from the Lot Size Calculator to see it here.",
                            assetName: "EmptyHistory"
                        )
                    } else {
                        ForEach(vm.grouped) { group in
                            Text(group.title)
                                .font(Theme.Fonts.sans(10.5, weight: .heavy))
                                .tracking(0.7)
                                .foregroundStyle(themed.textMuted)
                                .padding(.top, Theme.Spacing.sm)

                            ForEach(group.items) { record in
                                historyRow(record)
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
            }

            if vm.showClearConfirm {
                ConfirmDialog(
                    title: "Clear History?",
                    message: "This will permanently delete all saved calculations.",
                    confirmTitle: "Clear All",
                    onConfirm: {
                        vm.clearAll()
                        vm.showClearConfirm = false
                    },
                    onCancel: { vm.showClearConfirm = false }
                )
            }

            if let toast = vm.toastMessage {
                VStack {
                    ToastBanner(message: toast).padding(.top, 12)
                    Spacer()
                }
            }
        }
        .background(ThemedColors.resolve(for: colorScheme).bgApp.ignoresSafeArea())
        .environment(\.themed, ThemedColors.resolve(for: colorScheme))
        .navigationTitle("Calculation History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { vm.exportCSV() } label: { Image(systemName: "square.and.arrow.up") }
                Button { vm.showClearConfirm = true } label: { Image(systemName: "trash") }
            }
        }
        .onAppear { vm.load() }
    }

    private func historyRow(_ record: CalculationRecord) -> some View {
        Button {
            if let onRestore {
                onRestore(record)
                dismiss()
            } else {
                appState.restorePayload = record
                dismiss()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.symbol)
                        .font(Theme.Fonts.mono(14.5, weight: .heavy))
                        .foregroundStyle(themed.textPrimary)
                    Text("Risk \(Formatters.percent(record.riskPercent)) · SL \(String(format: "%.0f", record.stopPips)) pips")
                        .font(Theme.Fonts.mono(11.5))
                        .foregroundStyle(themed.textTertiary)
                    Text(timeString(record.date))
                        .font(Theme.Fonts.sans(11))
                        .foregroundStyle(themed.textMuted)
                }
                Spacer()
                Text("\(Formatters.lots(record.suggestedLots)) lots")
                    .font(Theme.Fonts.mono(13.5, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.brandPrimary)
                    .clipShape(Capsule())

                Button {
                    vm.delete(id: record.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(themed.textMuted)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.md)
            .background(
                LinearGradient(colors: [themed.bgSurfaceElevated, themed.bgSurface], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(themed.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
