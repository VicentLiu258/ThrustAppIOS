import SwiftUI
import UIKit

enum Theme {
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    enum Radius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let pill: CGFloat = 9999
    }

    enum Touch {
        static let minTarget: CGFloat = 44
    }

    enum Colors {
        static let brandPrimary = Color(hex: 0x19A492)
        static let brandPrimaryHover = Color(hex: 0x148374)
        static let brandLight = Color(hex: 0x2DD4BF)
        static let brandNavy = Color(hex: 0x0F172A)

        static let profit = Color(hex: 0x10B981)
        static let profitBg = Color(hex: 0x10B981).opacity(0.10)
        static let profitBorder = Color(hex: 0x10B981).opacity(0.35)
        static let loss = Color(hex: 0xEF4444)
        static let lossBg = Color(hex: 0xEF4444).opacity(0.10)
        static let lossBorder = Color(hex: 0xEF4444).opacity(0.35)
        static let warn = Color(hex: 0xF59E0B)
        static let warnBg = Color(hex: 0xF59E0B).opacity(0.12)

        static let bgApp = Color.adaptive(dark: 0x060A12, light: 0xF0F4F8)
        static let bgSurface = Color.adaptive(dark: 0x0C1220, light: 0xFFFFFF)
        static let bgSurfaceElevated = Color.adaptive(dark: 0x111B2E, light: 0xF1F5F9)
        static let bgSurfaceHover = Color.adaptive(dark: 0x1A2640, light: 0xE8EEF6)
        static let bgInput = Color.adaptive(dark: 0x080D18, light: 0xF8FAFC)

        static let textPrimary = Color.adaptive(dark: 0xF1F5F9, light: 0x0F172A)
        static let textSecondary = Color.adaptive(dark: 0x94A3B8, light: 0x475569)
        static let textTertiary = Color.adaptive(dark: 0x64748B, light: 0x64748B)
        static let textMuted = Color.adaptive(dark: 0x475569, light: 0x94A3B8)

        static let accentSubtle = brandPrimary.opacity(0.12)
        static let accentText = Color.adaptive(dark: 0x2DD4BF, light: 0x0F766E)
    }

    enum Fonts {
        static func mono(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .monospaced)
        }

        static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .default)
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    static func adaptive(dark: UInt32, light: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            let r = CGFloat((hex >> 16) & 0xFF) / 255.0
            let g = CGFloat((hex >> 8) & 0xFF) / 255.0
            let b = CGFloat(hex & 0xFF) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: 1)
        })
    }
}
