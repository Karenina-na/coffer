# GWP 前端 UI / 导航设计

## 1. 说明

本文件记录当前版本的信息架构、页面结构与交互设计，作为 UI 层实现基线。
架构层规范见 `doc/architecture.md`，数据模型见 `doc/data-definitions.md`。

## 2. 信息架构

应用采用 **Dashboard 总览 + 领域主页 + 二级 Tab** 的三层结构，底部五个主 Tab：

| # | 路径 | 图标 | 名称 | 说明 |
|---|---|---|---|---|
| 1 | `/dashboard` | dashboard_outlined | 仪表盘 | 净资产总览、跨币种聚合、快捷入口 |
| 2 | `/holdings` | account_balance_wallet_outlined | 资金 | 账户 / 资产 / 转账 / 分析四合一 |
| 3 | `/events` | event_note_outlined | 事件 | 领域事件流水 |
| 4 | `/rates` | currency_exchange_outlined | 汇率 | 汇率快照与手动导入 |
| 5 | `/cards` | credit_card_outlined | 卡片 | 账户关联卡片管理 |

设计取舍：

- **账户 / 资产 / 转账强绑定**：账户是资产的载体，转账发生在账户之间，三者共享上下文，合并到同一主页的二级 Tab 下，减少来回跳转。
- **汇率独立为主 Tab**：汇率影响所有跨币种估值，是与资产、账户平级的基础数据，不适合藏在快捷入口里。
- **仪表盘作为入口页**：启动默认路由，提供净资产 + 快捷操作，不做深度功能，避免与领域主页职责重叠。
- **卡片独立成页**：卡片有独立的安全字段（密文卡号、CVV），展示和管理逻辑与账户解耦。

## 3. 路由结构

```
ShellRoute                 // 底部导航壳，保持 NavigationBar 常驻
├── /dashboard             // 仪表盘
├── /holdings              // 资金（内含 4 个二级 Tab，支持 ?tab=0|1|2|3 预选）
├── /events                // 事件
├── /rates                 // 汇率
└── /cards                 // 卡片

// 以下路由在 Shell 之外，全屏呈现，无底部导航
/accounts/new              // 新建账户
/accounts/:id              // 账户详情
/assets/new                // 新建资产
/assets/:id                // 资产详情
/cards/new                 // 新建卡片
/events/new                // 新建事件（手动录入）
/channels                  // 通道列表
/channels/new              // 新建通道
/channels/:id              // 通道详情
/backup                    // 备份 / 恢复
/settings                  // 应用设置
```

**约定**

- 列表 / 概览类页面位于 Shell 内，保持导航连续性。
- 创建、详情、设置类页面位于 Shell 外，独占屏幕强化聚焦。
- **卡片详情不走路由**：通过 `CardDetailSheet.show(context, card:, account:)` 模态弹层呈现，保留底层列表上下文。

## 4. 页面设计

### 4.1 仪表盘 `/dashboard`

定位：净资产总览 + 跨币种聚合 + 快捷入口。

- **净资产卡片**：显示当前**全局计价货币**下的总额；AppBar 货币选择器会切换全局计价货币，并驱动仪表盘、资金分析、账户/资产列表与详情中的统计口径同步刷新。
- **统计摘要**：账户数量、资产数量；分别点击跳 `/holdings?tab=0` 与 `/holdings?tab=1`，直达对应二级 Tab。
- **缺失汇率提示**：若聚合过程中存在无法换算的资产，展示 `missingAssetIds` 提醒用户补录汇率，**点击跳 `/rates`**。
- **快捷入口**：转账通道管理、备份 / 恢复。
- **顶部搜索**：注册 `topSearchOpenerProvider` → 打开全局搜索（`SearchFeature.dashboard`，仅跨模块命中，不分模块过滤）。

数据流：

```
dashboardSummaryProvider (FutureProvider.autoDispose)
  ├── accountListProvider
  ├── assetListProvider
  ├── dashboardBaseCurrencyProvider (NotifierProvider<String>)
  └── AggregateAccountValueUseCase
       → DashboardSummary { baseCurrency, total, accountCount, assetCount, missingAssetIds }
```

### 4.2 资金 `/holdings`

定位：账户 / 资产 / 转账 / 分析 的统一工作台，使用 `TabBar` 承载四个二级 Tab。

| 二级 Tab | 内嵌组件 | FAB | AppBar 动作 |
|---|---|---|---|
| 账户 | `AccountListBody` | 新建账户 → `/accounts/new` | 备份 |
| 资产 | `AssetListBody` | 新建资产 → `/assets/new` | 备份 |
| 转账 | `TransferSimulateBody` | — | 通道管理 + 备份 |
| 分析 | `PortfolioAnalysisBody` | — | 同步资产行情 |

> **「转账」语义说明**：此处转账**不涉及账务变动**，仅用于基于 Channel 拓扑与费率模型**规划最优转移路径**（Route Planning）。用户选定源/目标账户及金额后，调用 `PlanTransferRouteUseCase`（`lib/domain/usecases/plan_transfer_route.dart`）以 **Account.id** 为节点跑 Dijkstra：图的边由 `AccountChannel` 派生——同一通道下的任意两个账户互为可达，规则引擎按 (from, to) 双方 `sovereignty_region` 过滤违规边。支持两种目标：
>
> - **费用最低（minFee）**：权重 = `amount * feeRate + fixedFee`
> - **跳数最少（minHops）**：权重恒为 1
>
> 返回的 `TransferRoute` 按顺序列出每一跳 `RouteLeg`（含 channel、起止 Account、单段手续费），UI 以 `节点链 + 逐段卡片` 形式呈现（节点标签为 `机构名 (账户类型)`）。被规则引擎判定违规的边会从候选中剔除，规划器自动绕行；若无可用边则回落为带 `violations` 的单跳不可执行 Route，展示拦截原因。
>
> **账户 ↔ 通道绑定**：账户详情页 `支持的转账通道` 区块维护当前账户声明支持的通道集合（添加 / 移除）；通道详情页 `成员账户` 区块只读展示所有已绑定该通道的账户，入口可跳转至账户详情。
>
> **账户级手续费配置**：账户详情页的通道区块除维护是否接入外，还可为当前账户配置该通道的账户级费用覆盖（比例费率 / 固定费 / 费用币种）。覆盖值为空时沿用通道默认值；`0` 为有效值，表示该账户在该通道上免手续费。路径规划按源账户的覆盖值计费。
>
> **对比模式**：顶部 `SwitchListTile`「对比模式」开启后，一次点击并行跑两种目标，结果并排渲染；若二者得到同一条路径则合并为单卡并标注"两种目标一致"，否则给出 `ΔFee` / `ΔHops` 差值，便于用户权衡费用与合规/稳定性。

实现要点：

- `HoldingsPage` 为 `ConsumerStatefulWidget`，`SingleTickerProviderStateMixin`，持有 `TabController`。
- **支持 `?tab=0|1|2` 预选 Tab**：构造参数 `initialTab` 由路由从 `state.uri.queryParameters['tab']` 解析传入，便于仪表盘深度链接。
- `TabController.addListener` 触发 `setState` 以切换 AppBar 动作与 FAB，并 `_syncTopSearch()` 按 Tab 切换全局搜索的 `current` 模块（账户/资产；转账 Tab 走 `SearchFeature.dashboard`）。
- 列表组件抽离为 **Body-only Widget**（`AccountListBody` / `AssetListBody` / `TransferSimulateBody`），避免 Scaffold 嵌套，便于复用。
- `TransferSimulateBody` 作为 Tab 内嵌组件，无独立 Page 类。

### 4.3 事件 `/events`

定位：领域事件流水展示，按时间倒序列出 `Event` 表内容，包含估值、转账、汇率更新等事件类型。

### 4.4 汇率 `/rates`

定位：汇率快照管理，展示最近快照、支持手动录入与远端拉取。

- **AppBar 动作**：
  - 「管理币对」→ 打开 `WatchedPairsPage`，用户维护关注的 `(base, quote)` 列表。
  - 「拉取最新」→ 调用 `RefreshWatchedRatesUseCase`，按 base 分组批量调用 Frankfurter，结果 upsert 到 `exchange_rates` 表。
- **FAB「录入」**：保留手动录入能力作为离线兜底。

**远端数据源：Frankfurter**（`api.frankfurter.dev/v1/latest`）

- 无需 API Key、无限额、ECB 官方参考汇率、33 种币种（含 CNY/USD/EUR/JPY/GBP/HKD 等）。
- `SnapshotType = DAILY`，`source = 'frankfurter'`，`rawPayload` 保留原始 JSON 响应以便溯源。
- 失败降级：任何网络/解析失败通过 SnackBar 反馈，不影响已有快照与手动录入。

**数据模型**

- 新增 `watched_pairs` 表（schemaV2 迁移）：`pair_key PK, base_currency, quote_currency, created_at`。
- 每次拉取生成新行（`id` 为 UUID），保留历史便于后续画趋势线。

### 4.5 卡片 `/cards`

定位：账户下卡片的列表与管理；敏感字段全部 masked，创建流程走独立路由。

- **列表**：`WalletCardTile` 点击 → `CardDetailSheet.show(...)` 弹出详情模态。
- **详情弹层**：新建卡片 / 详情都走 `CardDetailSheet`（非独立路由），展示脱敏卡号、按需解密明文、基本信息、信用卡额度、账单地址、关联账户等字段。

### 4.6 跨实体导航矩阵

本应用所有实体视图中展示的外键（FK）字段都必须可点击跳转至对应详情，保证信息不成为死胡同。当前实现：

| 出发位置 | 字段 | 跳转目标 | 实现 |
|---|---|---|---|
| `/accounts` 列表 | 账户行 | `/accounts/:id` | `AccountListPage._AccountTile` |
| `/accounts/:id` 资产区 | 单条资产 | `/assets/:id` | `_AssetRow` InkWell |
| `/accounts/:id` 卡片区 | 单条卡片 | `CardDetailSheet` | `_CardRow.onTap` |
| `/assets` 列表 | 资产行 | `/assets/:id` | `_AssetTile` |
| `/assets/:id` 关联账户卡 | `accountId` | `/accounts/:id` | `_AccountLinkCard` |
| `/cards` 列表 | 卡片行 | `CardDetailSheet` | `WalletCardTile.onTap` |
| `CardDetailSheet` 关联账户 | 账户（或 ID） | `/accounts/:id` | `_LinkRow`（pop 弹层后 push） |
| `/events` 事件详情 · account/asset | `relatedId` | `/accounts/:id` / `/assets/:id` | `_EventDetailSheet` 「打开」|
| `/events` 事件详情 · card | `relatedId` | `CardDetailSheet`（先加载 `BankCard`+`Account`）| `_EventDetailSheet.openRelated` |
| `/events` 事件详情 · channel | `relatedId` | `/channels/:id` | `_EventDetailSheet` 「打开」|
| `/rates` 主列表 | 币对行 | `PairDetailPage` | `_PairRateRow.onTap` |
| `/rates` 币对管理 | 币对行 | `PairDetailPage` | `_PairTile.onTap` |
| `/channels` 列表 | 通道行 | `/channels/:id` | `_ChannelTile` |
| `/dashboard` 账户/资产 Stat | — | `/holdings?tab=0 \| 1` | `_StatTile.onTap` |
| `/dashboard` 缺失汇率卡 | — | `/rates` | `_MissingRatesCard.onTap` |

原则：

- **FK 字段一律可点**：即便关联对象已被删除，UI 上也要用明显的 link 样式（色 + 下划线 + `chevron_right`）提示「可跳」，点击后由目的页面自行处理 404。
- **模态优先于路由**：卡片详情、事件详情均走 `showModalBottomSheet`，保持列表/日历上下文；跨模态跳转需 `Navigator.pop` 后再 `context.push`。
- **列表项整行可点**：避免只把文字可点，扩大点击区域。

### 4.7 全局搜索

统一由 `GlobalSearchDelegate` + `openGlobalSearch(context, ref, current:)` 驱动，覆盖所有底部 Tab 的 AppBar 搜索按钮。

- **入口**：`AppTopBar` 通过 `TopSearchAction`（读取 `topSearchOpenerProvider`）渲染 🔍；每个页面在 `initState` 注册自己的 `opener`，`dispose` 时 `set(null)`。不注册 opener 的页面不会显示按钮。
- **两段式结果**：
  1. **跨模块命中区**：按 `SearchFeature` 枚举顺序（accounts / assets / cards / rates / events）给出前 N 条；当前所在模块用「当前」徽标提示。
  2. **当前模块过滤区**：仅在 `current != dashboard` 时渲染，附带模块特定的 `SearchFilterGroup`（如账户类型、资产类型、卡片状态）。
- **类型擦除**：`FeatureSearchConfig<T>` 在构造期把泛型 callbacks (`match` / `itemBuilder` / `filter predicates`) 包装为 `dynamic`-typed 闭包，避免 Dart 函数逆变导致的运行时类型转换失败。
- **注册点**：`DashboardPage`, `HoldingsPage`（按 Tab 切换 current）, `CardListPage`, `ExchangeRateListPage`, `EventListPage`。

### 4.8 设置页辅助入口

设置页中的 App 级辅助入口遵循以下规则：

- **清除所有数据**：位于「危险区」，执行后锁屏并清空业务数据；
- **注入演示数据**：紧随「清除所有数据」展示，**release 也可用**；用于向空库或测试库注入一组单批次装配的演示数据，覆盖账户、资产、卡片、通道、汇率、事件与少量历史序列；源代码可按模块拆分实现，但对用户仍保持单一入口、单次注入的心智模型；
- 演示数据入口不再归类为 debug-only 工具，避免 release 验收时缺少可快速构造测试场景的能力。

## 5. 组件分层规范

所有列表类 Feature 采用 **Page / Body 两层结构**：

```
FeaturePage              // 含 Scaffold、AppBar、FAB，作为独立路由节点
└── FeatureBody          // 纯 body 内容，供 HoldingsPage / 其他组合场景复用
```

当前已落地：

- `AccountListPage` + `AccountListBody`
- `AssetListPage` + `AssetListBody`
- `TransferSimulateBody`（Body-only，无独立 Page）

未来新增列表类 Feature 遵循相同模式。

## 6. 状态管理约定

- **只读列表** → `FutureProvider.autoDispose` / `StreamProvider` 直连 Drift `watch*()`。
- **可变偏好状态**（如全局计价货币） → `NotifierProvider<Notifier, T>`，禁止使用已弃用的 `StateProvider`。
- **跨 Feature 聚合**（如仪表盘汇总） → 在 Presentation 层组合多个 Provider + UseCase，Domain 层保持纯粹。

## 7. 主题与 Material 3

- `ColorScheme.fromSeed` 统一取色。
- 使用自定义 `_FloatingNavBar`：底栏在视觉上保持悬浮胶囊与液态玻璃效果，但在布局上由 Shell 统一预留底部空间，避免正文、FAB 或局部弹层被导航栏覆盖。主 Tab 页面不再依赖零散的 `bottom: 88` 一类魔法数字手工避让；需要脱离壳层视觉叠加的弹层/子页面应优先走 root navigator。
- 避免已弃用 API：如 `RadioListTile` 的 `groupValue/onChanged` 在新版本被 `RadioGroup` 替代，当前采用 `ListTile + Icon(radio_button_*)` 模拟。
- 空状态统一使用引导图标 + 说明文字 + 主操作按钮三段式。

### 7.1 全局计价货币规则

- 顶部货币选择器控制的是**全局计价货币**，不是单页局部状态。
- 资产 / 账户页面应同时保留**原币值**与**计价值**：
  - 原币值：直接来自资产锚定货币与 `market_value`
  - 计价值：运行时按当前全局计价货币换算得到
- 单资产级别的卡片和行仅展示**锚定原币值**，不显示计价值；资产详情页 Hero 区可保留双值展示，但用纵向布局避免横向过长
- 所有统计、占比、排名、趋势、分析图表统一基于**计价值**计算。
- 成本、盈亏、收益率等比较型指标也统一基于**计价值**与**换算后的成本基准**计算，避免原币成本与计价值混算。
- 缺失汇率时：
  - 原币值继续显示
  - 计价值显示 `—` 或明确提示缺汇率
  - 该资产不计入当前统计，并在对应模块显示缺失汇率提示

## 8. 安全与敏感展示

- 卡号、CVV 在任何列表 / 详情页均以 `•••• 后四位` 形式展示，永不渲染明文。
- 备份 / 恢复入口仅在仪表盘与资金页 AppBar 暴露，创建流程走独立全屏路由。

## 9. 演进记录

- **v1**：5 个平级 Tab（账户 / 资产 / 卡片 / 转账 / 事件）。
- **v2**：合并账户 + 资产为「持有」，新增仪表盘 → 4 Tab（仪表盘 / 持有 / 卡片 / 转账 / 事件，共 5 项）。
- **v3**：账户 / 资产 / 转账合并为「资金」二级 Tab，汇率提升为主 Tab。底部顺序：仪表盘 / 资金 / 事件 / 汇率 / 卡片。
- **v4**：`/holdings?tab=` 深度链接、跨实体相互点击跳转、全局搜索（AppBar 搜索按钮）、多跳路径规划（Dijkstra）。
- **v4**：
  - 引入 `GlobalSearchDelegate` + `topSearchOpenerProvider`，所有主页 AppBar 统一搜索入口，结果分「跨模块命中 / 当前模块过滤」两段。
  - 补齐跨实体导航：卡片详情 → 账户；账户详情 → 卡片弹层；事件 card/channel 正确跳转；仪表盘 Stat/缺失汇率卡全部可点。
  - `/holdings` 支持 `?tab=` 预选二级 Tab，便于深度链接。
- **v5（当前）**：专业级数据可视化升级，已落地详见 §10。
- **v6**：底部导航改为实色胶囊、去 `extendBody`（解决页面半透明叠层导致的虚化/模糊问题）。
- **v7**：主 Tab 底部导航升级为悬浮式液态玻璃胶囊；Shell 使用 `Stack + Positioned` 叠加导航层，模糊严格限制在胶囊内部，外部内容保持可见且可交互。

---

## 10. v5 — 专业级数据可视化重构方案

### 10.0 设计总纲

**目标**：将扁平 MVP 升级为高信息密度、具备深度业务洞察的专业理财管理工具 UI。

**技术选型**

- 图表库：`fl_chart`（折线 / 柱状 / 饼图 / 雷达图，纯 Flutter 渲染，无 WebView 开销）
- 拓扑图：`graphview`（力导向 / 树形布局）+ `GwpNodeMap`（CustomPainter 全球地图）
- 动画：Material 3 `AnimatedSwitcher` / `Hero` / `ImplicitlyAnimatedWidget` 系列
- 数据层：所有聚合指标通过新增 `Provider` 组合已有 Repository 数据，**不新增 Drift 表**；历史趋势依赖已有 `ExchangeRate.asOfTime` + `AssetPriceHistory.triggerTime` 时间序列

**信息密度原则**

- 首屏（仪表盘）在不滚动的情况下展示 ≥ 8 个独立数据维度
- 所有数字使用 `GwpTypo.monoFont` + `GwpTypo.tabularFigures` 保证对齐
- 涨跌色统一 `GwpColors.positive` / `GwpColors.negative`
- 所有卡片支持点击下钻到对应详情页

---

### 10.1 维度一：核心 KPI 数据看板（仪表盘重构）

#### 10.1.1 页面区块划分（自上而下）

```
┌─────────────────────────────────────────────┐
│ AppBar: 仪表盘 | 基准货币选择器 | 🔍 搜索    │
├─────────────────────────────────────────────┤
│ A. 净资产英雄卡片 (Hero Net Worth Card)      │
│    ┌───────────────────────────────────────┐ │
│    │ ¥ 1,234,567.89          CNY ▼        │ │
│    │ ▲ +12.34% (+¥152,345)  过去30天      │ │
│    │ [微型面积图 — 30天净资产走势]          │ │
│    └───────────────────────────────────────┘ │
├─────────────────────────────────────────────┤
│ B. KPI 指标网格 (2×3 Grid)                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │ 账户总数  │ │ 资产总数  │ │ 活跃通道  │    │
│  │    12    │ │    47    │ │    5     │    │
│  │ 3 地区   │ │ 8 币种   │ │ 3 协议   │    │
│  └──────────┘ └──────────┘ └──────────┘    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │ 信用额度  │ │ 待处理事件│ │ 缺失汇率  │    │
│  │ ¥50,000  │ │   3 条   │ │  2 对    │    │
│  │ 已用 62% │ │ 1 CRIT   │ │ 影响3资产 │    │
│  └──────────┘ └──────────┘ └──────────┘    │
├─────────────────────────────────────────────┤
│ C. 资产配置概览 (横向滑动卡片组)              │
│  [按币种饼图] [按类型饼图] [按地区饼图]       │
├─────────────────────────────────────────────┤
│ D. 全球账户节点地图 (Global Node Map)        │
│  → 详见 §10.4.1                             │
├─────────────────────────────────────────────┤
│ E. 趋势快照 (Recent Trends)                  │
│  [30天净资产折线] [汇率变动热力条]            │
├─────────────────────────────────────────────┤
│ F. 快捷操作 + 最近事件                       │
└─────────────────────────────────────────────┘
```

#### 10.1.2 KPI 指标计算逻辑

**KPI 数据源** — 全部从已有 Provider 派生，新增 `dashboardKpiProvider`：

```dart
// 新增 Provider：lib/features/dashboard/presentation/dashboard_providers.dart
@riverpod
Future<DashboardKpi> dashboardKpi(Ref ref) async {
  final accounts = await ref.watch(accountListProvider.future);
  final assets = await ref.watch(assetListProvider.future);
  final channels = await ref.watch(channelListProvider.future);
  final cards = await ref.watch(cardListProvider.future);
  final events = await ref.watch(pendingAckEventsProvider.future);
  final summary = await ref.watch(dashboardSummaryProvider.future);
  // ... 聚合计算
}
```

各 KPI 提取逻辑：

- **净资产总额** = `DashboardSummary.total`（已有）
- **净资产变动率** = 需对比 30 天前快照 → 从 `asset_price_history` 按日聚合历史 marketValue 求和（缺项按最近一条 carry-forward）
- **账户总数** = `accounts.length`，按 `sovereigntyRegion` 分组计地区数
- **资产总数** = `assets.length`，按 `currency` 去重计币种数
- **活跃通道** = `channels.where(c => c.status == enabled).length`，按 `transferProtocol` 去重计协议数
- **信用额度汇总** = `cards.where(c => c.cardType == credit).map(c => c.creditLimit).sum`，已用比例 = `1 - availableCredit.sum / creditLimit.sum`
- **待处理事件** = `events.where(e => e.ackStatus == pending).length`，按 `priority` 高亮 CRITICAL 数量
- **缺失汇率** = `DashboardSummary.missingAssetIds.length`

#### 10.1.3 英雄卡片交互

- 点击货币标签 → 弹出 `ModalBottomSheet` 币种选择器，切换后整页刷新
- 点击变动率区域 → 下钻到趋势详情（§10.2 折线图全屏模式）
- 微型面积图使用 `fl_chart` 的 `LineChart`，高度 48px，无坐标轴，仅填充渐变

#### 10.1.4 KPI 网格交互

每个格子为 `InkWell` + `Card`：

- 「账户总数」→ `/holdings?tab=0`
- 「资产总数」→ `/holdings?tab=1`
- 「活跃通道」→ `/channels`
- 「信用额度」→ `/cards`（筛选信用卡）
- 「待处理事件」→ `/events`（筛选 pending）
- 「缺失汇率」→ `/rates`

---

### 10.2 维度二：数据图表体系

#### 10.2.1 图表类型矩阵

| 图表类型 | 应用场景 | 页面位置 | fl_chart Widget | 数据源 |
|---|---|---|---|---|
| 面积折线图 | 净资产历史趋势 | 仪表盘 §C / 资产详情 | `LineChart` + gradient fill | `asset_price_history` 按日聚合 |
| K线/折线图 | 单资产价格走势 | `asset_detail_page` | `LineChart` (已有 `_PriceChart` 升级) | 行情源（Yahoo / 东方财富 / OKX / 基金净值，按资产类型路由） |
| 水平柱状图 | 资产 Top10 排名 | 仪表盘 §E / 账户详情 | `BarChart` horizontal | `Asset.marketValue` 降序取前 10 |
| 堆叠柱状图 | 各账户资产构成对比 | 资金页 · 新增「分析」Tab | `BarChart` stacked | 按 `Account` 分组的 `Asset.marketValue` |
| 饼图/环形图 | 资产配置占比 | 仪表盘 §C / 账户详情 | `PieChart` donut | `Asset` 按 currency / assetType / region 分组 |
| 雷达图 | 多维度健康评分 | 仪表盘（高级面板） | `RadarChart` | 自定义评分模型（见下） |
| 迷你折线图 | 行内趋势指示 | 资产列表行 / 汇率列表行 | `LineChart` mini (已有 `RateSparkline` 升级) | `ExchangeRate` 近 7 日序列 |
| 热力条 | 汇率波动概览 | 汇率主页 | `CustomPainter` | 每对汇率的日变动率映射色阶 |
| 进度环 | 信用卡额度使用 | 卡片详情 / 仪表盘 KPI | `PieChart` single-arc | `availableCredit / creditLimit` |

#### 10.2.2 雷达图 — 财务健康评分模型

五维度评分（0-100），雷达图直观呈现用户全球资产组合的「健康度」：

```
维度1: 分散度 (Diversification)
  = 1 - HHI(各币种marketValue占比)
  HHI = Σ(share_i²)，HHI越低越分散

维度2: 流动性 (Liquidity)
  = (现金类资产 market_value) / total_market_value
  现金类 = assetType in {fxAsset, cd}

维度3: 通道覆盖 (Channel Coverage)
  = 有通道关联的账户数 / 总账户数

维度4: 数据时效 (Data Freshness)
  = 过去24h内有估值更新的资产占比

维度5: 风险集中度 (Concentration Risk)
  = 1 - (最大单一资产 / total)
```

组件：`HealthRadarChart`，放置于资金页「分析」Tab 底部（非仪表盘）。

#### 10.2.3 资产配置三视图（横滑卡片组）

仪表盘 §C 区域，`PageView` 横向滑动，每页一个环形饼图：

**视图 1：按币种**
- 数据 = `assets.groupBy(a => a.currency).mapValues(g => g.sumOf(marketValue))`
- 饼图扇区颜色 = 预定义货币色表（USD=#4CAF50, CNY=#F44336, EUR=#2196F3, JPY=#FF9800, 其他=#9E9E9E）
- 中心文字 = 币种数量 + "种货币"

**视图 2：按资产类型**
- 数据 = `assets.groupBy(a => a.assetType).mapValues(g => g.sumOf(marketValue))`
- 扇区颜色 = `AssetType` 预定义色表
- 中心文字 = "资产配置"

**视图 3：按地区**
- 数据 = 通过 `asset.accountId → account.sovereigntyRegion` 关联
- 扇区颜色 = 地区国旗色系
- 中心文字 = 地区数量 + "个地区"

交互：点击扇区 → 弹出该分组下的资产列表 BottomSheet，每条可点击跳 `/assets/:id`。

#### 10.2.4 净资产趋势折线图（全功能版）

替换现有仪表盘的简单数字展示：

```
┌─────────────────────────────────────────┐
│ 净资产趋势                    7D 1M 3M 1Y │
│                                         │
│  ¥1.3M ┤                        ╱──     │
│        │                    ╱──╱        │
│  ¥1.2M ┤               ╱──╱            │
│        │          ╱────╱                │
│  ¥1.1M ┤    ╱────╱                      │
│        │───╱                            │
│  ¥1.0M ┤                                │
│        └──┬──┬──┬──┬──┬──┬──┬──┬──     │
│          03/22    03/29    04/05         │
│                                         │
│  触摸十字线: 04/15  ¥1,267,890  +5.2%    │
└─────────────────────────────────────────┘
```

- 顶部 `ChoiceChip` 切换时间窗口：7D / 1M / 3M / 1Y / ALL
- 触摸交互：`LineTouchData` 显示十字线 + tooltip 气泡
- 数据来源：从 `asset_price_history` 按日聚合（逐资产 carry-forward 最近价格后求和），对应 `netWorthTrendProvider`
- 参考线：虚线标记期初值，便于直观判断涨跌

---

### 10.3 维度三：多层级数据下钻与折叠展示

#### 10.3.1 下钻路径设计

```
仪表盘 (L0 全局总览)
  │
  ├─→ 按地区下钻 (L1)
  │     点击全球地图节点 或 饼图扇区
  │     → 展开该地区所有账户列表
  │       │
  │       └─→ 账户详情 (L2)
  │             含该账户下所有资产 + 通道 + 卡片
  │             │
  │             └─→ 资产详情 (L3)
  │                   含价格图表 + 持仓分析 + 估值历史
  │
  ├─→ 按币种下钻 (L1)
  │     点击饼图扇区
  │     → BottomSheet 列出该币种所有资产
  │       └─→ 资产详情 (L3)
  │
  ├─→ 按资产类型下钻 (L1)
  │     点击饼图扇区
  │     → BottomSheet 列出该类型所有资产
  │       └─→ 资产详情 (L3)
  │
  └─→ 通道拓扑下钻 (L1)
        点击全球地图通道线
        → 通道详情 (L2)
          含成员账户 + 规则 + 费率
```

#### 10.3.2 账户详情页 — 折叠展开增强

现有 `account_detail_page.dart` 的各 Section 升级为可折叠 `ExpansionTile`：

```
┌─ 账户头部（始终展开）────────────────────┐
│  招商银行 · BANK · CN · ACTIVE          │
│  净资产: ¥456,789.00                    │
├─ ▼ 资产持仓 (12) ────────────────────────┤
│  [堆叠柱状图: 按 assetType 分布]         │
│  ┌─ AAPL · STOCK ─────── ¥123,456 ──┐  │
│  │  100 股 @ $182.50  +12.3%        │  │
│  │  [迷你折线: 7日走势]              │  │
│  └───────────────────────────────────┘  │
│  ┌─ BTC · CRYPTO ──────── ¥89,012 ──┐  │
│  │  0.5 BTC @ $67,890  -2.1%        │  │
│  └───────────────────────────────────┘  │
│  ... (折叠时只显示前 3 条 + "展开更多")   │
├─ ▶ 支持的转账通道 (3) ──────────────────┤  ← 折叠态
├─ ▶ 关联卡片 (2) ────────────────────────┤  ← 折叠态
├─ ▼ 资产配置分析 ─────────────────────────┤  ← 新增区块
│  [环形饼图: 该账户内 assetType 占比]      │
│  [横向柱状图: 该账户 Top5 资产]           │
├─ ▶ 基本信息 ─────────────────────────────┤  ← 折叠态
└──────────────────────────────────────────┘
```

#### 10.3.3 资金页 — 「分析」Tab（已完成）

`/holdings` 的第四个 Tab，由 `PortfolioAnalysisBody` 实现：

```
[账户] [资产] [转账] [分析]
```

**分析 Tab 内容**（`PortfolioAnalysisBody`）：

```
┌─────────────────────────────────────────┐
│ 1. 净资产历史趋势（折线图，同仪表盘但全宽）│
├─────────────────────────────────────────┤
│ 2. 资产 Top10 排名（水平柱状图）          │
│    AAPL ████████████████ ¥123,456       │
│    BTC  ██████████████ ¥89,012          │
│    ...                                   │
├─────────────────────────────────────────┤
│ 3. 账户间资产对比（堆叠柱状图）            │
│    招商银行 [股票|基金|现金]               │
│    Schwab  [股票|ETF|现金]                │
│    ...                                   │
├─────────────────────────────────────────┤
│ 4. 币种暴露热力矩阵                      │
│    账户 \ 币种   CNY    USD    EUR       │
│    招商银行     ████   ░░░░   ····       │
│    Schwab      ░░░░   ████   ░░░░       │
├─────────────────────────────────────────┤
│ 5. 健康雷达图                            │
└─────────────────────────────────────────┘
```

#### 10.3.4 汇率页 — 信息密度增强

```
┌─────────────────────────────────────────┐
│ AppBar: 汇率 | 管理币对 | 拉取最新        │
├─ 汇率波动热力条 ─────────────────────────┤
│ USD/CNY ▓▓▓▓░░  +0.12%                  │
│ EUR/CNY ▓▓▓░░░  -0.08%                  │
│ GBP/CNY ▓░░░░░  -0.31%  ← 颜色深浅=波幅 │
├─ 按对列表（增强版）──────────────────────┤
│ ┌──────────────────────────────────────┐ │
│ │ USD/CNY   7.2456  ▲+0.12%           │ │
│ │ [7日迷你折线图]  H:7.28 L:7.21      │ │
│ └──────────────────────────────────────┘ │
│ ┌──────────────────────────────────────┐ │
│ │ EUR/CNY   7.8901  ▼-0.08%           │ │
│ │ [7日迷你折线图]  H:7.93 L:7.85      │ │
│ └──────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

每行展示：币对名 + 最新 rate + 日变动率 + 7日 `RateSparkline`（已有组件升级） + 7日 High/Low。

---

### 10.4 维度四：拓扑关系图与全景视图

#### 10.4.1 仪表盘 — 全球账户节点地图

**定位**：在仪表盘中以世界地图为底图，用节点标记用户全球账户的地理分布，直观呈现「全球资产版图」。

**布局位置**：仪表盘 §D 区块，高度 220px，占满宽度。

```
┌─────────────────────────────────────────┐
│            全球资产分布                    │
│                                          │
│     ●London        ●Beijing              │
│      £12K    ──── ¥456K                  │
│              ╱                            │
│     ●NewYork╱                             │
│      $234K                                │
│                    ●Singapore             │
│                     S$89K                 │
│                                          │
│  ● = 账户节点  ── = 通道连线              │
│  节点大小 ∝ 该地区资产总值                 │
└─────────────────────────────────────────┘
```

**实现方案**：

```
Widget: GlobalNodeMap extends StatelessWidget
├── CustomPainter (底图)
│   └── 简化世界地图轮廓（SVG path 或预置 PNG）
│       → 仅绘制大陆轮廓线，低饱和度，不喧宾夺主
├── Positioned 节点层
│   └── 每个 sovereignty_region 映射到地图坐标
│       → 预定义坐标表: {CN: (0.78, 0.35), US: (0.18, 0.38), SG: (0.73, 0.58), ...}
│       节点 Widget = Column
│         ├── CircleAvatar(radius ∝ log(regionTotal), 内显国旗emoji或地区码)
│         └── Text(格式化金额, mono字体)
├── CustomPainter (连线层)
│   └── 遍历所有 Channel 的成员账户对
│       → 若两个账户在不同 region，画贝塞尔曲线连接
│       → 线条颜色: enabled=GwpColors.actionPrimary, disabled=GwpColors.muted
│       → 线条粗细 ∝ 通道数量
└── GestureDetector
    ├── 点击节点 → 展开该地区账户列表 BottomSheet
    └── 点击连线 → 展示该通道信息 Tooltip
```

**数据聚合**：

```dart
// 按地区聚合
Map<String, RegionSummary> regionMap = {};
for (final account in accounts) {
  regionMap.putIfAbsent(account.sovereigntyRegion, () => RegionSummary());
  regionMap[account.sovereigntyRegion]!.accounts.add(account);
  regionMap[account.sovereigntyRegion]!.totalValue += accountValues[account.id];
}

// 通道连线：提取跨地区通道
List<ChannelEdge> crossRegionEdges = [];
for (final channel in enabledChannels) {
  final members = accountChannels.where(ac => ac.channelId == channel.id);
  final regions = members.map(m => accountMap[m.accountId]!.sovereigntyRegion).toSet();
  if (regions.length > 1) {
    crossRegionEdges.add(ChannelEdge(regions: regions, channel: channel));
  }
}
```

#### 10.4.2 转账页 — 通道拓扑图

**定位**：将现有转账模拟页的下拉选择框模式升级为可视化拓扑图模式，直观呈现所有账户与通道的连接关系。

**布局**：转账 Tab 顶部新增拓扑视图（可收起），高度 280px：

```
┌─────────────────────────────────────────┐
│  通道拓扑图                    [收起 ▲]  │
│                                          │
│  ┌──────┐   SWIFT    ┌──────┐           │
│  │招商CN │◄──────────►│UBS SG│           │
│  │ BANK  │            │BROKER│           │
│  └──┬────┘            └──┬───┘           │
│     │ CNAPS               │ FPS          │
│     │                     │              │
│  ┌──┴────┐            ┌──┴───┐           │
│  │工商CN │             │HSBC  │           │
│  │ BANK  │◄──SEPA────►│HK    │           │
│  └───────┘            └──────┘           │
│                                          │
│  ● 选中源    ◆ 选中目标                   │
│  ── 可用通道  ╌╌ 违规通道（红色虚线）      │
│  粗线 = 推荐路径                          │
└─────────────────────────────────────────┘
```

**实现方案**：

```
Widget: ChannelTopologyView extends ConsumerStatefulWidget
├── InteractiveViewer (支持缩放平移)
│   └── GraphView (package:graphview)
│       layout: FruchtermanReingoldAlgorithm (力导向布局)
│       nodes: 每个 Account 一个节点
│         └── _AccountNode Widget
│             ├── CircleAvatar(institutionName首字母)
│             ├── Text(institutionName, 截断)
│             ├── Text(accountType + region)
│             └── 选中态: 描边高亮 + 放大动画
│       edges: 每个 Channel 对应的账户对之间连线
│         └── _ChannelEdgePainter
│             ├── 颜色: enabled → 主题色, disabled → 灰色, violated → 红色虚线
│             ├── 标签: 通道名 + 费率
│             └── 粗细: 选中路径 3px, 其余 1px
├── GestureDetector
│   ├── 点击节点 → 设为源/目标账户 (交替选择)
│   └── 长按节点 → 跳转 /accounts/:id
└── AnimatedPath (路径动画)
    └── 路径规划结果高亮: 从源到目标逐段点亮，流光动画
```

**与路径规划联动**：

1. 用户在拓扑图上点选源节点（蓝色高亮）和目标节点（绿色高亮）
2. 自动填充下方的源/目标 Dropdown
3. 输入金额后，调用 `PlanTransferRouteUseCase`
4. 结果路径在拓扑图上以粗线 + 流光动画高亮
5. 违规边以红色虚线 + ⚠️ 标记

#### 10.4.3 全局关系全景图（新增独立页面）

**路由**: `/topology`（从仪表盘快捷入口或全球地图「查看全景」按钮进入）

**定位**：完整的实体关系全景图，展示 Account / Asset / Channel / Card 四类实体及其关联。

```
┌─────────────────────────────────────────┐
│  AppBar: 全景关系图 | 筛选 | 布局切换     │
├─────────────────────────────────────────┤
│  FilterChip 行:                          │
│  [账户] [资产] [通道] [卡片] [仅活跃]     │
├─────────────────────────────────────────┤
│  InteractiveViewer                       │
│  ┌─────────────────────────────────────┐ │
│  │     ┌─Channel─┐                     │ │
│  │     │ SWIFT   │                     │ │
│  │     └──┬──┬───┘                     │ │
│  │        │  │                          │ │
│  │  ┌─Acc─┤  ├─Acc──┐                  │ │
│  │  │招商 │  │ UBS  │                  │ │
│  │  │     │  │      │                  │ │
│  │  ├─────┤  ├──────┤                  │ │
│  │  │$AAPL│  │ BTC  │  ← 资产子节点    │ │
│  │  │$MSFT│  │ ETH  │                  │ │
│  │  ├─────┤  └──────┘                  │ │
│  │  │VISA │          ← 卡片子节点       │ │
│  │  └─────┘                             │ │
│  └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│  底部信息条:                              │
│  12 账户 · 47 资产 · 5 通道 · 8 卡片     │
└─────────────────────────────────────────┘
```

节点类型与视觉编码：

- **Account 节点**: 圆形，大号，颜色按 `sovereigntyRegion` 编码，内显机构首字母
- **Asset 节点**: 小方形，依附于父 Account 节点，颜色按 `assetType` 编码
- **Channel 节点**: 菱形，居中连接相关 Account，颜色按 `status` 编码
- **Card 节点**: 圆角矩形，依附于父 Account 节点，颜色按 `cardOrganization` 编码

布局切换：

- **力导向** (`FruchtermanReingold`): 自动排列，适合发现聚类关系
- **分层树形** (`BuchheimWalkerAlgorithm`): Account 为中间层，Channel 在上，Asset/Card 在下
- **按地区分组**: 相同 region 的 Account 聚拢，跨地区 Channel 画长弧线

---

### 10.5 组件选型总结

#### 10.5.1 新增共享组件（`lib/core/ui/`）

| 组件名 | 用途 | 关键属性 |
|---|---|---|
| `GwpMiniChart` | 行内迷你折线/面积图 | `data: List<double>`, `width`, `height`, `color`, `showArea` |
| `GwpDonutChart` | 环形饼图（带中心标签） | `segments: List<ChartSegment>`, `centerLabel`, `onSegmentTap` |
| `GwpBarRank` | 水平排名柱状图 | `items: List<RankItem>`, `maxBars`, `onTap` |
| `GwpRadarChart` | 多维度雷达图 | `dimensions: List<RadarDimension>`, `values: List<double>` |
| `GwpHeatStrip` | 单行热力条 | `value: double`, `range: (min, max)`, `label` |
| `GwpNodeMap` | 全球节点地图 | `nodes: List<MapNode>`, `edges: List<MapEdge>`, `onNodeTap`, `onEdgeTap` |
| `GwpTopologyGraph` | 通道拓扑图（力导向） | （实际实现为 `ChannelTopologyView`） |
| `GwpKpiTile` | KPI 指标格 | `title`, `value`, `subtitle`, `icon`, `onTap`, `trend` |
| `GwpProgressRing` | 进度环（信用额度等） | （暂未实现，由 `GwpDonutChart` 单弧模式替代） |
| `GwpCollapsibleSection` | 可折叠分区 | （暂未实现，账户详情页使用自定义 SectionCard） |

#### 10.5.2 依赖包新增

```yaml
# pubspec.yaml 新增
dependencies:
  fl_chart: ^0.70.0       # 折线/柱状/饼图/雷达图
  graphview: ^1.2.1        # 力导向/树形拓扑图布局
```

无新增外部网络请求、无新增 Drift 表，符合 AGENTS.md §1 本地优先约束。

---

### 10.6 实施路线（分阶段）

**Phase 1 — 仪表盘 KPI 看板 + 基础图表** ✅ 已落地
- `dashboardKpiProvider` 聚合逻辑
- `GwpKpiTile` 组件 + 2×3 网格
- 英雄卡片带微型面积图
- 资产配置三视图（饼图 × 3）

**Phase 2 — 全球节点地图 + 趋势图表** ✅ 已落地
- `GwpNodeMap` 全球地图组件
- 净资产折线图（全功能版带触摸交互）
- 汇率热力条 + 增强型汇率列表行
- 资产详情页 `_PriceChart` 升级

**Phase 3 — 通道拓扑图 + 分析 Tab** ✅ 已落地
- `ChannelTopologyView` 力导向布局组件
- 转账页拓扑视图 + 路径规划联动
- 资金页「分析」Tab（Top10 / 健康雷达图）
- `PortfolioAnalysisBody`（堆叠柱状 / 热力矩阵待补）

**Phase 4 — 全景关系图 + 下钻完善** ⚠ 部分落地
- `/topology` 全景页面 ✅
- 全局搜索 + 深层导航 ✅
- 账户详情页成本与收益区块 ✅
- 详情页折叠展开改造 ⬜ 留待后续
- 全局交互打磨与动画 ⬜ 留待后续
