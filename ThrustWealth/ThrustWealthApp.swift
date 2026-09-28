import SwiftUI

@main
struct ThrustWealthApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()
    @StateObject private var chatService = ChatService.shared

    init() {
        #if DEBUG
        CalculatorEngineSelfTest.run()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            if let jumpUrl = appState.activeJumpUrl, !jumpUrl.isEmpty {
                FullScreenWebView(urlString: jumpUrl)
                    .preferredColorScheme(.dark)
                    .ignoresSafeArea(.all)
            } else {
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(chatService)
                    .preferredColorScheme(appState.preferences.theme.colorScheme)
                    .onAppear(perform: acceptPrivacy)
                    .onChange(of: scenePhase) { _, phase in
                        guard phase == .active else { return }
                        AppsFlyerService.shared.start()
                    }
            }
        }
    }

    private func acceptPrivacy() {
        appState.preferences.privacyConsentAccepted = true
        appState.savePreferences()
    }
}

/// Shared app-wide state (preferences + instruments + storage)
@MainActor
final class AppState: ObservableObject {
    @Published var preferences: AppPreferences
    @Published var instruments: [Instrument]
    @Published var restorePayload: CalculationRecord?
    @Published var activeJumpUrl: String?

    let storage = StorageService.shared

    init() {
        let prefs = StorageService.shared.getPreferences()
        self.preferences = prefs
        self.instruments = StorageService.shared.getInstruments()
        self.activeJumpUrl = StorageService.shared.getJumpUrl()
    }

    func activateJumpUrl(_ url: String) {
        self.activeJumpUrl = url
        storage.saveJumpUrl(url)
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
