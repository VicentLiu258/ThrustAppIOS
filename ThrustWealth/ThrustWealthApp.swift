import SwiftUI

@main
struct ThrustWealthApp: App {
    @StateObject private var appState = AppState()

    init() {
        #if DEBUG
        CalculatorEngineSelfTest.run()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.preferences.theme.colorScheme)
        }
    }
}

/// Shared app-wide state (preferences + instruments + storage)
@MainActor
final class AppState: ObservableObject {
    @Published var preferences: AppPreferences
    @Published var instruments: [Instrument]
    @Published var restorePayload: CalculationRecord?

    let storage = StorageService.shared

    init() {
        let prefs = StorageService.shared.getPreferences()
        self.preferences = prefs
        self.instruments = StorageService.shared.getInstruments()
    }

    func reloadInstruments() {
        instruments = storage.getInstruments()
    }

    func savePreferences() {
        storage.savePreferences(preferences)
        objectWillChange.send()
    }

    func applyTheme() {
        objectWillChange.send()
    }
}
