import Foundation
import UIKit

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var trades: [TradeEntry] = []
    @Published var stats: JournalStats = .empty
    @Published var showAddTrade = false
    @Published var showClearConfirm = false
    @Published var toastMessage: String?

    func load() {
        trades = StorageService.shared.getJournalTrades()
        stats = StorageService.shared.getJournalStats()
    }

    func addTrade(_ trade: TradeEntry) {
        trades = StorageService.shared.addJournalTrade(trade)
        stats = StorageService.shared.getJournalStats()
        toast("Trade logged")
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func deleteTrade(id: String) {
        trades = StorageService.shared.deleteJournalTrade(id: id)
        stats = StorageService.shared.getJournalStats()
    }

    func clearAll() {
        trades = StorageService.shared.clearJournalTrades()
        stats = StorageService.shared.getJournalStats()
        toast("All trades cleared")
    }

    func exportCSV() {
        if let url = ExportService.exportJournalCSV(trades) {
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
