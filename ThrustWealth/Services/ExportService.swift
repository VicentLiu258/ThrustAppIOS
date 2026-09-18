import Foundation
import UIKit
import SwiftUI

enum ExportService {

    static func csvString(from rows: [[String]]) -> String {
        rows.map { row in
            row.map { cell in
                var str = cell
                if str.contains("\"") || str.contains(",") || str.contains("\n") {
                    str = "\"" + str.replacingOccurrences(of: "\"", with: "\"\"") + "\""
                }
                return str
            }.joined(separator: ",")
        }.joined(separator: "\n")
    }

    static func exportJournalCSV(_ trades: [TradeEntry]) -> URL? {
        var rows: [[String]] = [["Trade ID", "Date", "Symbol", "Direction", "Lots", "Open Price", "Close Price", "P/L ($)", "Note"]]
        for t in trades {
            rows.append([
                t.id, t.date, t.symbol, t.direction.uppercased(),
                String(t.lots), String(t.openPrice), String(t.closePrice),
                String(t.pnl), t.note
            ])
        }
        return writeTemp(filename: "thrust_wealth_trades_\(Int(Date().timeIntervalSince1970)).csv", content: csvString(from: rows))
    }

    static func exportHistoryCSV(_ history: [CalculationRecord]) -> URL? {
        var rows: [[String]] = [["Timestamp", "Date", "Symbol", "Balance", "Risk %", "Stop Loss (pips)", "Suggested Lots", "Risk Amount ($)", "Notional Value ($)"]]
        for h in history {
            rows.append([
                String(h.timestamp), h.dateStr, h.symbol, String(h.balance),
                "\(h.riskPercent)%", String(h.stopPips), String(h.suggestedLots),
                String(h.riskAmount), String(h.notionalValue)
            ])
        }
        return writeTemp(filename: "thrust_wealth_history_\(Int(Date().timeIntervalSince1970)).csv", content: csvString(from: rows))
    }

    static func exportSpecsCSV(_ instruments: [Instrument]) -> URL? {
        var rows: [[String]] = [["Symbol", "Name", "Category", "Contract Size", "Unit", "Pip Size", "Quote Currency", "Digits"]]
        for i in instruments {
            rows.append([
                i.id, i.name, i.category, String(i.contractSize), i.unit,
                String(i.pipSize), i.quoteCurrency, String(i.digits)
            ])
        }
        return writeTemp(filename: "thrust_wealth_specs_\(Int(Date().timeIntervalSince1970)).csv", content: csvString(from: rows))
    }

    static func exportSingleCalculationCSV(_ record: CalculationRecord) -> URL? {
        let rows: [[String]] = [
            ["Field", "Value"],
            ["Symbol", record.symbol],
            ["Mode", record.mode],
            ["Balance", String(record.balance)],
            ["Risk %", "\(record.riskPercent)%"],
            ["Risk Amount", String(record.riskAmount)],
            ["Stop Loss (pips)", String(record.stopPips)],
            ["Entry Price", String(record.entryPrice)],
            ["Direction", record.direction],
            ["Suggested Lots", String(record.suggestedLots)],
            ["Pip Value", String(record.pipValue)],
            ["Notional Value", String(record.notionalValue)],
            ["Disclaimer", "For calculation purposes only. Not investment advice."]
        ]
        return writeTemp(filename: "thrust_wealth_calc_\(Int(Date().timeIntervalSince1970)).csv", content: csvString(from: rows))
    }

    static func exportFullBackupJSON(payload: [String: Any]) -> URL? {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return writeTemp(filename: "thrust_wealth_backup_\(Int(Date().timeIntervalSince1970)).json", content: str)
    }

    static func shareText(_ text: String) {
        let disclaimer = "\n\n—\nFor calculation purposes only. Not investment advice."
        presentShare([text + disclaimer])
    }

    static func presentShare(_ items: [Any]) {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else { return }
            var top = root
            while let presented = top.presentedViewController { top = presented }
            let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
            if let pop = vc.popoverPresentationController {
                pop.sourceView = top.view
                pop.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
                pop.permittedArrowDirections = []
            }
            top.present(vc, animated: true)
        }
    }

    static func shareFile(at url: URL) {
        presentShare([url])
    }

    private static func writeTemp(filename: String, content: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

/// SwiftUI wrapper to trigger share sheet
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
