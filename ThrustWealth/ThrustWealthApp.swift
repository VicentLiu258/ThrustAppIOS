import SwiftUI

@main
struct ThrustWealthApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var chatService = ChatService.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var showPrivacySheet = false

    init() {
        #if DEBUG
        CalculatorEngineSelfTest.run()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(chatService)
                    .preferredColorScheme(appState.preferences.theme.colorScheme)
                    .opacity(appState.preferences.privacyConsentAccepted ? 1 : 0)
                    .allowsHitTesting(appState.preferences.privacyConsentAccepted)

                if !appState.preferences.privacyConsentAccepted {
                    PrivacyConsentView(
                        onAccept: acceptPrivacy,
                        onViewPrivacy: { showPrivacySheet = true }
                    )
                    .preferredColorScheme(appState.preferences.theme.colorScheme)
                    .transition(.opacity)
                }
            }
            .sheet(isPresented: $showPrivacySheet) {
                LegalTextView(kind: .privacy)
            }
            .task(id: appState.preferences.privacyConsentAccepted) {
                await chatService.initializeIfAllowed(
                    privacyConsentAccepted: appState.preferences.privacyConsentAccepted
                )
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    chatService.setWindowVisible(true)
                case .background, .inactive:
                    chatService.setWindowVisible(false)
                @unknown default:
                    break
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
