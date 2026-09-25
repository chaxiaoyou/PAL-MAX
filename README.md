# PJT ZA · Flutter

面向 Android / iOS 的行情 + 股票计算器应用。行情部分使用公开的 Yahoo Finance
接口（quotes v7 / chart v8 / symbol search v1 / 新闻 RSS），计算器部分为本项目
自带的纯 Dart 计算逻辑（无网络依赖）。

## 功能

底部三个 Tab：

- **Watchlist（自选）**：行情卡片网格（代码、名称、现价、涨跌幅/涨跌额，红绿
  配色），下拉刷新 + 按设置间隔自动刷新，标题显示 Last fetch / Next fetch。
- **Calculators（计算器）**：11 个交易/投资计算工具，支持搜索与分类筛选、收藏：

  | 工具 | 用途 |
  | --- | --- |
  | Compound Interest | 复利终值、逐年明细 |
  | Risk / Reward | 风险回报比、期货保证金与保证金收益率 |
  | Position Cost | 多次建仓/减仓的持仓均价 |
  | Position Size | 由最大亏损反推仓位 |
  | Dividend Reinvest | 股息率与红利再投份数 |
  | Asset Allocation | 资产配置比例与剩余额度 |
  | Profit & Loss | 多空盈亏与手续费 |
  | Target Price | 由目标收益率反推目标价 |
  | Annual Return | 总收益率与年化收益率 |
  | Time to Target | 达到目标所需年限 |
  | ROI Calculator | 投入回报率与净收益 |

  每个计算器可把当前输入/结果 **保存** 成记录（Isar 持久化）。
- **Saved（已保存）**：计算记录列表，可展开查看输入/结果、重新载入计算器或删除。

其他能力：

- **实时行情**：Yahoo Finance v7 quotes，复刻 cookie + crumb 引导流程
  （GDPR consent → getcrumb → 带 crumb 请求）。
- **添加股票**：Yahoo symbol search 搜索建议，附 Trending 列表一键加入/移除。
- **行情详情**：大字号报价头 + 1D / 2W / 1M / 3M / 1Y / 5Y / Max 图表
  （自绘平滑面积图，无第三方图表库）+ 关键统计 + 相关新闻 RSS（点击用系统浏览器打开）。
- **Android 桌面小组件**：2×4 网格展示自选快照（RemoteViews，无第三方插件）。
  Flutter 每次刷新成功后通过 `PJZA/stocks_widget` 通道把快照同步到原生层并立即
  刷新小组件；点击小组件打开 App，支持浅色/深色快照。
- **设置**：跟随系统/浅色/深色主题、自动排序、两位小数开关、刷新间隔、数据来源。
- **纯原生**：界面全部由 Flutter 原生绘制，不加载任何网页内容；本地偏好与计算记录走 Isar。

## 品牌与包名

- 应用名：**PJT ZA**（Android `android:label`、iOS `CFBundleDisplayName`、
  启动页、桌面小组件标题、Dart 侧 `kAppName`）。
- 启动图标：`assets/icon/app_icon.png`，通过 `flutter_launcher_icons` 生成
  Android mipmap 与 iOS AppIcon 各尺寸。
- **包名**：Android `namespace` / `applicationId` 与 iOS
  `PRODUCT_BUNDLE_IDENTIFIER` 均为 `com.arslan.pdfprotoolkit`
  （Kotlin 源码位于 `android/app/src/main/kotlin/com/arslan/pdfprotoolkit/`）。
- **签名**：release 使用 `android/key.properties`（该文件被 git 忽略，不入库）
  指向的 keystore；本机当前指向
  `~/Downloads/Telegram Desktop/com.arslan.pdfprotoolkit/key.jks`，
  alias `pdfpro`。换机器时只需替换 `android/key.properties`。
## 技术栈

| 依赖 | 用途 |
| --- | --- |
| Flutter 3.47 (Dart 3.13) | 跨平台 UI |
| flutter_riverpod 2.x | 状态管理 |
| isar_community 3.3.2 | 自选/偏好/计算记录本地持久化 |
| intl | 数字/日期格式化 |
| url_launcher | 详情页新闻用系统浏览器打开 |

## 运行

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # 模型生成
flutter run
```

## 测试与检查

```bash
flutter analyze
flutter test
```

## 发布打包

```bash
./tool/build_release.sh        # APK + AAB
./tool/build_release.sh apk
./tool/build_release.sh aab
./tool/build_release.sh ipa    # 需 macOS + Xcode
```

发布包处理方式：

- Dart 层 `--obfuscate`：标识符（变量名/类名）混淆，AOT 产物不含源码注释；
  `--split-debug-info=build/symbols` 导出符号表，用于还原线上崩溃堆栈。
- Android 原生层 R8：`isMinifyEnabled` + `isShrinkResources` 已开启，
  `proguard-rules.pro` 用 `-renamesourcefileattribute SourceFile` 隐藏源码信息。
- **务必备份 `build/symbols`**，否则线上崩溃堆栈无法还原。

正式上架前请在 `android/app/build.gradle.kts` 配置自己的签名（当前走仓库外
`android/key.properties` 指向的 keystore）。

## 项目结构

```text
lib/
├── main.dart                       # 入口：打开 Isar 后启动
├── app.dart                        # MaterialApp（主题 + 系统栏样式）
├── theme/app_theme.dart            # PJT ZA 主题与配色（深浅两套）
├── data/tools.dart                 # 计算器目录（11 个工具）
├── models/                         # Quote / SavedRecord / ToolDefinition
├── providers/providers.dart        # Riverpod：自选、偏好、计算记录、收藏、Yahoo API
├── services/
│   ├── database_service.dart       # Isar 初始化
│   ├── yahoo_service.dart          # Yahoo quotes/chart/search/news + crumb
│   └── widget_sync.dart            # 行情快照 → Android 桌面小组件
├── screens/
│   ├── root_shell.dart             # 底部导航（Watchlist / Calculators / Saved）
│   ├── home_screen.dart            # 自选行情网格
│   ├── tools_screen.dart           # 计算器目录
│   ├── calc_scaffold.dart          # 计算器外壳（返回/保存/保存为）
│   ├── calculators/                # 11 个计算器页面
│   ├── history_screen.dart         # 已保存的计算记录
│   ├── search_screen.dart          # 搜索 / Trending
│   ├── quote_detail_screen.dart    # 报价详情 + 图表 + 统计 + 新闻
│   └── settings_screen.dart        # 设置
├── widgets/
│   ├── common.dart                 # 计算器共用控件（输入框/卡片/结果面板/表格）
│   ├── save_dialog.dart            # 保存计算记录弹窗
│   ├── quote_card.dart             # 行情卡片
│   └── price_chart.dart            # 自绘平滑面积图
└── utils/
    ├── calculators.dart            # 全部计算逻辑（纯函数，可单测）
    ├── format.dart                 # 价格/百分比/大数/日期格式化
    └── input_formatter.dart        # 数字输入（千分位、两位小数）
```

Android 原生部分：

```text
android/app/src/main/kotlin/com/arslan/pdfprotoolkit/
├── MainActivity.kt            # MethodChannel 接收快照
└── StocksWidgetProvider.kt    # AppWidgetProvider + RemoteViews 渲染
android/app/src/main/res/
├── layout/stocks_widget.xml   # 2×4 网格布局
├── xml/stocks_widget_info.xml # 小组件配置（可缩放）
└── values/widget_strings.xml
```

## License

行情接口与部分设计思路参考开源项目 premnirmal/stockticker（GPL），仅供学习参考。
