# Thrust Wealth — iOS App

Standalone trading risk & position sizing utility built with **SwiftUI**.

## Open & Run

1. Open `ThrustWealth.xcodeproj` in Xcode 16+
2. Wait for Swift Package `SalesmartlyChat` (SaleSmartly Mobile-SDK `1.0.0`) to resolve
3. Select an iPhone simulator (iOS 17+)
4. Press **Run** (⌘R)

Bundle ID: `com.thrustwealth.app`  
Display Name: **Thrust Wealth**  
Category: Utilities

## Features

| Tab | Features |
|-----|----------|
| **Calculator** | Lot size (By Risk / By Lots), live results, presets, quick symbols, history, search tools |
| **Tools** | P/L Calculator, Market Specs (search / favorites / custom instruments) |
| **Journal** | Trade log, Net P/L / Win Rate / R:R / Max DD, CSV export |
| **Settings** | Currency, theme, default symbol/leverage, data export & purge, **Contact Support**, Privacy / Terms / About |

Calculator / journal data stays **local**. Optional support chat uses SaleSmartly native SDK and initializes only after privacy consent.

## SaleSmartly Support Chat

1. Admin completes backend setup — see [`docs/SaleSmartly_后台配置指南.md`](docs/SaleSmartly_后台配置指南.md)
2. Fill placeholders in `ThrustWealth/Services/ChatConfig.swift`:
   - `scriptURL`
   - custom field IDs
3. First launch: user must tap **Agree & Continue**
4. Open **Settings → Contact Support**

SwiftPM: `https://github.com/SaleSmartly-Mobile/Mobile-SDK` @ `1.0.0` → product `SalesmartlyChat`

## Project Structure

```
ThrustWealth/
  Models/          Instrument, CalculationRecord, TradeEntry, AppPreferences
  Services/        CalculatorEngine, StorageService, ExportService, ChatService
  ViewModels/      MVVM for each feature
  Views/           Calculator, Tools, Journal, History, Settings, Components
  Theme/           Design tokens (brand #19A492) + dark/light themes
  PrivacyInfo.xcprivacy
  Assets.xcassets  App Icon, Logo, empty states
docs/
  SaleSmartly_后台配置指南.md
```

## Design Source

UI/UX follows the HTML prototype (`index-19.html`) and
`Thrust_Wealth_移动端App需求文档.md`. Brand accent: `#19A492`.
