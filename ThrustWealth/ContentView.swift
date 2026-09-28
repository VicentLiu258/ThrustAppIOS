import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var chatService: ChatService
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .calculator

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        TabPageHost(isSelected: selectedTab == tab) {
                            NavigationStack {
                                tab.root
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !chatService.isChatPresented {
                    AppTabBar(selection: $selectedTab)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .thrustTheme()

            SalesmartlyChatSheet()
                .environmentObject(chatService)
                .opacity(chatService.isChatPresented ? 1 : 0)
                .allowsHitTesting(chatService.isChatPresented)
                .accessibilityHidden(!chatService.isChatPresented)
                .ignoresSafeArea()
                .zIndex(100)
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: chatService.isChatPresented)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active,
                  case .failed = chatService.connectionState else { return }
            chatService.retryChat()
        }
    }
}

/// Keeps every tab's navigation stack mounted. The outgoing page snaps away;
/// only the incoming page fades in while moving up 14pt over 280ms.
private struct TabPageHost<Content: View>: View {
    let isSelected: Bool
    let content: Content

    init(isSelected: Bool, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.content = content()
    }

    var body: some View {
        content
            .opacity(isSelected ? 1 : 0)
            .offset(y: isSelected ? 0 : 14)
            .animation(isSelected ? .timingCurve(0.16, 1, 0.3, 1, duration: 0.28) : nil, value: isSelected)
            .allowsHitTesting(isSelected)
            .accessibilityHidden(!isSelected)
            .zIndex(isSelected ? 1 : 0)
    }
}

private struct TabIconMotion {
    var scale: CGFloat = 1.1
    var y: CGFloat = 0
}

enum AppTab: Hashable, CaseIterable {
    case calculator, tools, journal, settings

    var title: String {
        switch self {
        case .calculator: return "Calculator"
        case .tools: return "Tools"
        case .journal: return "Journal"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .calculator: return "function"
        case .tools: return "square.grid.2x2"
        case .journal: return "book"
        case .settings: return "gearshape"
        }
    }

    @ViewBuilder
    var root: some View {
        switch self {
        case .calculator: CalculatorView()
        case .tools: ToolsListView()
        case .journal: TradeJournalView()
        case .settings: SettingsView()
        }
    }
}

private struct AppTabBar: View {
    @Binding var selection: AppTab
    /// Indicator progress is separate so page switching can stay non-animated
    /// while the lines still shrink and grow together.
    @State private var lineSelection: AppTab = .calculator
    @Environment(\.themed) private var themed

    private var lineAnimation: Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: 0.28)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let selected = selection == tab
                Button {
                    guard selection != tab else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        selection = tab
                    }
                    DispatchQueue.main.async {
                        withAnimation(lineAnimation) {
                            lineSelection = tab
                        }
                    }
                } label: {
                    VStack(spacing: 3) {
                        TabSelectionLine(progress: lineSelection == tab ? 1 : 0)
                            .animation(lineAnimation, value: lineSelection)
                        Image(systemName: tab.symbol)
                            .font(.system(size: 22, weight: selected ? .semibold : .regular))
                            .keyframeAnimator(initialValue: TabIconMotion(), trigger: selection) { icon, motion in
                                icon
                                    .scaleEffect(selected ? motion.scale : 1)
                                    .offset(y: selected ? motion.y : 0)
                            } keyframes: { _ in
                                KeyframeTrack(\.scale) {
                                    LinearKeyframe(1.28, duration: 0.136)
                                    LinearKeyframe(0.96, duration: 0.102)
                                    LinearKeyframe(1.10, duration: 0.102)
                                }
                                KeyframeTrack(\.y) {
                                    LinearKeyframe(-3, duration: 0.136)
                                    LinearKeyframe(0, duration: 0.204)
                                }
                            }
                        Text(tab.title)
                            .font(Theme.Fonts.sans(10.5, weight: selected ? .semibold : .semibold))
                    }
                    .foregroundStyle(selected ? Theme.Colors.brandPrimary : themed.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 6)
        .background(themed.bgApp.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(themed.borderSubtle)
                .frame(height: 0.5)
        }
    }
}

/// Centered marker. Progress 1 is the full line; 0 is gone.
/// Width tracks progress the whole way, so the outgoing line shortens from both
/// ends. Opacity only drops at the end, after it is already short.
/// The incoming line uses the same progress curve in reverse.
private struct TabSelectionLine: View, Animatable {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let amount = min(1, max(0, progress))
        Capsule()
            .fill(Theme.Colors.brandPrimary)
            .frame(width: 20 * amount, height: 3)
            .opacity(amount > 0.2 ? 1 : amount / 0.2)
            .frame(width: 20, height: 3, alignment: .center)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(ChatService.shared)
}
