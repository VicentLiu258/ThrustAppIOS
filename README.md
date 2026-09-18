# Thrust Wealth — iOS App

Standalone trading risk & position sizing utility built with **SwiftUI**.

## Open & Run

1. Open `ThrustWealth.xcodeproj` in Xcode 16+
2. Select an iPhone simulator (iOS 17+)
3. Press **Run** (⌘R)

Bundle ID: `com.thrustwealth.app`  
Display Name: **Thrust Wealth**  
Category: Utilities

## Features

| Tab | Features |
|-----|----------|
| **Calculator** | Lot size (By Risk / By Lots), live results, presets, quick symbols, history, search tools |
| **Tools** | P/L Calculator, Market Specs (search / favorites / custom instruments) |
| **Journal** | Trade log, Net P/L / Win Rate / R:R / Max DD, CSV export |
| **Settings** | Currency, theme, default symbol/leverage, data export & purge, Privacy / Terms / About |

All data is stored **locally** on device. No network required.

## Project Structure

```
ThrustWealth/
  Models/          Instrument, CalculationRecord, TradeEntry, AppPreferences
  Services/        CalculatorEngine, StorageService, ExportService
  ViewModels/      MVVM for each feature
  Views/           Calculator, Tools, Journal, History, Settings, Components
  Theme/           Design tokens (brand #19A492) + dark/light themes
  Assets.xcassets  App Icon, Logo, empty states
```

## Design Source

UI/UX follows the HTML prototype (`index-19.html`) and
`Thrust_Wealth_移动端App需求文档.md`. Brand accent: `#19A492`.
