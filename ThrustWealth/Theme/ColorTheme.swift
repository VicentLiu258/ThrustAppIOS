import SwiftUI

enum AppThemeOption: String, CaseIterable, Codable, Identifiable {
    case dark
    case light
    case auto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark: return "Dark (Preferred)"
        case .light: return "Light"
        case .auto: return "System Default"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .auto: return nil
        }
    }
}

/// Adaptive themed colors used across views (resolved for current scheme).
struct ThemedColors {
    let bgApp: Color
    let bgSurface: Color
    let bgSurfaceElevated: Color
    let bgSurfaceHover: Color
    let bgInput: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let textMuted: Color
    let borderSubtle: Color
    let borderMedium: Color
    let accentSubtle: Color
    let accentText: Color
    let disclaimerBg: Color
    let disclaimerText: Color
    let tabBarBg: Color

    static func resolve(for scheme: ColorScheme) -> ThemedColors {
        switch scheme {
        case .light:
            return ThemedColors(
                bgApp: Color(hex: 0xF0F4F8),
                bgSurface: Color(hex: 0xFFFFFF),
                bgSurfaceElevated: Color(hex: 0xF1F5F9),
                bgSurfaceHover: Color(hex: 0xE8EEF6),
                bgInput: Color(hex: 0xF8FAFC),
                textPrimary: Color(hex: 0x0F172A),
                textSecondary: Color(hex: 0x475569),
                textTertiary: Color(hex: 0x64748B),
                textMuted: Color(hex: 0x94A3B8),
                borderSubtle: Color(hex: 0xE2E8F0),
                borderMedium: Color(hex: 0xCBD5E1),
                accentSubtle: Theme.Colors.brandPrimary.opacity(0.09),
                accentText: Color(hex: 0x0F766E),
                disclaimerBg: Color(hex: 0xF8FAFC),
                disclaimerText: Color(hex: 0x64748B),
                tabBarBg: Color.white.opacity(0.92)
            )
        default:
            return ThemedColors(
                bgApp: Color(hex: 0x060A12),
                bgSurface: Color(hex: 0x0C1220),
                bgSurfaceElevated: Color(hex: 0x111B2E),
                bgSurfaceHover: Color(hex: 0x1A2640),
                bgInput: Color(hex: 0x080D18),
                textPrimary: Color(hex: 0xF1F5F9),
                textSecondary: Color(hex: 0x94A3B8),
                textTertiary: Color(hex: 0x64748B),
                textMuted: Color(hex: 0x475569),
                borderSubtle: Color.white.opacity(0.06),
                borderMedium: Color.white.opacity(0.12),
                accentSubtle: Theme.Colors.brandPrimary.opacity(0.12),
                accentText: Color(hex: 0x2DD4BF),
                disclaimerBg: Color(hex: 0x080D18),
                disclaimerText: Color(hex: 0x475569),
                tabBarBg: Color(hex: 0x060A12).opacity(0.88)
            )
        }
    }
}

private struct ThemedColorsKey: EnvironmentKey {
    static let defaultValue = ThemedColors.resolve(for: .dark)
}

extension EnvironmentValues {
    var themed: ThemedColors {
        get { self[ThemedColorsKey.self] }
        set { self[ThemedColorsKey.self] = newValue }
    }
}

struct ThemedBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .environment(\.themed, ThemedColors.resolve(for: colorScheme))
            .background(ThemedColors.resolve(for: colorScheme).bgApp.ignoresSafeArea())
    }
}

extension View {
    func thrustTheme() -> some View {
        modifier(ThemedBackground())
    }
}
