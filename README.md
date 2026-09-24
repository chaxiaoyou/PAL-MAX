# Axight · Flutter Replica

Flutter + Dart（Android / iOS）复刻的开源项目
[premnirmal/stockticker](https://github.com/premnirmal/stockticker)
（Play Store 上的 Needham Capital）。原项目是 Kotlin Multiplatform + Compose，
本项目用 Flutter 重新实现其核心应用界面与数据逻辑。

## 已实现功能

- **Watchlist 首页**：行情卡片网格（代码、名称、现价、涨跌幅/涨跌额，红绿配色），
  下拉刷新 + 按设置间隔自动刷新，标题显示 Last fetch / Next fetch。行情与持仓组合
  共用同一个 `QuoteBoard`，不重复请求。
- **持仓组合（Stock Events 方向的第一步）**：Portfolio Tab。逐笔记录持股数量与
  平均成本，用实时行情算出市值、总收益/收益率、当日盈亏；按币种分组汇总，
  不同币种绝不直接相加；没有报价的持仓显示为「无报价」并被排除在合计之外，
  不会被当成 0 计入亏损。
- **股息收入追踪**：读取 Yahoo 的历史派息记录，算出每个持仓近 12 个月的现金股息、
  组合合计，以及相对你自己成本的股息率。按币种分组，同样是不同币种不混算。
- **交易流水与已实现盈亏**：记录每笔买入/卖出，持仓由流水推算（移动平均成本），
  组合页显示已卖出的实际盈亏。点持仓行进入该标的的流水页。
- **价格提醒**：给任意标的设一个价位，价格**穿越**该价位时发本地通知（不是停在
  上方就一直响）。设置 → Price alerts 管理，个股详情页右上角铃铛直接新建。
- **Android 桌面小组件**：2×4 网格展示 watchlist 快照（RemoteViews 实现，无
  第三方插件）。Flutter 每次行情刷新成功后通过 `NeedhamCapital/stocks_widget` 通道把
  快照同步到原生层并立即刷新小组件；点击小组件打开 App。支持浅色/深色快照。
- **实时行情**：直接使用与原项目相同的 Yahoo Finance v7 quotes 接口，
  并复刻原项目的 cookie + crumb 引导流程（GDPR consent → getcrumb → 带 crumb 请求）。
- **添加股票**：Yahoo symbol search 搜索建议，附 Trending 列表一键加入/移除。
- **行情详情**：大字号报价头 + 1D / 2W / 1M / 3M / 1Y / 5Y / Max 图表
  （Yahoo v8 chart，自绘平滑面积图，无第三方图表库）+ 关键统计 + 相关新闻 RSS。
- **设置**：跟随系统/浅色/深色主题、自动排序、两位小数开关、刷新间隔、数据来源说明。
  已从首页齿轮入口改为底部导航的一个 Tab。
- **启动中转页**：App 打开先进入 `SplashScreen`，在那里请求后端 `app.conf`
  （`AppConfService`）。返回 `steer` 就整体切到 WebView（原生界面根本不出现），
  没有就进主界面；切换用 `pushReplacement` + 淡入，返回键回不到中转页。
  请求失败**不会放行**：会一直重试（这是后端的开关，猜错方向的代价更大），但界面上
  会显示「Still connecting…」并给一个 Retry，而不是无声转圈。本地偏好仍走 Isar
  `AppSetting`。

## 与原项目的差异（当前阶段）

- 导航改成底部三个 Tab（Watchlist / Portfolio / Settings）。原项目只有自选股一个
  主界面，设置是右上角齿轮；持仓组合本身也超出原项目范围，是朝 Stock Events 方向
  新增的能力。
- Android 桌面小组件为“快照版”：展示 App 最近一次成功拉取的行情；小组件
  自身没有原生后台定时联网刷新（App 在前台按间隔自动刷新并同步），App 被
  彻底杀后台后不会自动更新行情。
- iOS WidgetKit 扩展尚未移植。
- 导入导出、新闻详情页的多页面视图等高级功能未纳入本次范围。
- 数据源为公开 Yahoo Finance 接口，随 Yahoo 政策变化可能限流，界面保留重试入口。

## 持仓组合：这一版做了什么、没做什么

**做了什么**

- `Holding`（Isar 集合）存标的、股数、平均成本、币种。市值和盈亏一律由实时行情
  推导，所以不存在“陈旧价格被当成真实价格”的问题。一旦某个标的有了交易流水，
  持仓就以流水为准，手工填的股数和成本只作没有流水时的兜底。
- **交易流水**：`Transaction` 记录每一笔买入/卖出（股数、价格、费用、日期、币种）。
  用移动平均成本法推算当前股数、平均成本和**已实现盈亏**；卖掉的部分会从成本池里
  扣掉，均价保持不变。卖出数量超过流水记录时会明确提示，而不是编出一个负数持仓。
  持仓行点进去就是该标的的流水页；手工录入的持仓可以一键转成流水（写入一笔
  「Opening balance」），避免「先卖后无买入记录」这种空账。
- `PortfolioSummary` 负责全部计算：单笔市值/盈亏/收益率、当日盈亏、按币种汇总。
  纯函数、无副作用，`test/portfolio_math_test.dart` 覆盖。
- 币种不混算：不同币种各自汇总，头部大字显示市值最大的那种，其余单列。
- 报价失败的持仓显示 `--` 和「no quote」，并计入提示行，**不计入合计**。
- 刷新失败不会清空已经显示的市值：卡片保留上一次成功的时间戳，配合错误条说明
  这次刷新失败，数字不会被当成「实时」。
- 新增/编辑走同一个底部弹层：标的通过 Yahoo 搜索解析，自动带出名称、币种和
  当前价（当前价只作参考，不预填成本价，避免默认收益率为 0 的误导）。搜索不可用时
  可以用「Use "XXX" as a symbol」手动录入，此时币种改为手动选择。
- **行情只拉一次**：watchlist 和 portfolio 各自把关心的标的注册到 `QuoteBoard`，
  由它去重后按并集请求，同时独占刷新定时器。同一只股票同时出现在自选和持仓里，
  也只有一个请求；移除标的后它的报价会被清掉。
- **股息收入**：历史派息一次抓取后缓存在内存里，不跟着行情轮询走（派息按季度才变）。
  同一只股票只抓一次；抓不到的标的会记下来，只有点「Retry」才重试，不会每次
  持仓变化都重发请求。
- 股息按**派息当天的持股数**计：流水里有每笔交易的日期，所以派息能落到当时的
  持仓上，而不是笼统地按今天的股数折算。没有流水的持仓才回退到估算口径。

**刻意没做**

- **拆股/合股：当前阶段明确不做。** 流水按原始股数记录，发生拆股后股数与均价会和
  券商口径不一致，需要自己补一笔调整交易。做自动化要拿到公司行为数据（同下），
  现阶段收益不抵成本——这是决定，不是遗漏。
- 逐笔（FIFO）成本与分币种盈亏归集：当前统一用移动平均成本法，同一只股票不会
  按批次分别计税。这是取舍，不是遗漏。
- **未来的**股息/派息日历与财报日历仍然卡在数据源选型上：历史派息 Yahoo 给得出，
  「下一次什么时候派、派多少」和财报日期它给不可靠，Stock Events 用的是付费数据源。
  所以目前只能做价格提醒，做不了「除息前提醒」。
- 股息收入的口径分两种，界面会说明当前用的是哪种：有流水的持仓，每笔派息按
  **派息当天的持股数**计算（流水推得出来），是精确值；只有手工录入、没有流水的
  持仓才按今天的股数估算，年内加减过仓的会偏高或偏低。

## 价格提醒：触发规则与当前边界

- **只在穿越时触发。** 第一次看到某只股票时只记录它在阈值的哪一侧，不通知；
  之后只有从下往上穿过（Above）或从上往下穿过（Below）才发一次通知。所以设一个
  已经被满足的价位不会立刻响，价格一直停在上方也不会每次刷新都响。
- 改阈值、关掉再打开，都会**重新武装**（清掉上次的观测状态）。重新打开一个已经
  越过阈值的提醒不会立刻响，要等下一次真正的穿越。
- 触发状态（在哪一侧、上次触发时间）会写进数据库再发通知，所以重启 App 不会把
  同一次穿越重复播报。
- **App 关闭后由 Android 定时检查。** App 进程不在时，`AlertJobService` 用
  JobScheduler 起一个无头 Flutter 引擎，跑同一个 Dart 判定函数。真机验证过：
  服务启动 → 引擎加载 → 入口点解析 → Dart 侧读到规则并请求行情 → 完成后回报、
  任务收尾，且请求失败时不写任何状态。周期受系统限制（最短 15 分钟，Doze/省电
  模式会推迟）。App 进程还活着时后台任务主动让位，避免同一次穿越报两遍。
  `AlertBackground.BACKGROUND_CHECK_SUPPORTED` 是总开关，出问题时可以关掉，
  界面会如实改成「只在 App 运行时检查」。
- 这条路径上踩过并修好的三个真机 bug（都只能在设备上发现）：
  1. 缺 `ACCESS_NETWORK_STATE`，`JobScheduler.schedule` 抛 SecurityException，
     任务从未注册成功，而异常被上层 try/catch 吞成一行日志；
  2. 全新进程里 `lookupCallbackInformation` 早于 native 库加载 → 服务崩溃重启；
  3. `DartExecutor.DartEntrypoint` 的**两参数**构造函数是
     `(pathToBundle, functionName)`，会把 `dartEntrypointLibrary` 置为 null。
     按「(库, 函数)」调用就丢掉了库名，引擎报
     `Could not resolve main entrypoint function`。必须用三参数版本。
- **只做 Android，iOS 不在范围内**（用户明确要求）。通知走自己写的
  `MethodChannel`（`NeedhamCapital/alerts`）而不是第三方插件：渠道、Android 13+
  运行时权限、点击回到 App、后台定时任务都是原生实现，零新依赖，与桌面小组件
  同一套路子。
- **判定逻辑只有一份。** 前台和后台都调用 Dart 里的 `evaluateAlertRules`，Kotlin
  只负责调度、存取和发通知；连通知文案都由 Dart 生成。两套实现早晚会不一致，而
  症状是重复或漏报，所以刻意避免。
- 后台任务把规则当作不透明字符串存储，只有 Dart 知道「提醒」长什么样；App 启动时
  会把后台记录的状态合并回来，再开始自己检查，避免重复播报。
- 需要 Android 13+ 的 `POST_NOTIFICATIONS` 运行时权限，在**创建提醒时**才申请，
  不在启动时打扰。被拒绝时列表页会显示提示条，不会静默失败。
- **验证状态**：debug 与 release（R8 混淆 + AOT）构建均通过；已在 Android 17 模拟器
  上真机跑过——应用启动、三个 Tab、创建提醒、通知权限、JobScheduler 注册
  （`get-job-state` 返回 `waiting`）、以及后台任务完整跑一趟（引擎起来、入口点解析、
  Dart 后台代码执行、失败不落状态、任务收尾）。`evaluateAlertRules`、规则编解码、
  后台那一趟的完整流程都有测试。
- **尚未验证**：① 通知的真实投递（需要一次真实的价位穿越，而行情被网络挡住）；
  ② Yahoo 的**真实响应形状**——所有解析都用录制的报文钉在测试里，但从开发机发出
  的每一次请求都撞在地区封锁上，从未见过一次真实响应。`tool/check_yahoo.sh` 就是
  为此写的：在美国网络或可用的代理下跑一次，把输出贴回来即可确认解析是否要调整。

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

**一律用脚本出包**，不要用 IDE 或手敲 `flutter build`：漏掉 `--obfuscate` 就会把
Dart 类名、方法名原样留在 `libapp.so` 里（曾经发生过一次）。

```bash
./tool/build_release.sh        # APK + AAB
./tool/build_release.sh apk
./tool/build_release.sh aab
./tool/build_release.sh ipa    # iOS（macOS + Xcode 签名）
```

脚本做的事：

- Dart 层：`--obfuscate --split-debug-info=build/symbols`，混淆变量/类/方法名。
- Android 原生层：R8 压缩与重命名（`android/app/build.gradle.kts` + `proguard-rules.pro`）。
- **构建后自检**：扫描产物里的 `libapp.so`，只要还能搜到 `PortfolioScreen`、
  `_fetchOnce` 这类只在代码里作为符号存在的名字，就直接判定失败——混淆没生效的包出不去。

关于"去掉注释"：

- release 的 AOT 快照里**本来就没有注释和源码文本**，无需额外处理。
- **debug 包例外**：它会把整个 Dart 源码文本打进 `assets/flutter_assets/kernel_blob.bin`，
  连注释一起可以原文搜到。所以 debug 包不要外发；要给测试同学装包用 `--profile` 或
  上面的 release 包。
- `--obfuscate` **不隐藏字符串字面量**：接口地址、Yahoo/GitHub 链接在 `libapp.so`
  里仍是明文。要藏这些值只能改成由后端下发或构建期注入。

两个需要留意的残留信息：

- `libapp.so` 里会带构建机的绝对路径（例如 `file:///Users/<你的用户名>/.../dart_plugin_registrant.dart`），
  这是 Flutter 工具链写进去的，混淆去不掉。介意的话在 CI 或中性目录里出包，
  不要用本机个人目录。
- 构建日志里的 `unobfuscated DWARF debugging information` 警告针对的是中间产物；
  打进 APK 的 `libapp.so` 已经不带 `.debug_*` 段（AGP 打包时会 strip）。

签名：存在 `android/key.properties` 时走其中的 release keystore，否则回落到 debug 签名。

**崩溃还原**靠两份文件，务必随版本备份：`build/symbols/`（Dart）与
`build/app/outputs/mapping/release/mapping.txt`（Android/R8）。

## 项目结构

```text
lib/
├── main.dart                      # 入口：打开 Isar 后启动
├── app.dart                       # MaterialApp + app.conf steer 门卫
├── theme/app_theme.dart           # 品牌配色与主题 + 等宽数字
├── models/quote.dart              # Quote / ChartPoint / SearchResult / NewsItem
├── models/dividend.dart           # 单笔派息记录
├── models/dividend_income.dart    # 近 12 个月股息 + 股息率（纯函数）
├── models/holding.dart            # 持仓（Isar 集合）+ HoldingDraft
├── models/transaction.dart        # 交易流水（Isar 集合）+ TransactionDraft
├── models/position_ledger.dart    # 移动平均成本、已实现盈亏（纯函数）
├── models/price_alert.dart        # 价格提醒（Isar 集合）+ 穿越判定（纯函数）
├── models/portfolio_math.dart     # 市值 / 盈亏 / 按币种汇总（纯函数）
├── providers/providers.dart       # Riverpod：QuoteBoard + watchlist + 偏好 + portfolio
├── services/app_conf_service.dart # 后端 reg_conf（保留）
├── services/database_service.dart # Isar 初始化（保留）
├── services/yahoo_service.dart    # Yahoo quotes/chart/search/news + crumb
├── services/widget_sync.dart      # 行情快照 → Android 桌面小组件
├── services/alert_notifier.dart   # 提醒通知通道（Android 原生实现，可注入替换）
├── services/background_alerts.dart # 后台检查入口 + 规则编解码（与前台共用判定）
├── screens/
│   ├── splash_screen.dart         # 启动中转页：请求 app.conf 后决定去向
│   ├── root_shell.dart            # 底部导航外壳（Watchlist / Portfolio / Settings）
│   ├── home_screen.dart           # watchlist 首页
│   ├── portfolio_screen.dart      # 持仓组合 + 盈亏
│   ├── transactions_screen.dart   # 单只标的的流水与已实现盈亏
│   ├── alerts_screen.dart         # 价格提醒列表 / 选标的
│   ├── search_screen.dart         # 搜索 / Trending
│   ├── quote_detail_screen.dart   # 报价详情 + 图表 + 统计 + 新闻
│   ├── settings_screen.dart       # 设置
│   └── webview_screen.dart        # steer / 外链 WebView（保留）
├── widgets/
│   ├── quote_card.dart            # 行情卡片
│   ├── holding_editor_sheet.dart  # 新增/编辑持仓弹层
│   ├── transaction_editor_sheet.dart # 新增/编辑交易弹层
│   ├── alert_editor_sheet.dart    # 新增/编辑价格提醒弹层
│   └── price_chart.dart           # 自绘平滑面积图
└── utils/format.dart              # 价格/百分比/大数格式化
```

Android 原生部分：

```text
android/app/src/main/kotlin/com/toolnest/rulerratio/screen/ratio/utility/
├── MainActivity.kt            # MethodChannel：小组件快照 + 提醒权限/通知/规则同步
├── AlertBackground.kt         # 规则字符串存储 + JobScheduler 注册
├── AlertJobService.kt         # 无头 Flutter 引擎跑后台检查
├── AlertNotifications.kt      # 通知渠道与投递（前台/后台共用）
└── StocksWidgetProvider.kt    # AppWidgetProvider + RemoteViews 渲染
android/app/src/main/res/
├── layout/stocks_widget.xml   # 2×4 网格布局
├── xml/stocks_widget_info.xml # 小组件配置（可缩放）
└── values/widget_strings.xml
```

## License 声明

原项目 premnirmal/stockticker 采用 GPL 许可；复刻仅作参考学习用途。
