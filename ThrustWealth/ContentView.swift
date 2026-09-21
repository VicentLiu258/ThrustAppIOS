import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var chatService: ChatService
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .calculator

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    CalculatorView()
                }
                .tabItem {
                    Label("Calculator", systemImage: "function")
                }
                .tag(AppTab.calculator)

                NavigationStack {
                    ToolsListView()
                }
                .tabItem {
                    Label("Tools", systemImage: "square.grid.2x2")
                }
                .tag(AppTab.tools)

                NavigationStack {
                    TradeJournalView()
                }
                .tabItem {
                    Label("Journal", systemImage: "book")
                }
                .tag(AppTab.journal)

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
            }
            .tint(Theme.Colors.brandPrimary)
            .thrustTheme()

            // Keep one WebView alive after privacy consent. SaleSmartly's
            // real-time connection must survive closing the visible chat UI,
            // otherwise agent replies sent afterward cannot reach the app.
            if appState.preferences.privacyConsentAccepted {
                SalesmartlyChatSheet()
                    .environmentObject(chatService)
                    .opacity(chatService.isChatPresented ? 1 : 0)
                    .allowsHitTesting(chatService.isChatPresented)
                    .accessibilityHidden(!chatService.isChatPresented)
                    .zIndex(100)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active,
                  case .failed = chatService.connectionState else { return }
            chatService.retryChat()
        }
    }
}

enum AppTab: Hashable {
    case calculator, tools, journal, settings
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(ChatService.shared)
}
