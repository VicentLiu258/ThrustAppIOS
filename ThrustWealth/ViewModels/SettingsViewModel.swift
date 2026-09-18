import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var preferences: AppPreferences = .default
    @Published var showResetConfirm = false
    @Published var toastMessage: String?

    private weak var appState: AppState?

    func bind(appState: AppState) {
        self.appState = appState
        preferences = appState.preferences
    }

    func save() {
        StorageService.shared.savePreferences(preferences)
        appState?.preferences = preferences
        appState?.applyTheme()
        toast("Preferences saved")
    }

    func exportCalculationsCSV() {
        let history = StorageService.shared.getHistory()
        if let url = ExportService.exportHistoryCSV(history) {
            ExportService.shareFile(at: url)
        }
    }

    func exportFullBackup() {
        let payload = StorageService.shared.fullBackupPayload()
        if let url = ExportService.exportFullBackupJSON(payload: payload) {
            ExportService.shareFile(at: url)
        }
    }

    func resetAll() {
        StorageService.shared.resetAllData()
        preferences = .default
        appState?.preferences = .default
        appState?.reloadInstruments()
        appState?.applyTheme()
        toast("All app data purged")
    }

    private func toast(_ msg: String) {
        toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.toastMessage == msg { self?.toastMessage = nil }
        }
    }
}
