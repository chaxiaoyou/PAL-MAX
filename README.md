# PAL MAX · Stock Trading Calculator

A clean, minimal, light-themed stock trading calculator app built with
**Flutter + Dart**, targeting **Android / iOS**.

## Features

- Home tool list with **All / Investment / Trading** tabs, rounded cards with
  icons and descriptions, favorites, and search.
- 11 real-time calculators: Compound Interest (with yearly breakdown table),
  Risk / Reward (long / short, spot / futures), Position Cost (multiple entries
  with dates), Position Size, Dividend Reinvestment, Asset Allocation
  (amount / percent auto cross-calc), Profit & Loss, Target Price, Annual
  Return, Time to Target, and ROI.
- Every calculator updates results in real time as you type — no calculate
  button needed.
- Number inputs accept only digits and a decimal point, with automatic
  thousands separators (e.g. 10,000.00).
- Bottom **Save / Save As** buttons persist records with the
  **Isar (`isar_community`)** local database; the history screen lets you
  expand, load, and delete saved records.
- Every page shows the disclaimer: *This tool is for demonstration only and
  does not constitute investment advice.*
- State management with Riverpod; UI built only with native widgets (no large
  third-party UI libraries).

## Tech Stack

| Dependency | Purpose |
| --- | --- |
| Flutter 3.47.1 (Dart 3.13) | Cross-platform framework |
| flutter_riverpod 2.x | State management |
| isar_community 3.3.2 | Local database (official Isar no longer supports Dart 3; the community fork keeps the same API) |
| intl | Thousands separators |
| path_provider | Database directory |

> Note: the official `isar` / `isar_generator` 3.1.0+1 packages constrain the
> SDK to `>=2.17.0 <3.0.0`, so they are incompatible with modern Flutter
> (Dart 3). This project uses the community-maintained `isar_community` line,
> which is API-compatible with the original.

## Release 打包与安全

推荐使用仓库内的打包脚本，它同时开启了两层防护：

```bash
./tool/build_release.sh        # 同时构建 APK 与 AAB
./tool/build_release.sh apk    # 只构建 APK
./tool/build_release.sh aab    # 只构建 AAB（Google Play 上架用）
```

- **Dart 层混淆**：构建时带 `--obfuscate --split-debug-info=build/symbols`，
  类名/方法名会被打乱。
- **Android 原生层**：`android/app/build.gradle.kts` 的 release 构建已开启
  R8（`isMinifyEnabled` / `isShrinkResourcesEnabled`），
  规则见 `android/app/proguard-rules.pro`。
- **符号表备份**：`build/symbols/` 用于把崩溃日志中的混淆符号还原成可读的
  类名和方法名。发布后务必备份该目录，不要删除。

> 上架国内应用市场时，通常还要求**加固**（如 360 加固、腾讯乐固等）。
> 该步骤需要把构建好的 APK 上传到对应平台处理，属于外部服务，无法在本地
> 完成；处理后再用平台提供的加固包上架即可。

> 注意：当前 release 仍使用 debug 签名（`signingConfigs.getByName("debug")`），
> 正式发布前请在 `android/app/build.gradle.kts` 中换成自己的签名配置。

## Requirements

- Flutter 3.35 or newer (Dart 3.9+); latest stable is recommended.
- VS Code with the Flutter and Dart extensions.
- Android: Android Studio / emulator or a device with USB debugging enabled.
- iOS: macOS with Xcode and the iOS Simulator.

## Running in VS Code

```bash
# 1. Enter the project directory
cd PAL-MAX

# 2. Fetch dependencies
flutter pub get

# 3. Generate Isar code (models live in lib/models/)
dart run build_runner build

# 4. Run
flutter run
```

You can also press `F5` in VS Code (`.vscode/launch.json` is already set up).

### If the android/ios platform folders are missing

The repository contains all of `lib/` and `pubspec.yaml`. If `android/` or
`ios/` is missing, run once:

```bash
flutter create --platforms=android,ios --project-name pal_max .
```

This only adds the platform folders and does not overwrite code in `lib/`.

### Useful commands

```bash
flutter analyze        # static analysis
flutter test           # run calculation unit tests
flutter build apk      # build Android package
flutter build ios      # build iOS package (macOS + Xcode required)
```

## Project Structure

```text
lib/
├── main.dart                     # entry: opens Isar, then starts the app
├── app.dart                      # MaterialApp and theme
├── data/tools.dart               # metadata for the 11 tools
├── models/                       # Isar models (saved_record / app_setting)
├── providers/providers.dart      # Riverpod: saved records + favorites
├── services/database_service.dart# Isar database initialization
├── theme/app_theme.dart          # light theme
├── utils/                        # calculations, formatting, input filter
├── widgets/                      # number fields, cards, tables, disclaimer
└── screens/
    ├── home_screen.dart          # home tool list
    ├── history_screen.dart       # saved records
    ├── calc_scaffold.dart        # shared calculator layout + save flow
    └── calculators/              # the 11 calculator pages
```

## Disclaimer

This tool is for demonstration only and does not constitute investment advice.
