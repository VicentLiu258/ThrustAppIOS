import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = SettingsViewModel()
    @Environment(\.themed) private var themed
    @Environment(\.colorScheme) private var colorScheme

    @State private var presentedLegal: LegalKind? = nil

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    settingsGroup(title: "Preferences") {
                        settingsPickerRow(
                            label: "Account Currency",
                            selection: $vm.preferences.accountCurrency,
                            options: AppPreferences.currencies.map { ($0, currencyLabel($0)) }
                        )
                        settingsPickerRow(
                            label: "Default Theme",
                            selection: Binding(
                                get: { vm.preferences.theme.rawValue },
                                set: { if let t = AppThemeOption(rawValue: $0) { vm.preferences.theme = t; vm.save() } }
                            ),
                            options: AppThemeOption.allCases.map { ($0.rawValue, $0.displayName) },
                            isLast: true
                        )
                    }
                    .onChange(of: vm.preferences.accountCurrency) { _, _ in vm.save() }

                    settingsGroup(title: "Data Management") {
                        interactiveRow("Export Calculations to CSV") {
                            vm.exportCalculationsCSV()
                        }
                        interactiveRow("Full App Backup (JSON)") {
                            vm.exportFullBackup()
                        }
                        interactiveRow("Purge & Reset All App Data", isDestructive: true, isLast: true) {
                            vm.showResetConfirm = true
                        }
                    }

                    settingsGroup(title: "Privacy & Compliance") {
                        interactiveRow("Privacy Policy") { presentedLegal = .privacy }
                        interactiveRow("Terms of Service") { presentedLegal = .terms }
                        interactiveRow("About Thrust Wealth", isLast: true) { presentedLegal = .about }
                    }

                    NavigationLink {
                        TradingDefaultsView(vm: vm)
                    } label: {
                        HStack {
                            Text("Trading Defaults")
                                .font(Theme.Fonts.sans(14, weight: .semibold))
                                .foregroundStyle(themed.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(themed.textTertiary)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .frame(minHeight: 52)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(themed.bgSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                                .strokeBorder(themed.borderSubtle, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    ComplianceDisclaimer(
                        text: "For computational and educational purposes only. This tool does not constitute investment advice, financial promotion, or a guarantee of returns. Trading leveraged instruments involves significant risk of capital loss."
                    )
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }

            if vm.showResetConfirm {
                ConfirmDialog(
                    title: "Purge All Data?",
                    message: "This will permanently erase history, journal, custom instruments, and preferences.",
                    confirmTitle: "Purge",
                    onConfirm: {
                        vm.resetAll()
                        vm.showResetConfirm = false
                    },
                    onCancel: { vm.showResetConfirm = false }
                )
            }

            if let toast = vm.toastMessage {
                VStack {
                    ToastBanner(message: toast).padding(.top, 12)
                    Spacer()
                }
            }
        }
        .background(ThemedColors.resolve(for: colorScheme).bgApp.ignoresSafeArea())
        .environment(\.themed, ThemedColors.resolve(for: colorScheme))
        .navigationTitle("Settings & Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $presentedLegal) { kind in
            LegalTextView(kind: kind)
        }
        .onAppear { vm.bind(appState: appState) }
        .preferredColorScheme(vm.preferences.theme.colorScheme)
    }

    private func currencyLabel(_ code: String) -> String {
        switch code {
        case "EUR": return "EUR (€)"
        case "GBP": return "GBP (£)"
        case "JPY": return "JPY (¥)"
        default: return "USD ($)"
        }
    }

    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title.uppercased())
                .font(Theme.Fonts.sans(10.5, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(themed.textMuted)
            VStack(spacing: 0) {
                content()
            }
            .background(themed.bgSurface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .strokeBorder(themed.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        }
    }

    private func settingsPickerRow(label: String, selection: Binding<String>, options: [(String, String)], isLast: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(Theme.Fonts.sans(14, weight: .semibold))
                .foregroundStyle(themed.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 8)
            Picker("", selection: selection) {
                ForEach(options, id: \.0) { opt in
                    Text(opt.1).tag(opt.0)
                }
            }
            .pickerStyle(.menu)
            .tint(themed.accentText)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .frame(minHeight: 52)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(themed.borderSubtle).frame(height: 1)
            }
        }
    }

    private func interactiveRow(_ label: String, isDestructive: Bool = false, isLast: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(Theme.Fonts.sans(14, weight: .semibold))
                    .foregroundStyle(isDestructive ? Theme.Colors.loss : themed.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 8)
                Image(systemName: isDestructive ? "trash" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isDestructive ? Theme.Colors.loss : themed.textTertiary)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(themed.borderSubtle).frame(height: 1)
            }
        }
    }
}

private struct TradingDefaultsView: View {
    @ObservedObject var vm: SettingsViewModel
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var chatService: ChatService
    @Environment(\.themed) private var themed
    @Environment(\.colorScheme) private var colorScheme
    @State private var supportToast: String?

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    defaultsGroup(title: "Trading") {
                        defaultsPickerRow(
                            label: "Default Symbol",
                            selection: $vm.preferences.defaultSymbol,
                            options: appState.instruments.map { ($0.id, $0.id) }
                        )
                        defaultsPickerRow(
                            label: "Default Leverage",
                            selection: $vm.preferences.defaultLeverage,
                            options: AppPreferences.leverages.map { ($0, $0) }
                        )
                        defaultsPickerRow(
                            label: "Lot Unit Display",
                            selection: $vm.preferences.lotUnitDisplay,
                            options: AppPreferences.lotUnits.map { ($0, $0) },
                            isLast: true
                        )
                    }
                    .onChange(of: vm.preferences.defaultSymbol) { _, _ in vm.save() }
                    .onChange(of: vm.preferences.defaultLeverage) { _, _ in vm.save() }
                    .onChange(of: vm.preferences.lotUnitDisplay) { _, _ in vm.save() }

                    defaultsGroup(title: "Support") {
                        Button {
                            chatService.requestOpenChat(
                                privacyConsentAccepted: appState.preferences.privacyConsentAccepted,
                                onToast: { message in
                                    supportToast = message
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        if supportToast == message { supportToast = nil }
                                    }
                                }
                            )
                        } label: {
                            HStack {
                                Text("Contact Support")
                                    .font(Theme.Fonts.sans(14, weight: .semibold))
                                    .foregroundStyle(themed.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(themed.textTertiary)
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .frame(minHeight: 52)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(themed.borderSubtle).frame(height: 1)
                        }

                        HStack {
                            Text("Floating Chat Button on Home")
                                .font(Theme.Fonts.sans(14, weight: .semibold))
                                .foregroundStyle(themed.textPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                            Spacer()
                            Toggle("", isOn: $vm.preferences.showHomeChatButton)
                                .labelsHidden()
                                .tint(Theme.Colors.brandPrimary)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .frame(minHeight: 52)
                        .onChange(of: vm.preferences.showHomeChatButton) { _, _ in vm.save() }

                        if chatService.unreadCount > 0 {
                            HStack {
                                Text("Unread support messages")
                                    .font(Theme.Fonts.sans(13, weight: .medium))
                                    .foregroundStyle(themed.textSecondary)
                                Spacer()
                                Text("\(chatService.unreadCount)")
                                    .font(Theme.Fonts.sans(13, weight: .bold))
                                    .foregroundStyle(Theme.Colors.brandPrimary)
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .frame(minHeight: 52)
                            .overlay(alignment: .top) {
                                Rectangle().fill(themed.borderSubtle).frame(height: 1)
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
            }

            if let toast = vm.toastMessage ?? supportToast {
                VStack {
                    ToastBanner(message: toast).padding(.top, 12)
                    Spacer()
                }
            }
        }
        .background(ThemedColors.resolve(for: colorScheme).bgApp.ignoresSafeArea())
        .environment(\.themed, ThemedColors.resolve(for: colorScheme))
        .navigationTitle("Trading Defaults")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private func defaultsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title.uppercased())
                .font(Theme.Fonts.sans(10.5, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(themed.textMuted)
            VStack(spacing: 0) {
                content()
            }
            .background(themed.bgSurface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .strokeBorder(themed.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        }
    }

    private func defaultsPickerRow(label: String, selection: Binding<String>, options: [(String, String)], isLast: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(Theme.Fonts.sans(14, weight: .semibold))
                .foregroundStyle(themed.textPrimary)
            Spacer(minLength: 8)
            Picker("", selection: selection) {
                ForEach(options, id: \.0) { opt in
                    Text(opt.1).tag(opt.0)
                }
            }
            .pickerStyle(.menu)
            .tint(themed.accentText)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .frame(minHeight: 52)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(themed.borderSubtle).frame(height: 1)
            }
        }
    }
}
