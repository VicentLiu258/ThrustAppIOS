import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var chatService: ChatService
    @StateObject private var vm = CalculatorViewModel()
    @Environment(\.themed) private var themed
    @Environment(\.colorScheme) private var colorScheme

    @State private var showSymbolPicker = false
    @State private var showMore = false
    @State private var showHelp = false
    @State private var navigateHistory = false
    @State private var navigatePL = false
    @State private var navigateSpecs = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        searchSection

                        ThrustSegmentedControl(
                            options: CalculatorMode.allCases.map { ($0, $0.title) },
                            selection: $vm.mode
                        )

                        FormDropdownField(
                            label: "Instrument / Symbol",
                            hint: vm.currentInstrument.map { "Contract: \($0.contractHint)" },
                            value: vm.symbolID
                        ) {
                            showSymbolPicker = true
                        }

                        FormInputField(
                            label: "Account Balance",
                            hint: "Base Currency: \(vm.currency)",
                            prefix: vm.currencySymbol,
                            text: $vm.balanceText
                        )
                        .onChange(of: vm.balanceText) { _, _ in
                            if vm.mode == .byRisk { vm.syncRiskAmountFromPercent() }
                        }

                        if vm.mode == .byRisk {
                            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                                FormInputField(
                                    label: "Risk %",
                                    suffix: "%",
                                    text: $vm.riskPercentText
                                )
                                .onChange(of: vm.riskPercentText) { _, _ in
                                    vm.syncRiskAmountFromPercent()
                                }

                                FormInputField(
                                    label: "Risk Amount",
                                    prefix: vm.currencySymbol,
                                    text: $vm.riskAmountText
                                )
                                .onChange(of: vm.riskAmountText) { _, _ in
                                    vm.syncRiskPercentFromAmount()
                                }
                            }

                            PresetPillsRow(
                                presets: [0.5, 1.0, 2.0, 3.0],
                                selected: $vm.selectedPreset,
                                onSelect: vm.applyPreset
                            )
                        } else {
                            FormInputField(
                                label: "Lot Size",
                                hint: "Standard Lots",
                                suffix: "lots",
                                text: $vm.lotSizeText
                            )
                        }

                        FormInputField(
                            label: "Stop Loss (Pips)",
                            hint: vm.currentInstrument?.pipHint,
                            suffix: "pips",
                            text: $vm.stopPipsText,
                            keyboard: .numberPad
                        )

                        HStack(alignment: .top, spacing: Theme.Spacing.md) {
                            FormInputField(
                                label: "Entry Price",
                                hint: "Optional",
                                text: $vm.entryPriceText
                            )

                            VStack(alignment: .leading, spacing: 6) {
                                Text("DIRECTION")
                                    .font(Theme.Fonts.sans(11.5, weight: .bold))
                                    .tracking(0.6)
                                    .foregroundStyle(themed.textTertiary)
                                ThrustSegmentedControl(
                                    options: TradeDirection.allCases.map { ($0, $0.displayName) },
                                    selection: $vm.direction,
                                    longShortStyle: true
                                )
                            }
                        }

                        resultCard

                        ComplianceDisclaimer()
                            .padding(.bottom, 80)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)
                }

                QuickSymbolBar(
                    symbols: vm.quickSymbols,
                    selected: $vm.symbolID,
                    onSelect: vm.selectSymbol
                )
            }

            if appState.preferences.showHomeChatButton {
                HStack {
                    Spacer()
                    FloatingChatButton(
                        unreadCount: chatService.unreadCount,
                        action: openSupportChat
                    )
                    .padding(.trailing, 18)
                }
                .padding(.bottom, 64)
                .zIndex(5)
                .transition(.scale.combined(with: .opacity))
            }

            if let toast = vm.toastMessage {
                ToastBanner(message: toast)
                    .padding(.bottom, 90)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .background(ThemedColors.resolve(for: colorScheme).bgApp.ignoresSafeArea())
        .environment(\.themed, ThemedColors.resolve(for: colorScheme))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if UIImage(named: "Logo") != nil {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                } else {
                    Text("Thrust Wealth")
                        .font(Theme.Fonts.sans(17, weight: .bold))
                        .foregroundStyle(Theme.Colors.brandPrimary)
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { navigateHistory = true } label: {
                    Image(systemName: "clock")
                }
                .accessibilityLabel("Calculation History")

                Button { vm.saveRecord() } label: {
                    Image(systemName: "bookmark")
                }
                .accessibilityLabel("Save Calculation")

                Button { showMore = true } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("More Options")
            }
        }
        .toolbarBackground(themed.bgApp, for: .navigationBar)
        .sheet(isPresented: $showSymbolPicker) {
            SymbolPickerSheet(
                instruments: vm.instruments,
                selectedID: vm.symbolID,
                onSelect: vm.selectSymbol
            )
        }
        .sheet(isPresented: $showMore) {
            moreSheet
        }
        .sheet(isPresented: $showHelp) {
            helpSheet
        }
        .navigationDestination(isPresented: $navigateHistory) {
            HistoryView { record in
                vm.restore(record)
            }
        }
        .navigationDestination(isPresented: $navigatePL) {
            PLCalculatorView()
        }
        .navigationDestination(isPresented: $navigateSpecs) {
            MarketSpecsView()
        }
        .onAppear {
            vm.bind(appState: appState)
            if let payload = appState.restorePayload {
                vm.restore(payload)
                appState.restorePayload = nil
            }
        }
        .onChange(of: appState.restorePayload) { _, newValue in
            if let payload = newValue {
                vm.restore(payload)
                appState.restorePayload = nil
            }
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SearchBar(text: $vm.searchText, placeholder: "Search tools (P/L, Specs, Journal)...")
            if !vm.searchHits.isEmpty {
                VStack(spacing: 0) {
                    ForEach(vm.searchHits, id: \.route) { hit in
                        Button {
                            handleSearchRoute(hit.route)
                            vm.searchText = ""
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(hit.title)
                                        .font(Theme.Fonts.sans(14, weight: .semibold))
                                        .foregroundStyle(themed.textPrimary)
                                    Text(hit.desc)
                                        .font(Theme.Fonts.sans(12))
                                        .foregroundStyle(themed.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(themed.textMuted)
                            }
                            .padding(Theme.Spacing.md)
                        }
                        .buttonStyle(.plain)
                        Divider().background(themed.borderSubtle)
                    }
                }
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                        .strokeBorder(themed.borderMedium, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                .padding(.top, 8)
            }
        }
    }

    private var resultCard: some View {
        let r = vm.result
        let slText: String = {
            if let sl = r.stopLossPrice, let digits = vm.currentInstrument?.digits {
                return "\(Formatters.price(sl, digits: digits)) (\(vm.direction.displayName))"
            }
            return "—"
        }()

        return ResultShowcaseCard(
            heroTitle: vm.mode == .byRisk ? "Suggested Lot Size" : "Position Lot Size",
            heroValue: r.isValid ? "\(Formatters.lots(r.suggestedLots)) Lots" : "—",
            heroSub: r.isValid ? "(= \(r.miniLots) Mini / \(Int(r.microLots)) Micro lots)" : nil,
            badge: "Sizing Result",
            stats: [
                ("Risk Amount", Formatters.money(r.riskAmount, currency: vm.currency), nil),
                ("Risk %", Formatters.percent(r.riskPercent), nil),
                ("Pip Value", "\(Formatters.money(r.pipValue, currency: vm.currency)) / pip", nil),
                ("Notional Value", Formatters.compactNotional(r.notionalValue, currency: vm.currency), nil),
                ("Stop Loss Price", slText, nil)
            ],
            isValid: r.isValid,
            onReset: { vm.reset() },
            onExport: { vm.exportCurrent() },
            onPrimary: { vm.saveRecord() },
            primaryTitle: "Save Record",
            primarySystemImage: "bookmark"
        )
    }

    private var moreSheet: some View {
        NavigationStack {
            List {
                Button {
                    showMore = false
                    vm.reset()
                } label: {
                    Label("Reset Calculator", systemImage: "trash")
                }
                Button {
                    showMore = false
                    vm.exportCurrent()
                } label: {
                    Label("Export Calculation (CSV)", systemImage: "square.and.arrow.up")
                }
                Button {
                    showMore = false
                    vm.shareSummary()
                } label: {
                    Label("Share Calculation Summary", systemImage: "doc.on.doc")
                }
                Button {
                    showMore = false
                    showHelp = true
                } label: {
                    Label("Calculation Reference", systemImage: "questionmark.circle")
                }
            }
            .navigationTitle("Calculator Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showMore = false }
                }
            }
        }
        .presentationDetents([.medium])
        .thrustTheme()
    }

    private var helpSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("Position Sizing Formula")
                            .font(.headline)
                        Text("Suggested Lots = Risk Amount ÷ (Stop Loss Pips × Pip Value)")
                            .foregroundStyle(themed.textSecondary)
                    }
                    Group {
                        Text("Gold (XAUUSD) Specifics")
                            .font(.headline)
                        Text("Standard Contract = 100 oz per lot. 1 pip = 0.10 price move ($10.00 / pip per standard lot).")
                            .foregroundStyle(themed.textSecondary)
                    }
                    Group {
                        Text("Important Compliance Notice")
                            .font(.headline)
                        Text("This utility does not recommend trades or predict price movements. Always apply disciplined risk management. Built-in specs are industry defaults — verify with your broker.")
                            .foregroundStyle(themed.textSecondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Calculation Reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showHelp = false }
                }
            }
        }
        .presentationDetents([.medium])
        .thrustTheme()
    }

    private func handleSearchRoute(_ route: String) {
        switch route {
        case "pnl": navigatePL = true
        case "specs": navigateSpecs = true
        case "journal": break
        default: break
        }
    }

    private func openSupportChat() {
        chatService.requestOpenChat(
            privacyConsentAccepted: appState.preferences.privacyConsentAccepted,
            onToast: { message in
                vm.showToast(message)
            }
        )
    }
}
