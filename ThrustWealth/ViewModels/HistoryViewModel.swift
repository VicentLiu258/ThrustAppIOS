import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var records: [CalculationRecord] = []
    @Published var showClearConfirm = false
    @Published var toastMessage: String?

    struct DayGroup: Identifiable {
        var id: String { title }
        var title: String
        var items: [CalculationRecord]
    }

    var grouped: [DayGroup] {
        let calendar = Calendar.current
        let groupedDict = Dictionary(grouping: records) { record -> String in
            let date = record.date
            if calendar.isDateInToday(date) { return "TODAY" }
            if calendar.isDateInYesterday(date) { return "YESTERDAY" }
            let f = DateFormatter()
            f.dateStyle = .medium
            return f.string(from: date).uppercased()
        }
        let order = ["TODAY", "YESTERDAY"]
        return groupedDict.keys.sorted { a, b in
            let ai = order.firstIndex(of: a) ?? 99
            let bi = order.firstIndex(of: b) ?? 99
            if ai != bi { return ai < bi }
            return a > b
        }.map { DayGroup(title: $0, items: groupedDict[$0] ?? []) }
    }

    func load() {
        records = StorageService.shared.getHistory()
    }

    func delete(id: String) {
        records = StorageService.shared.deleteHistoryItem(id: id)
    }

    func clearAll() {
        records = StorageService.shared.clearHistory()
        toast("History cleared")
    }

    func exportCSV() {
        if let url = ExportService.exportHistoryCSV(records) {
            ExportService.shareFile(at: url)
        }
    }

    private func toast(_ msg: String) {
        toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.toastMessage == msg { self?.toastMessage = nil }
        }
    }
}
