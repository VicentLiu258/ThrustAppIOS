import SwiftUI

struct MarketSpecsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = MarketSpecsViewModel()
    @Environment(\.themed) private var themed
    @Environment(\.colorScheme) private var colorScheme

    private let categoryTabs = ["ALL", "Metals", "Forex", "Indices"]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SearchBar(text: $vm.searchText, placeholder: "Search symbol or name...")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.xs) {
                            ForEach(categoryTabs, id: \.self) { cat in
                                let active = vm.category == cat
                                Button {
                                    vm.category = cat
                                } label: {
                                    Text(cat == "ALL" ? "All Instruments" : (cat == "Indices" ? "Indices & Energy" : (cat == "Metals" ? "Precious Metals" : cat)))
                                        .font(Theme.Fonts.sans(12.5, weight: active ? .bold : .semibold))
                                        .foregroundStyle(active ? .white : themed.textTertiary)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 8)
                                        .background(active ? Theme.Colors.brandPrimary : themed.bgSurface)
                                        .overlay(Capsule().strokeBorder(active ? Color.clear : themed.borderSubtle, lineWidth: 1))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if !vm.favorites.isEmpty && vm.category == "ALL" && vm.searchText.isEmpty {
                        Text("★ FAVORITES")
                            .font(Theme.Fonts.sans(10.5, weight: .heavy))
                            .foregroundStyle(themed.textMuted)
                            .tracking(0.7)
                        ForEach(vm.favorites) { inst in
                            specRow(inst)
                        }
                    }

                    ForEach(vm.grouped, id: \.0) { group in
                        Text(group.0.uppercased())
                            .font(Theme.Fonts.sans(10.5, weight: .heavy))
                            .foregroundStyle(themed.textMuted)
                            .tracking(0.7)
                            .padding(.top, Theme.Spacing.sm)
                        ForEach(group.1) { inst in
                            specRow(inst)
                        }
                    }

                    if vm.filtered.isEmpty {
                        EmptyStateView(
                            systemImage: "magnifyingglass",
                            title: "No instruments found",
                            description: "Try a different search or category filter.",
                            assetName: "EmptySearch"
                        )
                    }

                    Text("Tap any instrument to view full contract specifications, tick sizes, and pip values.")
                        .font(Theme.Fonts.sans(12))
                        .foregroundStyle(themed.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.Spacing.xl)
                }
                .padding(Theme.Spacing.lg)
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
        .navigationTitle("Market Specs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { vm.exportSpecs() } label: { Image(systemName: "square.and.arrow.up") }
                Button { vm.showAddCustom = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $vm.showDetail) {
            if let inst = vm.selectedInstrument {
                SpecDetailSheet(instrument: inst, currency: appState.preferences.accountCurrency)
            }
        }
        .sheet(isPresented: $vm.showAddCustom) {
            CustomSpecSheet { symbol, name, contract, pip in
                vm.addCustom(symbol: symbol, name: name, contract: contract, pip: pip)
            }
        }
        .onAppear { vm.bind(appState: appState) }
    }

    private func specRow(_ inst: Instrument) -> some View {
        Button {
            vm.selectedInstrument = inst
            vm.showDetail = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(inst.id)
                        .font(Theme.Fonts.mono(15, weight: .heavy))
                        .foregroundStyle(themed.textPrimary)
                    Text(inst.name)
                        .font(Theme.Fonts.sans(11.5))
                        .foregroundStyle(themed.textTertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(inst.contractHint)
                        .font(Theme.Fonts.mono(13, weight: .bold))
                        .foregroundStyle(themed.textSecondary)
                    Text(inst.pipHint)
                        .font(Theme.Fonts.mono(11))
                        .foregroundStyle(themed.textMuted)
                }

                Button {
                    vm.toggleFavorite(inst)
                } label: {
                    Image(systemName: inst.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(inst.isFavorite ? Color(hex: 0xEAB308) : themed.textMuted)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)

                if inst.isCustom {
                    Button {
                        vm.deleteCustom(inst)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(themed.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(themed.bgSurface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(themed.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
