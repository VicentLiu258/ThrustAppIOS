import Foundation
import Combine

@MainActor
final class MarketSpecsViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var category: String = "ALL"
    @Published var instruments: [Instrument] = []
    @Published var selectedInstrument: Instrument?
    @Published var showDetail = false
    @Published var showAddCustom = false
    @Published var toastMessage: String?

    private weak var appState: AppState?

    func bind(appState: AppState) {
        self.appState = appState
        reload()
    }

    func reload() {
        instruments = StorageService.shared.getInstruments()
        appState?.instruments = instruments
    }

    var filtered: [Instrument] {
        var list = instruments
        if category != "ALL" {
            let cat = category == "Indices" ? "Indices & Energy" : category
            list = list.filter { $0.category == cat || ($0.category.contains("Indices") && cat.contains("Indices")) }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.id.lowercased().contains(q) || $0.name.lowercased().contains(q)
            }
        }
        return list
    }

    var favorites: [Instrument] {
        filtered.filter(\.isFavorite)
    }

    var grouped: [(String, [Instrument])] {
        let cats = ["Metals", "Forex", "Indices & Energy"]
        return cats.compactMap { cat in
            let items = filtered.filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    func toggleFavorite(_ instrument: Instrument) {
        StorageService.shared.setFavorite(id: instrument.id, isFavorite: !instrument.isFavorite)
        reload()
    }

    func deleteCustom(_ instrument: Instrument) {
        guard instrument.isCustom else { return }
        StorageService.shared.deleteCustomInstrument(id: instrument.id)
        reload()
        toast("Custom instrument removed")
    }

    func addCustom(symbol: String, name: String, contract: Double, pip: Double) {
        let inst = Instrument(
            id: symbol.uppercased(),
            name: name,
            category: "Forex",
            contractSize: contract,
            unit: "units",
            pipSize: pip,
            tickSize: pip / 10,
            digits: max(0, Int(-log10(pip))),
            baseCurrency: String(symbol.prefix(3)).uppercased(),
            quoteCurrency: String(symbol.suffix(3)).uppercased(),
            defaultPrice: 1.0,
            isFavorite: false,
            isCustom: true
        )
        StorageService.shared.saveCustomInstrument(inst)
        reload()
        toast("Custom instrument saved")
    }

    func exportSpecs() {
        if let url = ExportService.exportSpecsCSV(instruments) {
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
