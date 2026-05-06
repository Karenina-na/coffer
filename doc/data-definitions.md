# GWP 数据定义

## 1. 说明

本文件用于沉淀 GWP 核心实体的数据结构定义，面向开发实现与接口对齐。

- 账户类型范围：BANK / BROKER / INSURANCE / PAYMENT / CUSTODY / CRYPTO_EXCHANGE / CRYPTO_WALLET
- 资产类型范围：STOCK / EQUITY / FUND / BOND / CD / OPTION / FUTURE / WARRANT / POLICY / CRYPTO / PERPETUAL / CONTRACT / PRECIOUS_METAL / FX_ASSET
- 卡类型范围：DEBIT / CREDIT / PREPAID

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
| currency | VARCHAR(10) | 是 | 计价币种或数字资产符号 |
| market_value | DECIMAL(28,10) | 否 | 市值缓存 |
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
| effective_from | DATETIME | 否 | 生效时间 |
| effective_to | DATETIME | 否 | 失效时间 |
| created_at | DATETIME | 是 | 创建时间 |
| updated_at | DATETIME | 是 | 更新时间 |

> Channel 不再绑定源/目账户类型；是否两个账户能通过某通道互转，由 `account_channels` 关联决定。路由规划（Dijkstra on Account id）会为同一通道内所有账户对生成双向边。

## 4a. AccountChannel（账户-通道关联）

账户与通道的多对多关联，一个账户可声明支持多个通道，一个通道也可被多个账户共享。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID / BIGINT | 是 | 主键 |
| account_id | UUID / BIGINT | 是 | 外键，关联 Account.id |
| channel_id | UUID / BIGINT | 是 | 外键，关联 Channel.id |
| created_at | DATETIME | 是 | 创建时间 |

唯一约束：`(account_id, channel_id)`。

外键约束：
- `account_id -> accounts.id`（`ON DELETE CASCADE`）
- `channel_id -> channels.id`（`ON DELETE CASCADE`）

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
| currency | VARCHAR(10) | 否 | 主记账币种（信用额度计价） |
| supports_all_currencies | TINYINT(1) | 是 | 是否全币种卡；true 时忽略列表 |
| supported_currencies | VARCHAR(256) | 否 | CSV of ISO-4217 codes，如 "USD,EUR,HKD"。空 = 仅主币种 |
| credit_limit | DECIMAL(28,8) | 否 | 信用额度（信用卡） |
| available_credit | DECIMAL(28,8) | 否 | 可用额度（信用卡） |
| billing_cycle_day | TINYINT | 否 | 账单日 |
| payment_due_day | TINYINT | 否 | 还款日 |
| billing_address | VARCHAR(256) | 否 | 账单地址 |
| is_virtual | TINYINT(1) | 是 | 是否虚拟卡 |
| status | ENUM | 是 | ACTIVE / LOCKED / EXPIRED / CLOSED |
| created_at | DATETIME | 是 | 创建时间 |
| updated_at | DATETIME | 是 | 更新时间 |

## 6. ExchangeRate

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID / BIGINT | 是 | 主键 |
| pair_key | VARCHAR(32) | 是 | 货币对唯一标识（如 USD/CNY） |
| base_currency | VARCHAR(10) | 是 | 基础币种 |
| quote_currency | VARCHAR(10) | 是 | 目标币种 |
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
| base_currency | VARCHAR(10) | 是 | 基础币种 |
| quote_currency | VARCHAR(10) | 是 | 目标币种 |
| created_at | DATETIME | 是 | 加入关注的时间 |
| threshold_high | DECIMAL(28,10) / TEXT | 否 | 上沿阈值；`rate ≥ threshold_high` 触发 high 预警 |
| threshold_low | DECIMAL(28,10) / TEXT | 否 | 下沿阈值；`rate ≤ threshold_low` 触发 low 预警 |
| alert_change_pct | DECIMAL(28,10) / TEXT | 否 | 日环比波动阈值（%，正数）；`|pct| ≥` 触发 change 预警 |

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
