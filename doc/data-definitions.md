# GWP 数据定义

## 1. 说明

本文件用于沉淀 GWP 核心实体的数据结构定义，面向开发实现与接口对齐。

- 账户类型范围：BANK / BROKER / INSURANCE / PAYMENT / CUSTODY / CRYPTO_EXCHANGE / CRYPTO_WALLET
- 资产类型范围：STOCK / EQUITY / FUND / BOND / CD / OPTION / FUTURE / WARRANT / POLICY / CRYPTO / PERPETUAL / CONTRACT / PRECIOUS_METAL / FX_ASSET
- 卡类型范围：DEBIT / CREDIT / PREPAID
- 字典锚定：`currency` / `sovereignty_region` / `transfer_protocol` 相关业务字段在 UI 与 UseCase 层都必须锚定到 `dict_entries`，禁止自由字符串落库；可空字段以 `null` 表达“沿用默认值”

## 2. Account

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID / BIGINT | 是 | 主键 |
| account_no | VARCHAR(64) | 否 | 机构侧账户编号 |
| account_type | ENUM | 是 | BANK / BROKER / INSURANCE / PAYMENT / CUSTODY / CRYPTO_EXCHANGE / CRYPTO_WALLET |
| sovereignty_region | VARCHAR(16) | 是 | 主权地区编码（如 CN、US、SG、EU） |
| institution_name | VARCHAR(128) | 是 | 开户机构 |
| status | ENUM | 是 | ACTIVE / INACTIVE / DORMANT / CLOSED |
| opened_at | DATETIME | 否 | 开户时间 |
| fx_spread_percent | REAL | 是 | 账户内部换汇百分比损耗（0–100，默认 0）。0 表示该账户不支持内部货币兑换；例如 0.3 表示每次换汇损失 0.3% |
| ext_info | JSON | 否 | 扩展信息 |
| created_at | DATETIME | 是 | 创建时间 |
| updated_at | DATETIME | 是 | 更新时间 |
| is_deleted | TINYINT(1) | 是 | 软删除标记 |

## 3. Asset

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID / BIGINT | 是 | 主键 |
| account_id | UUID / BIGINT | 是 | 外键，关联 Account.id |
| asset_type | ENUM | 是 | STOCK / EQUITY / FUND / BOND / CD / OPTION / FUTURE / WARRANT / POLICY / CRYPTO / PERPETUAL / CONTRACT / PRECIOUS_METAL / FX_ASSET |
| asset_code | VARCHAR(64) | 否 | 资产代码 |
| quantity | DECIMAL(28,8) | 是 | 数量 |
| cost_price | DECIMAL(28,10) | 否 | 成本价 |
| current_price | DECIMAL(28,10) | 否 | 当前价 |
| currency | VARCHAR(10) | 是 | 资产计价货币代码；加密资产本身属于 `asset_type=CRYPTO` / `asset_code`，不是货币字典项 |
| market_value | DECIMAL(28,10) | 否 | 原币市值缓存（`quantity × current_price`，币种由 `currency` 指定）；全局计价值在查询/展示层按当前计价货币运行时换算，不单独落库 |
| valuation_time | DATETIME | 否 | 估值时间 |
| status | ENUM | 是 | HOLDING / FROZEN / REDEEMED / CLOSED |
| ext_info | JSON | 否 | 扩展信息 |
| created_at | DATETIME | 是 | 创建时间 |
| updated_at | DATETIME | 是 | 更新时间 |
| is_deleted | TINYINT(1) | 是 | 软删除标记 |

## 4. Channel

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID / BIGINT | 是 | 主键 |
| name | VARCHAR(64) | 是 | 通道名称，如 SWIFT / ACH / 微信支付 / CNAPS 等，面向账户声明支持 |
| transfer_protocol | ENUM / VARCHAR(32) | 是 | 取值同 transfer_protocol 枚举 |
| fee_rate | DECIMAL(10,6) | 否 | 比例费率 |
| fixed_fee | DECIMAL(18,6) | 否 | 固定费 |
| sovereignty_region_rule | JSON / TEXT | 否 | 地区限制规则 |
| limit_currency | VARCHAR(10) | 否 | 限额币种 |
| daily_limit | DECIMAL(28,8) | 否 | 每日限额 |
| single_limit | DECIMAL(28,8) | 否 | 单笔限额 |
| status | ENUM | 是 | ENABLED / DISABLED / MAINTENANCE |
| is_builtin | TINYINT(1) | 是 | 是否内置通道（默认 0）。内置通道不可删除，共 7 条：SWIFT / HK FPS / GB FPS / HK CHATS / CN CNAPS / CN CIPS / US ACH |
| sort_order | INTEGER | 是 | 用户自定义排序（默认 1000） |
| effective_from | DATETIME | 否 | 生效时间 |
| effective_to | DATETIME | 否 | 失效时间 |
| created_at | DATETIME | 是 | 创建时间 |
| updated_at | DATETIME | 是 | 更新时间 |

> Channel 不再绑定源/目账户类型；是否两个账户能通过某通道互转，由 `account_channels` 关联决定。路由规划（多币种 Dijkstra on `(accountId, currency)`）会为同一通道内所有账户对生成双向边，并在每条边上以边特定货币评估规则引擎。

> `transfer_protocol` / `limit_currency` / `sovereignty_region_rule.allowedRegions|blockedRegions` 都必须来自字典选择器；地区列表不再接受逗号分隔自由文本。

> 内置转账协议共 11 个：SWIFT / ACH / FPS / CNAPS / SEPA / CHATS / CIPS / FEDWIRE / CHAPS / ZENGIN / NPP；内置货币共 12 个：CNY / USD / GBP / EUR / HKD / JPY / KRW / TWD / SGD / MYR / CAD / AUD。

## 4a. AccountChannel（账户-通道关联）

账户与通道的多对多关联，一个账户可声明支持多个通道，一个通道也可被多个账户共享。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| account_id | UUID / BIGINT | 是 | 外键，关联 Account.id；复合主键之一 |
| channel_id | UUID / BIGINT | 是 | 外键，关联 Channel.id；复合主键之一 |
| fee_rate_override | DECIMAL(10,6) / TEXT | 否 | 账户级比例费率覆盖；为空 = 沿用 Channel.fee_rate；`0` 合法，表示免比例费 |
| fixed_fee_override | DECIMAL(18,6) / TEXT | 否 | 账户级固定费覆盖；为空 = 沿用 Channel.fixed_fee；`0` 合法，表示免固定费 |
| fee_currency_override | VARCHAR(10) | 否 | 账户级费用币种覆盖；为空 = 沿用 Channel.limit_currency；UI 必须提供明确空态而非预填默认值 |
| region_override | VARCHAR(16) | 否 | 运行时地区覆盖（算法层拼装，不修改账户自身 region）。用于跨地区通道场景，例如 IBKR(US) 通过其 HK 分行接入 CHATS 时需将有效地区设为 HK |
| created_at | DATETIME | 是 | 创建时间 |
| updated_at | DATETIME | 否 | 最近一次修改账户级通道配置的时间 |

复合主键：`(account_id, channel_id)`（无独立 `id` 列）。

外键约束：
- `account_id -> accounts.id`（`ON DELETE CASCADE`）
- `channel_id -> channels.id`（`ON DELETE CASCADE`）

> 注：无独立 `id` 列，复合主键 `(account_id, channel_id)` 同时承担外键角色。

费用语义：
- `AccountChannel` 上的 override 为**完全覆盖**通道默认值，不做叠加；
- 规划转账路径时按**源账户**在该通道上的 override 计费；
- override 为 `0` 视为有效值，不等同于空。

地区语义：
- `region_override` 仅在算法运行时生效（`_effectiveRegion()`），不会写回 `accounts.sovereignty_region`；
- 优先级：`region_override` > 通道 `allowedRegions` 匹配 > 账户自身地区；
- 同一账户在不同通道上可拥有不同的有效地区。

## 5. Card

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID / BIGINT | 是 | 主键 |
| account_id | UUID / BIGINT | 是 | 外键，关联 Account.id |
| card_organization | VARCHAR(32) | 是 | 发卡组织（VISA/MasterCard/银联） |
| card_no_masked | VARCHAR(32) | 是 | 脱敏卡号 |
| card_no_ciphertext | TEXT | 否 | 卡号密文 |
| card_type | ENUM | 是 | DEBIT / CREDIT / PREPAID |
| expire_month | TINYINT | 是 | 有效期月 |
| expire_year | SMALLINT | 是 | 有效期年 |
| cvv_ciphertext | TEXT | 否 | CVV 密文 |
| issuer_name | VARCHAR(128) | 是 | 发卡行 |
| currency | VARCHAR(10) | 否 | 主记账币种（信用额度计价），来自 `currency` 字典 |
| supports_all_currencies | TINYINT(1) | 是 | 是否全币种卡；true 时忽略列表 |
| supported_currencies | VARCHAR(256) | 否 | CSV of `currency` 字典代码，如 "USD,EUR,HKD"。空 = 仅主币种；不再允许手工录入自由 ISO 字符串 |
| credit_limit | DECIMAL(28,8) | 否 | 信用额度（信用卡） |
| available_credit | DECIMAL(28,8) | 否 | 可用额度（信用卡） |
| billing_cycle_day | TINYINT | 否 | 账单日 |
| payment_due_day | TINYINT | 否 | 还款日 |
| billing_address | VARCHAR(256) | 否 | 账单地址 |
| is_virtual | TINYINT(1) | 是 | 是否虚拟卡 |
| status | ENUM | 是 | ACTIVE / LOCKED / EXPIRED / CLOSED |
| sort_order | INTEGER | 是 | 用户自定义排序（默认 1000） |
| created_at | DATETIME | 是 | 创建时间 |
| updated_at | DATETIME | 是 | 更新时间 |

## 6. ExchangeRate

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID / BIGINT | 是 | 主键 |
| pair_key | VARCHAR(32) | 是 | 货币对唯一标识（如 USD/CNY） |
| base_currency | VARCHAR(10) | 是 | 基础币种，来自 `currency` 字典 |
| quote_currency | VARCHAR(10) | 是 | 目标币种，来自 `currency` 字典 |
| rate | DECIMAL(20,10) | 是 | 汇率 |
| as_of_time | DATETIME | 是 | 生效时间 |
| updated_at | DATETIME | 是 | 更新时间 |
| source | VARCHAR(64) | 是 | 数据源 |
| snapshot_type | ENUM | 是 | REALTIME / HOURLY / DAILY |
| raw_payload | JSON / TEXT | 否 | 原始快照 |

## 6a. WatchedPair（关注币对 / 预警阈值）

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| pair_key | VARCHAR(32) | 是 | 主键，形如 `USD/CNY` |
| base_currency | VARCHAR(10) | 是 | 基础币种，来自 `currency` 字典 |
| quote_currency | VARCHAR(10) | 是 | 目标币种，来自 `currency` 字典 |
| created_at | DATETIME | 是 | 加入关注的时间 |
| threshold_high | DECIMAL(28,10) / TEXT | 否 | 上沿阈值；`rate ≥ threshold_high` 触发 high 预警 |
| threshold_low | DECIMAL(28,10) / TEXT | 否 | 下沿阈值；`rate ≤ threshold_low` 触发 low 预警 |
| alert_change_pct | DECIMAL(28,10) / TEXT | 否 | 日环比波动阈值（%，正数）；`|pct| ≥` 触发 change 预警 |
| sort_order | INTEGER | 是 | 用户自定义排序（默认 1000） |

- 阈值字段自 schema v12 起从 `REAL` 迁移到 `TEXT`（`Decimal.toString()`），遵循「金额/数值类永远禁止 double」约束
- 触发判定由 `CheckRateAlertsUseCase` 执行，幂等键 `RATE_ALERT:{pairKey}:{yyyymmdd}:{kind}` 保证同天同类型不重复写入

## 7. Event

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID / BIGINT | 是 | 主键 |
| event_type | VARCHAR(64) | 是 | 事件类型 code；详见 `EventCatalog` |
| related_model | ENUM / VARCHAR(32) | 是 | ACCOUNT / ASSET / CARD / CHANNEL |
| related_id | UUID / BIGINT | 是 | 主关联模型 ID |
| refs | JSON | 否 | 辅助关联，`{role: {model, id}}`；例如转账落地事件保存源/目账户 |
| batch_id | UUID | 否 | 批次 ID，用于将一次同步/导入产生的多个事件聚合折叠 |
| source_key | VARCHAR(128) | 否 | 幂等键，建议形如 `{eventType}:{relatedId}:{yyyymmdd}:{source}`；同键不重复写入 |
| trigger_time | DATETIME | 是 | 触发时间 |
| due_at | DATETIME | 否 | 需用户响应时的截止时间（定存到期、账单还款等） |
| priority | ENUM | 否 | LOW / MEDIUM / HIGH / CRITICAL |
| status | ENUM | 是 | PENDING / TRIGGERED / RESOLVED / CLOSED（系统处理链状态） |
| handling_status | ENUM | 否 | UNHANDLED / PROCESSING / HANDLED / FAILED（系统处理器状态） |
| handler | VARCHAR(64) | 否 | 处理人/处理器 |
| handling_note | TEXT | 否 | 处理说明；约定存 JSON，由 `EventCatalog` 按 event_type 约束 schema |
| ack_requirement | ENUM | 是 | NOT_APPLICABLE（默认） / OPTIONAL / REQUIRED；用户是否需要确认 |
| ack_status | ENUM | 是 | PENDING / CONFIRMED / DISMISSED；用户视角状态 |
| ack_at | DATETIME | 否 | 用户执行确认/忽略的时间 |
| ack_note | TEXT | 否 | 用户确认或忽略时填写的说明 |
| is_deleted | BOOLEAN | 是 | 软删除标记（默认 false） |
| created_at | DATETIME | 是 | 创建时间 |
| updated_at | DATETIME | 是 | 更新时间 |

### 7.1 两套状态的分工

- **`status` + `handling_status`**：系统处理链路视角。由 sync worker / use case 驱动，与用户无关。
- **`ack_requirement` + `ack_status`**：用户视角。表达「是否需要用户看过 / 确认 / 忽略」。与系统状态正交。

合法组合示例：

- 估值失败 `ASSET_VALUATION_FAILED`：`priority=HIGH`、`handling_status=FAILED`、`ack_requirement=OPTIONAL`；出现在事件页「失败」Tab。`source_key` 含 `stage`（`latest`/`history`），同日同阶段只记一条。
- 同步过期 `ASSET_SYNC_OUTDATED`：`priority=MEDIUM`、`handling_status=UNHANDLED`、`ack_requirement=OPTIONAL`；每日聚合一条，`handling_note` 存超期资产列表；`source_key` 形如 `ASSET_SYNC_OUTDATED:<yyyymmdd>`。
- 跨境到账 `TRANSFER_LANDED`：`handling_status=HANDLED`、`ack_requirement=REQUIRED`、`ack_status=PENDING`，需用户对账后置 `CONFIRMED`。
- 跨境到账 `TRANSFER_LANDED`：`handling_status=HANDLED`、`ack_requirement=REQUIRED`、`ack_status=PENDING`，需用户对账后置 `CONFIRMED`。
- 账单到期 `CARD_BILL_DUE`：带 `due_at`；`ack_requirement=REQUIRED`，用户「忽略」置 `DISMISSED`。

### 7.2 `status` FSM 允许转移

```
PENDING  → TRIGGERED → RESOLVED → CLOSED
       ↘              ↗
         (可直接 CLOSED 作为取消)
```
不允许回退（例如 `RESOLVED → TRIGGERED`）；由 use case 层强校验，entity 层不约束。

### 7.3 `ack_status` FSM

```
PENDING → CONFIRMED
       ↘ DISMISSED
```
用户一旦确认或忽略即终态；如需再次操作应复核事件业务本身，而非修改 ack。

### 7.4 幂等与批次

- 写入事件前应先检查 `source_key`，存在则更新 `updated_at` 并跳过（不重复写）。
- `batch_id` 由触发方（例如 `RefreshAssetPriceUseCase.refreshHistory`）生成一次并赋给本批所有事件/快照，用于 UI 折叠为"今日刷新 N 项资产估值"一张聚合卡。

### 7.5 事件表的定位（与 `asset_price_history` 的分工）

**事件表只收操作型条目**：失败、需确认、到期提醒等用户/运维必须感知的项。
成功类高频写入（每日百条级）走独立的审计日志表，避免淹没真正重要的告警。

目前这种分工的典型代表是资产估值：

- 成功估值 → 写 `asset_price_history`（见 §8），事件表不再出现 `ASSET_VALUATED`
- 估值失败 → 写事件 `ASSET_VALUATION_FAILED`（HIGH）
- 超过阈值未同步 → 每日聚合一条 `ASSET_SYNC_OUTDATED`（MEDIUM）

## 8. AssetPriceHistory

资产估值快照/审计日志。与事件表独立，专门承接**成功**的估值写入；
UI 的资产价格走势图、Dashboard 净资产趋势均从此表读取。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID | 是 | 主键 |
| asset_id | UUID | 是 | 外键，`Asset.id` |
| price | DECIMAL / TEXT | 是 | 该时刻单价（asset.currency 下） |
| market_value | DECIMAL / TEXT | 否 | 持仓市值 = quantity × price |
| currency | VARCHAR(3) | 是 | ISO-4217；冗余一份便于查询 |
| source | VARCHAR(32) | 是 | `manual` / `yahoo` / `eastmoney` / `okx` / `fund-yahoo` / `fixed_income` … |
| batch_id | UUID | 否 | 同 §7 `batch_id` 语义，用于聚合 |
| trigger_time | DATETIME | 是 | 估值时间 |
| source_key | VARCHAR(128) | 否 | 幂等键，形如 `{assetId}:{yyyymmdd}:{source}`；UNIQUE |
| raw_payload | JSON / TEXT | 否 | 原始输入快照（便于回查） |
| created_at | DATETIME | 是 | 写入时间 |

索引：`(asset_id, trigger_time)`、`(trigger_time)`、UNIQUE(`source_key`)。

写入方：`ValuateAssetUseCase` / `RefreshAssetPriceUseCase.refreshHistory`。
读取方：`assetValuationHistoryProvider`（图表）、`netWorthTrendProvider`（Dashboard）。

## 9. AssetCostHistory

资产成本/持仓数量调整的审计日志。与 §8 价格历史解耦：价格历史记录**市场价格**的变化（自动估值写入），成本历史记录**用户主动修改**的成本价或持仓数量（手动编辑写入）。

不进事件表：成本调整属于常规录入操作，不是操作型告警。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID | 是 | 主键 |
| asset_id | UUID | 是 | 外键，`Asset.id` |
| cost_price | DECIMAL / TEXT | 否 | 该时刻的单位成本价（asset.currency 下）；可空（仅调整数量时） |
| quantity | DECIMAL / TEXT | 是 | 该时刻的持仓数量 |
| currency | VARCHAR(3) | 是 | ISO-4217 |
| source | VARCHAR(32) | 是 | `manual`（目前只有手动写入一种） |
| reason | VARCHAR(128) | 否 | 调整原因（预留，暂未使用） |
| trigger_time | DATETIME | 是 | 调整发生时间 |
| source_key | VARCHAR(128) | 否 | 幂等键，形如 `{assetId}:{isoTimestamp}`；UNIQUE |
| created_at | DATETIME | 是 | 写入时间 |

索引：主键 + UNIQUE(`source_key`)。

写入方：`asset_create_page` 编辑流程自动追加（当 `costPrice` 或 `quantity` 发生变更时）。
读取方：`assetCostHistoryProvider`（Stream，按 asset 维度 `trigger_time DESC`）。

## 10. DictEntry

通用字典表，承载「转账协议 / 主权地区 / 货币」三个业务字典。三者读写同构（列表 / 新增 / 改名），合并到一张表减少模板代码。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | INTEGER | 是 | 自增主键 |
| type | VARCHAR(32) | 是 | 字典类型：`TRANSFER_PROTOCOL` / `SOVEREIGNTY_REGION` / `CURRENCY` |
| code | VARCHAR(32) | 是 | 业务代码，统一大写（如 SWIFT / CN / USD） |
| name | VARCHAR(128) | 是 | 本地化展示名 |
| name_en | VARCHAR(128) | 否 | 英文名 |
| sort_order | INTEGER | 是 | 排序（默认 1000） |
| is_builtin | TINYINT(1) | 是 | 是否内置项（内置项禁止删除，仅允许改名） |
| flag_emoji | VARCHAR(8) | 否 | 国旗 emoji（仅 SOVEREIGNTY_REGION 使用） |
| continent | VARCHAR(32) | 否 | 大洲分组标签（仅 SOVEREIGNTY_REGION 使用） |
| color_hex | VARCHAR(16) | 否 | 强调色 hex（仅 SOVEREIGNTY_REGION 使用） |
| map_lon | REAL | 否 | 地理经度（仅 SOVEREIGNTY_REGION 使用） |
| map_lat | REAL | 否 | 地理纬度（仅 SOVEREIGNTY_REGION 使用） |
| anchor_lon | REAL | 否 | 地图锚点经度（仅 SOVEREIGNTY_REGION 使用） |
| anchor_lat | REAL | 否 | 地图锚点纬度（仅 SOVEREIGNTY_REGION 使用） |
| parent_region | VARCHAR(32) | 否 | 上级区域 code（如 DE 的 parent_region = 'EU'） |
| created_at | DATETIME | 是 | 创建时间 |
| updated_at | DATETIME | 是 | 更新时间 |

唯一索引：`(type, code)`。

约束：
- `is_builtin = true` 的条目不可删除，`code` 不可变；用户可改名
- 写入前 `code` 统一 `toUpperCase()`
- 查询始终带 `type = ?` 过滤

当前内置条目：转账协议 11 个（SWIFT / ACH / FPS / CNAPS / SEPA / CHATS / CIPS / FEDWIRE / CHAPS / ZENGIN / NPP）、主权地区 16 个（HK / CN / US / SG / GB / DE / FR / IT / JP / KR / TW / MY / CA / AU / EU / CRYPTO）、货币 12 个（CNY / USD / GBP / EUR / HKD / JPY / KRW / TWD / SGD / MYR / CAD / AUD）。

写入方：`DictRepository.addCustom()` / `updateEntry()`。
读取方：`dictEntriesProvider(DictType)` StreamProvider。

## 11. SearchHistoryEntries

全局搜索的最近查询与最近访问记录。

设计目标：

- 不再将搜索轨迹落到明文 JSON 文件；
- 进入 SQLCipher 主库，与其余本地数据统一加密；
- 仍保持轻量，不引入额外 domain entity 或复杂查询模型。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | INTEGER | 是 | 自增主键 |
| kind | VARCHAR(8) | 是 | `QUERY` / `VISIT` |
| unique_key | VARCHAR(160) | 是 | 幂等键；查询为 `Q:{normalizedQuery}`，访问为 `V:{feature}:{targetId}`；UNIQUE |
| query | TEXT | 否 | 最近搜索词，仅 `QUERY` 使用 |
| feature | VARCHAR(32) | 否 | `SearchFeature.name`，仅 `VISIT` 使用 |
| target_id | VARCHAR(64) | 否 | 最近访问目标 ID，仅 `VISIT` 使用 |
| label | TEXT | 否 | 最近访问展示标题，仅 `VISIT` 使用 |
| sublabel | TEXT | 否 | 最近访问展示副标题，仅 `VISIT` 使用 |
| visited_at | DATETIME | 是 | 最近一次搜索/访问时间 |
| updated_at | DATETIME | 是 | 排序/去重使用的最新更新时间 |

约束与策略：

- UNIQUE(`unique_key`)：相同查询 / 相同访问目标只保留最近一条；
- 查询历史最多保留 8 条；
- 访问历史最多保留 10 条；
- 启动时若发现旧版 `search_history.dat` 或 `search_history.json`，会自动迁移入库并删除旧文件。

写入方：`GlobalSearchDelegate`（搜索提交、搜索结果点击）。
读取方：`searchHistoryProvider` 空态页（最近搜索 / 最近访问）。

## 12. RegionGroupOrders

用户自定义的列表地区分组排序（schema v26 新增）。不承载业务数据，仅控制 UI 展示顺序。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| scene | VARCHAR(32) | 是 | 展示场景标识（如 `account_list` / `asset_list`），复合主键之一 |
| region_code | VARCHAR(16) | 是 | 地区编码（来自 `sovereignty_region` 字典），复合主键之一 |
| sort_order | INTEGER | 是 | 该场景下该地区的展示排序（默认 1000） |

主键：`(scene, region_code)`。

写入方：列表页用户拖拽排序后持久化。
读取方：账户/资产列表页的地区分组排序。
