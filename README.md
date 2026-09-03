# Stocks Widget · Flutter Replica

Flutter + Dart（Android / iOS）复刻的开源项目
[premnirmal/stockticker](https://github.com/premnirmal/stockticker)
（Play Store 上的 Stocks Widget）。原项目是 Kotlin Multiplatform + Compose，
本项目用 Flutter 重新实现其核心应用界面与数据逻辑。

## 已实现功能

- **Watchlist 首页**：行情卡片网格（代码、名称、现价、涨跌幅/涨跌额，红绿配色），
  下拉刷新 + 按设置间隔自动刷新，标题显示 Last fetch / Next fetch。
- **Android 桌面小组件**：2×4 网格展示 watchlist 快照（RemoteViews 实现，无
  第三方插件）。Flutter 每次行情刷新成功后通过 `pal_max/stocks_widget` 通道把
  快照同步到原生层并立即刷新小组件；点击小组件打开 App。支持浅色/深色快照。
- **实时行情**：直接使用与原项目相同的 Yahoo Finance v7 quotes 接口，
  并复刻原项目的 cookie + crumb 引导流程（GDPR consent → getcrumb → 带 crumb 请求）。
- **添加股票**：Yahoo symbol search 搜索建议，附 Trending 列表一键加入/移除。
- **行情详情**：大字号报价头 + 1D / 2W / 1M / 3M / 1Y / 5Y / Max 图表
  （Yahoo v8 chart，自绘平滑面积图，无第三方图表库）+ 关键统计 + 相关新闻 RSS。
- **设置**：跟随系统/浅色/深色主题、自动排序、两位小数开关、刷新间隔、数据来源说明。
- **配置请求保留**：启动时仍请求后端 `app.conf`（`AppConfService`），返回 `steer`
  时整体替换为 WebView 页面；本地偏好仍走 Isar `AppSetting`。

## 与原项目的差异（当前阶段）

- Android 桌面小组件为“快照版”：展示 App 最近一次成功拉取的行情；小组件
  自身没有原生后台定时联网刷新（App 在前台按间隔自动刷新并同步），App 被
  彻底杀后台后不会自动更新行情。
- iOS WidgetKit 扩展尚未移植。
- 持仓/组合、提醒、导入导出、新闻详情页的多页面视图等高级功能未纳入本次范围。
- 数据源为公开 Yahoo Finance 接口，随 Yahoo 政策变化可能限流，界面保留重试入口。

## 技术栈

| 依赖 | 用途 |
| --- | --- |
| Flutter 3.47 (Dart 3.13) | 跨平台 UI |
| flutter_riverpod 2.x | 状态管理 |
| isar_community 3.3.2 | 本地偏好持久化（AppSetting） |
| intl | 数字/日期格式化 |
| webview_flutter | app.conf steer 与详情页新闻打开 |
| image_picker | WebView 内文件上传（保留原能力） |

## 运行

```bash
cd PAL-MAX
flutter pub get
dart run build_runner build   # 模型生成（app_setting/saved_record）
flutter run
```

## 测试与检查

```bash
flutter analyze
flutter test
```

## 发布打包

保留仓库内的安全打包脚本（混淆 + 符号表）：

```bash
./tool/build_release.sh        # APK + AAB
./tool/build_release.sh apk
```

注意：当前 release 仍使用 debug 签名，正式上架前请在
`android/app/build.gradle.kts` 配置自己的签名。

## 项目结构

```text
lib/
├── main.dart                      # 入口：打开 Isar 后启动
├── app.dart                       # MaterialApp + app.conf steer 门卫
├── theme/app_theme.dart           # Stocks Widget 主题与配色
├── models/quote.dart              # Quote / ChartPoint / SearchResult / NewsItem
├── providers/providers.dart       # Riverpod：watchlist + 偏好 + Yahoo API
├── services/app_conf_service.dart # 后端 reg_conf（保留）
├── services/database_service.dart # Isar 初始化（保留）
├── services/yahoo_service.dart    # Yahoo quotes/chart/search/news + crumb
├── services/widget_sync.dart      # 行情快照 → Android 桌面小组件
├── screens/
│   ├── home_screen.dart           # watchlist 首页
│   ├── search_screen.dart         # 搜索 / Trending
│   ├── quote_detail_screen.dart   # 报价详情 + 图表 + 统计 + 新闻
│   ├── settings_screen.dart       # 设置
│   └── webview_screen.dart        # steer / 外链 WebView（保留）
├── widgets/
│   ├── quote_card.dart            # 行情卡片
│   └── price_chart.dart           # 自绘平滑面积图
└── utils/format.dart              # 价格/百分比/大数格式化
```

Android 原生部分：

```text
android/app/src/main/kotlin/com/example/pal_max/
├── MainActivity.kt            # MethodChannel 接收快照
└── StocksWidgetProvider.kt    # AppWidgetProvider + RemoteViews 渲染
android/app/src/main/res/
├── layout/stocks_widget.xml   # 2×4 网格布局
├── xml/stocks_widget_info.xml # 小组件配置（可缩放）
└── values/widget_strings.xml
```

## License 声明

原项目 premnirmal/stockticker 采用 GPL 许可；复刻仅作参考学习用途。
