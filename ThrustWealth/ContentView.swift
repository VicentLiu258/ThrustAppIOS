import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var chatService: ChatService
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

        }
        .sheet(isPresented: $chatService.isChatPresented) {
            SalesmartlyChatSheet()
                .environmentObject(chatService)
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
