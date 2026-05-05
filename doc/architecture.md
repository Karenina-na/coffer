# GWP 架构设计

## 1. 说明

本文件定义 GWP 的应用形态、分层架构、技术选型与工程结构，作为后续开发的基线。

- 应用形态：**Flutter 跨端 App（iOS / Android）**
- 部署形态：**纯本地，不引入远端服务**
- 数据范围：与 `doc/data-definitions.md`、`doc/er-diagram.md` 定义的 6 个核心实体对齐

## 2. 架构分层

采用 Clean Architecture 的裁剪版，将「数据组织与维护」作为逻辑后端，「展示渲染」作为逻辑前端，中间以领域层解耦。

- **Presentation（前端）**：页面、组件、路由、交互状态；只依赖 Domain
- **Domain（领域）**：实体、仓储接口、用例（估值、换汇、限额、事件）、领域事件
- **Data（后端）**：Drift 数据库、Repository 实现、加密、导入导出
- **Core（横切）**：加密、金额、错误、结果类型等基础设施

依赖方向：`Presentation → Domain ← Data`，Domain 不依赖任何外部框架。

## 3. 技术选型

| 领域 | 选型 | 说明 |
|---|---|---|
| UI | Flutter 3.x + Material 3 | 跨端一套代码 |
| 状态管理 | Riverpod 2 | 编译期安全、天然 DI |
| 路由 | go_router | 声明式路由 |
| 本地数据库 | Drift | 类型安全 SQL，支持 SQLCipher |
| 库级加密 | sqlcipher_flutter_libs | 整库加密 |
| 字段级加密 | cryptography (AES-GCM) | 卡号、CVV 等敏感字段二次封装 |
| 密钥存储 | flutter_secure_storage | iOS Keychain / Android Keystore |
| 序列化 | freezed + json_serializable | 不可变模型、JSON 转换 |
| 依赖注入 | Riverpod Provider | 不再引入 get_it |
| 金额 | decimal 包 | 严禁使用 double 处理金额 |
| 国际化/格式化 | intl | 货币、日期格式化 |
| 事件总线 | 自研 Stream 实现 + Drift 持久化 | 事件落库到 Event 表 |
| 生物识别 | local_auth | 启动解锁 |
| 本地通知 | flutter_local_notifications | 汇率提醒 / 资产同步过期 / 账单日提醒（默认关闭） |
| 测试 | flutter_test + drift in-memory + mocktail | 单测与集成测 |

## 4. 工程结构

```
lib/
├── main.dart
├── app/                         # 应用壳：路由、主题、入口
│   ├── router.dart
│   └── theme.dart
├── core/                        # 横切基础设施
│   ├── auth/                    # BiometricAuth
│   ├── crypto/                  # AES-GCM、KeyStore、PasswordKDF
│   ├── money/                   # Decimal、Currency 工具
│   ├── ui/                      # EntitySearchDelegate 等跨 feature UI
│   ├── notifications/           # NotificationService（本地通知封装）
│   ├── result.dart              # Result<T, E>
│   └── errors.dart
├── data/
│   ├── db/                      # Drift database、tables、daos
│   ├── repositories/            # Repository 实现
│   ├── providers/               # 外部数据适配器（实现 `domain/providers` 接口）
│   │   ├── fx/                  # FrankfurterProvider（实现 FxRateProvider）
│   │   └── asset/               # Eastmoney / Yahoo / Composite（实现 AssetPriceProvider）
│   ├── backup/                  # DbSnapshot（加密备份 / 恢复）
│   └── crypto_service.dart
├── domain/
│   ├── entities/                # freezed 领域模型（与 DB 行解耦）
│   ├── repositories/            # 抽象接口
│   ├── providers/               # 外部数据源抽象（AssetPriceProvider / FxRateProvider）
│   ├── utils/                   # 共享工具（如 `pairKeyOf`）
│   ├── usecases/                # 用例（估值、换汇、限额、事件、备份、更新等）
│   └── events/                  # 领域事件定义
└── features/                    # 按实体 / 视图切 feature
    ├── account/
    ├── asset/
    ├── card/
    ├── channel/
    ├── exchange_rate/
    ├── event/
    ├── holdings/                # 资金总览（账户 / 资产 / 转账 三 Tab）
    ├── dashboard/               # 总览仪表盘
    ├── topology/                # 全景关系图
    ├── backup/                  # 备份 / 恢复页
    ├── settings/                # App 级全局设置
    └── auth/                    # 生物识别解锁 Gate
```

**依赖约束**

- `features/*/presentation` 只依赖 `domain`
- `data` 只实现 `domain/repositories` 中的接口
- UI 永远消费 freezed 领域实体，不直接持有 Drift 行对象

## 5. 数据层规范

- 一个 Drift `Database`（当前 `schemaVersion = 14`），11 张表：`Accounts / Assets / AssetPriceHistory / AssetCostHistory / Cards / Channels / AccountChannels / DictEntries / Events / ExchangeRates / WatchedPairs`；字段约束对齐 `doc/data-definitions.md`
- JSON 字段（`ext_info`、`sovereignty_region_rule`、`raw_payload`）以 `TEXT` 存储，DAO 层负责 `fromJson/toJson`
- `DECIMAL(28,8)` / `DECIMAL(28,10)` 及阈值类字段（含 `watched_pairs.threshold_high / threshold_low / alert_change_pct`，v12 起）在 SQLite 无原生支持，统一以 `TEXT` 存储，应用层使用 `Decimal`，**禁止使用 `REAL`**
- 软删除：带 `is_deleted` 的表建立 partial index，查询统一 `where is_deleted = 0`
- `account_channels` 通过外键约束连接 `accounts / channels`，并在父记录硬删除时级联清理，避免孤儿关联
- 敏感列（`card_no_ciphertext`、`cvv_ciphertext`）在库级加密之外再做字段级 AES-GCM，密钥独立派生
- 迁移：Drift `MigrationStrategy`，schema 版本号与 DDL 一同入库提交

## 6. 领域层规范

- UseCase 单一职责，典型用例：
  - `ValuateAssetUseCase`：读 Asset + ExchangeRate → 计算 `market_value` → 写回 + 写入 `AssetPriceHistoryPoint`（成功估值不进事件表，只记审计日志）
  - 资产编辑流程：用户调整 `cost_price` / `quantity` 时自动追加 `AssetCostHistoryPoint`（见 data-definitions.md §9），与价格历史解耦
  - `CheckChannelLimitUseCase`：按 Channel 的日限、单笔、地区规则校验
  - `RecordEventUseCase`：统一事件落库入口
- **事件驱动估值**：价格或汇率更新触发事件，订阅者异步重算受影响的 `Asset.market_value`，避免查询时实时计算
- **Channel 规则引擎**：`sovereignty_region_rule` 采用 JSON Schema + 谓词列表实现，避免 if-else 蔓延
- **多跳路径规划**：`PlanTransferRouteUseCase` 以 Account.id 为图节点，按 `AccountChannel` 聚合同一通道的成员账户并在两两之间生成双向边，规则引擎按 (from, to) 的 `sovereignty_region` 逐边评估；Dijkstra 支持 minFee / minHops 两种目标
- **ExchangeRate 抽象**：定义 `PriceProvider` 接口，REALTIME / HOURLY / DAILY 三种快照类型对应不同实现，便于替换与离线兜底

## 7. 表现层规范

- 每个 feature 暴露一个 `*NotifierProvider`，对外只暴露不可变 `State`
- 列表视图使用 `AsyncValue` + `StreamProvider` 直连 Drift `watch*()`，数据变更自动驱动 UI
- 金额展示统一走 `MoneyFormatter`，按资产 `currency` 精度渲染
- 敏感字段仅展示 masked 值，绝不渲染明文密文
- 支持 Material 3 动态取色与深色模式

## 8. 安全规范

- 启动走生物识别解锁（`local_auth`），失败 N 次清空内存中的密钥与敏感态
- 密钥体系：主密钥存 Keystore / Keychain，通过 HKDF 派生出 SQLCipher 密钥与字段加密密钥
- 禁止日志打印敏感字段；Release 构建关闭 `debugPrint`
- 平台兜底：iOS 设置 `NSFileProtectionComplete`，Android 使用 `EncryptedFile`
- 备份导出文件必须经用户口令加密（Argon2id 派生密钥 + AES-GCM），不进入系统明文备份；快照导出会剥离 `cards.card_no_ciphertext` / `cvv_ciphertext`（跨设备无法解密，避免无效密文随包外泄）

## 9. 实施路线

1. 初始化 Flutter 工程 + Drift schema（6 张表）+ migration
2. 落地 `core/crypto`、`core/money`、`Result` 基础设施
3. 实现 Account / Card / Asset 三个 feature 的 CRUD 与列表
4. 接入 ExchangeRate 的手动导入（CSV / JSON）+ `PriceProvider` 抽象（Frankfurter）
5. 实现 Asset 估值 UseCase + 事件总线 + Event 持久化
6. 构建 Channel 规则引擎与多跳路径规划（`PlanTransferRouteUseCase`，Dijkstra on Account.id graph，边由 `AccountChannel` 关联派生；支持 minFee / minHops 目标；不做账务变动，仅报价）
7. 接入生物识别、备份导入导出
8. 外部资产行情（Yahoo Finance `/v8/finance/chart`）+ 统一同步按钮 + 缓存覆盖提示
9. 统一搜索（AppBar 按钮 + `EntitySearchDelegate` + 预设过滤 Chip + 实时结果）
10. 全量实体 CRUD 闭环：账户 / 资产 / 卡片 / 通道 / 事件 的编辑路由 + 软/硬删除；卡片 `update()` 允许选择性替换卡号 / CVV，对应字段重新加密，其余字段保留原密文
11. 仪表盘深度优化：多维度 KPI（含信用利用率、事件紧急度、缺失汇率）、趋势区间切换（7D / 1M / 3M / 1Y / ALL）+ delta、资产配置 segmented donut、信用卡账单 45 天预警、近期活动 feed
12. 体验与可维护性补齐：事件中心快捷操作、本地通知（flutter_local_notifications，默认关闭）、资产成本历史审计（`AssetCostHistory`，schema v11 + 索引）
13. UI 打磨：主题、空状态、错误态、国际化
