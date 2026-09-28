# Thrust Wealth — iOS App

Standalone trading risk & position sizing utility built with **SwiftUI**.

## Open & Run

1. Open `ThrustWealth.xcodeproj` in Xcode 16+
2. Select an iPhone simulator (iOS 17+)
3. Press **Run** (⌘R)

Bundle ID: `com.thrustwealth.tools`  
Display Name: **Thrust Wealth**  
Category: Utilities

## Build & Package

运行根目录打包脚本即可自动打包，生成命名格式为 `APP名字+版本号+日期` 的安装包与归档文件：

```bash
./build.sh
```

打包产物输出至 `build/` 目录：
- `build/ThrustWealth_1.0.0_<YYYYMMDD>.ipa`
- `build/ThrustWealth_1.0.0_<YYYYMMDD>.xcarchive`

## Features

| Tab | Features |
|-----|----------|
| **Calculator** | Lot size (By Risk / By Lots), live results, presets, quick symbols, history, search tools |
| **Tools** | P/L Calculator, Market Specs (search / favorites / custom instruments) |
| **Journal** | Trade log, Net P/L / Win Rate / R:R / Max DD, CSV export |
| **Settings** | Currency, theme, default symbol/leverage, data export & purge, **Contact Support**, Privacy / Terms / About |

Calculator / journal data stays **local**. Optional support chat loads SaleSmartly's dedicated service link in an in-app WebView only after privacy consent.

## SaleSmartly Support Chat

1. Admin completes backend setup — see [`docs/SaleSmartly_后台配置指南.md`](docs/SaleSmartly_后台配置指南.md)
2. Fill placeholders in `ThrustWealth/Services/ChatConfig.swift`:
   - `serviceLinkURL`
   - custom field IDs
3. First launch: user must tap **Agree & Continue**
4. Open **Settings → Contact Support**

The service link is opened with `loginSource=postMessage`; the app posts a stable visitor ID and `setLoginInfo` payload after the page finishes loading. No SaleSmartly iOS native SDK package is required for this planned H5 flow.

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
