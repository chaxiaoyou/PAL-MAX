# 新 App 差异化方案（客户 B）

## 进度

| 步骤 | 状态 |
| --- | --- |
| 1 信息架构 + 数据模型 | 领域模型与算法已落地（见下） |
| 2 `MarketDataProvider` 抽象 | 已落地，当前挂 Yahoo 实现，换商用源只改一个类 |
| 3 组合模块 | 完成：界面（仪表盘 + 配置 + 持仓表）+ Isar 持久化 |
| 4 提醒模块 | 完成（前台触发）：规则、判定、列表、增删改、本地通知、触发回写 |
| 5 计算器替换 | 未开始（旧计算器暂留在 Mercado 之外，未接入新壳） |
| 6 视觉系统 + 商店素材 | 未开始（先用现有主题，避免半成品视觉） |
| 多语言基础（en / es） | 已完成 |

已落地的代码：

```text
lib/domain/instrument.dart      # Instrument / InstrumentType
lib/domain/transaction.dart     # Transaction / TradeSide
lib/domain/position.dart        # Position / PriceSnapshot / AllocationSlice
                                # PortfolioValuation / LedgerWarning / LedgerResult
lib/domain/portfolio_math.dart  # buildLedger / valuePortfolio / investedTimeline
lib/domain/alert.dart           # Alert / AlertKind / evaluateAlert(s)
lib/data/market_data.dart       # MarketDataProvider 接口 + Yahoo 实现
lib/data/portfolio_store.dart   # PortfolioStore 接口 + 内存实现 + 派生 provider
lib/data/isar_portfolio_store.dart  # Isar 实现（落库）
lib/models/stored_transaction.dart  # 流水持久化模型 + 枚举 code 映射
lib/models/stored_alert.dart        # 提醒持久化模型
lib/screens/app_shell.dart      # 顶部导航外壳（Portafolio / Mercado / Alertas）
lib/screens/portfolio_screen.dart  # 仪表盘、配置条、持仓表、录入面板
lib/screens/alerts_screen.dart  # 提醒列表、状态、距触发距离、新建面板
lib/services/alert_notifier.dart   # 通知投递接口 + flutter_local_notifications 实现
lib/services/alert_dispatcher.dart # 触发→通知→回写，保证只响一次
test/portfolio_math_test.dart   # 成本、盈亏、超额卖出、估值、汇率、缺失报价
test/alerts_test.dart           # 触发条件、距离、重复触发抑制、禁用规则
test/portfolio_screen_test.dart # 仪表盘/提醒页渲染、缺报价提示、空状态
test/portfolio_store_test.dart  # 落库往返、同 id 覆盖不重复、种子数据不覆盖真实数据
test/alert_dispatch_test.dart   # 只响一次、拒绝授权也回写、单条失败不影响其余
```

### 当前已知缺口

1. **通知只在应用运行时触发**。价格轮询发生在 app 前台/刷新时，所以 app 被完全杀掉
   或在后台时不会检查阈值。真正的后台推送要么接服务端任务，要么用 WorkManager
   周期任务（Android 最短 15 分钟，且受省电策略限制）。这是产品决策，不是实现遗漏。
2. **演示数据默认开启**：`DEMO_PORTFOLIO` 默认 true，方便直接看到成品形态；
   对外的包必须带 `--dart-define=DEMO_PORTFOLIO=false`。
3. 新壳只用了 Mercado 一栏承载旧的自选行情，旧的计算器尚未接入新信息架构。

## 存储选型（2026-09-27 修订）

原方案写的是 drift（SQLite），**实际落地改成 Isar**，理由是原方案的前提不成立了：

drift 的唯一优势是关系型聚合查询（按标的聚合、按时间切片）。但组合的派生值全部由
`domain/portfolio_math.dart` 的纯函数计算，数据库只承担按 id 的增删改查，聚合查询
根本没有出场机会。为此再引入一套 SQLite：多一个原生库、多一份 codegen（还要和现有
isar 生成器抢 analyzer 版本）、应用里同时存在两个存储引擎——收益是零。

改用 Isar 之后：不动依赖树、不新增原生库、整个应用只有一个存储引擎，而且
`PortfolioStore` 接口本来就为这种替换留好了位置，界面层一行没改。

唯一取舍是 `uid` 没建唯一索引：建索引会让 Isar 生成器吐出它仍标记为 experimental 的
API，`flutter analyze` 会多出 24 条警告（都在生成文件里，不该手改）。改成存储层自己
查重——组合规模是几百行量级，扫描成本可以忽略，行为由
`test/portfolio_store_test.dart` 的「同 id 覆盖不重复」用例锁住。

记账口径：**移动加权平均成本**（墨西哥券商报 ISR 用的口径）。买入手续费计入成本，
卖出手续费冲减收入；卖光后成本价归零，避免下一笔买入继承旧成本；超卖不会产生负持仓，
而是收口到已有数量并产出一条 `LedgerWarning`。

## 原则

差异来自**产品本身**：功能集合、领域模型、数据来源、交互范式、视觉系统。技术栈按工程
理由选型，不为了“看起来不一样”去改代码形态。产品真的不同了，两个包自然不相似——这是
结果，不是手段。反过来，针对相似度检测做反向改造（改标识符、打散结构、换字符串、加噪声）
不产生任何产品价值，不做。

## 定位对比

| 维度 | 现有 App | 新 App（客户 B） |
| --- | --- | --- |
| 核心场景 | 看行情 + 算交易 | 管持仓 + 等提醒 |
| 首页 | 自选列表（卡片流） | 组合总览（仪表盘 + 持仓表） |
| 数据模型 | Quote / SavedRecord | Instrument / Position / Transaction / Alert |
| 计算器 | 11 个交易/投资工具 | 另一套：CETES、ISR、IVA、实际收益、UDIS |
| 市场侧重 | 美股 + 美指 | BMV / IPC 优先，比索计价 |
| 导航 | 底部 3 Tab | 顶部导航（组合 / 市场 / 提醒 / 工具） |

## 功能清单

1. **组合跟踪 Portafolio**：多笔买卖流水，移动加权成本、已实现/未实现盈亏、仓位占比、
   收益曲线（全部本地计算，不上传持仓）。
2. **价格提醒 Alertas**：按目标价或涨跌幅阈值建规则，本地通知触发，可暂停/删除。
3. **墨西哥市场优先**：IPC 指数、BMV 上市公司、MXN 计价格式化、CETES 参考利率。
4. **本地化计算器**：CETES 到期收益、ISR 预扣、IVA 拆分、通胀调整后实际收益、UDIS 换算。
5. **按持仓聚合的资讯**：只显示用户持有标的相关的新闻，点开走系统浏览器。

## 数据源选型

现状用的是 Yahoo Finance 非公开接口（v7/v8/v1 + cookie/crumb 引导）。这条路有两个问题：
接口随时可能变，且属于服务条款灰色地带，审核期或上线后被封会直接导致应用不可用。

建议换正规数据源，按覆盖度排序：

| 候选 | 覆盖墨西哥 | 免费额度 | 备注 |
| --- | --- | --- | --- |
| Finnhub | 部分（`.MX` 后缀） | 有 | 报价 + 基本面，接口稳定 |
| Twelve Data | 部分 | 有 | 历史 K 线较全 |
| Polygon | 弱（偏美股） | 有 | 美股最强，墨西哥弱 |
| BMV 官方数据 | 完整 | 需商务 | 要做墨西哥本地深度，最终得谈 |

落地方式：抽象一层 `MarketDataProvider` 接口，上层只依赖接口，先接一个商用 API，
本地做缓存与离线回退。切源不影响业务代码。

## 架构

- 保留 Flutter + Riverpod（工程理由：现有团队熟悉，Riverpod 适合这类数据流）。
- 重做数据层与领域模型：`Instrument`（标的）、`Position`（持仓）、`Transaction`（流水）、
  `Alert`（提醒）。现在的 `Quote` 只是个行情快照，撑不起组合跟踪。
- 本地存储沿用 **Isar**（详见下方「存储选型（修订）」）。原计划的 drift 已撤销：
  派生值都在 Dart 里算，数据库不需要聚合查询能力。
- 通知用 `flutter_local_notifications` + 后台任务调度做提醒触发。

## 交互与视觉

- 首页 = 组合总览：总市值、当日盈亏、收益曲线、持仓表（可排序、可分组）。
- 持仓用高密度表格而不是卡片流；提醒用时间轴列表。
- 视觉系统从零做：新配色（不走现有的深蓝）、新字阶、新图标风格、新圆角体系、
  自定义空状态插画。启动图标与启动页一并重做。

## 落地顺序

| 步骤 | 产出 | 依赖 |
| --- | --- | --- |
| 1 | 信息架构 + 数据模型定稿 | 客户确认核心场景 |
| 2 | `MarketDataProvider` 抽象 + 接入一个商用源 | 数据源选型 |
| 3 | 组合模块（流水录入、成本、盈亏、曲线） | 步骤 1、2 |
| 4 | 提醒模块（规则、通知、调度） | 步骤 1、3 |
| 5 | 计算器集合替换 | 步骤 1 |
| 6 | 视觉系统 + 商店素材 + 西语隐私政策与数据安全表单 | 全部 |

多语言基础设施已完成（en / es，ARB 在 `lib/l10n/`），新功能直接按同一套 key 体系加文案即可。

## 上架墨西哥清单

- 应用内文案 es-MX —— 已完成。
- 隐私政策（西语）+ 数据安全表单：必须与实际采集一致。
- 目标 API 级别、64 位支持、原生库合规。
- 金融类声明：不构成投资建议的免责声明要有西语版本（已加）。
