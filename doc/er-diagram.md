# Coffer ER 图

## 1. 说明

本文件仅用于展示 Coffer 核心数据模型的实体关系图。

## 2. Mermaid ER 图

```mermaid
erDiagram
    ACCOUNT ||--o{ ASSET : owns
    ACCOUNT ||--o{ CARD : owns
    ACCOUNT ||--o{ ACCOUNT_CHANNEL : supports
    CHANNEL ||--o{ ACCOUNT_CHANNEL : linked_by
    ASSET ||--o{ ASSET_PRICE_HISTORY : priced_by
    ASSET ||--o{ ASSET_COST_HISTORY : adjusted_by
    ASSET }o..o{ EXCHANGE_RATE : convert_with
    CARD }o..o{ EXCHANGE_RATE : settle_with
    WATCHED_PAIR ||--o{ EXCHANGE_RATE : triggers

    ACCOUNT {
        string id PK
        string account_no
        string account_type
        string sovereignty_region
        string institution_name
        string status
        datetime opened_at
        real fx_spread_percent
        decimal fx_fixed_fee
        json ext_info
        datetime created_at
        datetime updated_at
        boolean is_deleted
    }

    ASSET {
        string id PK
        string account_id FK
        string asset_type
        string asset_code
        decimal quantity
        decimal cost_price
        decimal current_price
        string currency
        decimal market_value
        datetime valuation_time
        string status
        json ext_info
        datetime created_at
        datetime updated_at
        boolean is_deleted
    }

    CHANNEL {
        string id PK
        string name
        string transfer_protocol
        boolean is_builtin
        decimal fee_rate
        decimal fixed_fee
        json sovereignty_region_rule
        string limit_currency
        decimal daily_limit
        decimal single_limit
        string status
        int sort_order
        datetime effective_from
        datetime effective_to
        datetime created_at
        datetime updated_at
    }

    ACCOUNT_CHANNEL {
        string account_id PK
        string channel_id PK
        decimal fee_rate_override
        decimal fixed_fee_override
        string fee_currency_override
        string region_override
        datetime created_at
        datetime updated_at
    }

    CARD {
        string id PK
        string account_id FK
        string card_organization
        string card_no_masked
        string card_no_ciphertext
        string card_type
        int expire_month
        int expire_year
        string cvv_ciphertext
        string issuer_name
        string currency
        boolean supports_all_currencies
        string supported_currencies
        decimal credit_limit
        decimal available_credit
        int billing_cycle_day
        int payment_due_day
        string billing_address
        boolean is_virtual
        string status
        int sort_order
        datetime created_at
        datetime updated_at
    }

    EXCHANGE_RATE {
        string id PK
        string pair_key
        string base_currency
        string quote_currency
        decimal rate
        datetime as_of_time
        datetime updated_at
        string source
        string snapshot_type
        json raw_payload
    }

    EVENT {
        string id PK
        string event_type
        string related_model
        string related_id
        json refs
        string batch_id
        string source_key
        datetime trigger_time
        datetime due_at
        string priority
        string status
        string handling_status
        string handler
        string handling_note
        string ack_requirement
        string ack_status
        datetime ack_at
        string ack_note
        boolean is_deleted
        datetime created_at
        datetime updated_at
    }

    ASSET_PRICE_HISTORY {
        string id PK
        string asset_id FK
        decimal price
        decimal market_value
        string currency
        string source
        string batch_id
        datetime trigger_time
        string source_key
        string raw_payload
        datetime created_at
    }

    ASSET_COST_HISTORY {
        string id PK
        string asset_id FK
        decimal cost_price
        decimal quantity
        string currency
        string source
        string reason
        datetime trigger_time
        string source_key
        datetime created_at
    }

    WATCHED_PAIR {
        string pair_key PK
        string base_currency
        string quote_currency
        datetime created_at
        decimal threshold_high
        decimal threshold_low
        decimal alert_change_pct
        int sort_order
    }

    DICT_ENTRY {
        int id PK
        string type
        string code
        string name
        string name_en
        int sort_order
        boolean is_builtin
        string flag_emoji
        string continent
        string color_hex
        float map_lon
        float map_lat
        float anchor_lon
        float anchor_lat
        string parent_region
        datetime created_at
        datetime updated_at
    }

    REGION_GROUP_ORDER {
        string scene PK
        string region_code PK
        int sort_order
    }

    SEARCH_HISTORY_ENTRY {
        int id PK
        string kind
        string unique_key
        string query
        string feature
        string target_id
        string label
        string sublabel
        datetime visited_at
        datetime updated_at
    }
```

## 3. 关系说明

- ACCOUNT -> ASSET: 一对多
- ACCOUNT -> CARD: 一对多
- ACCOUNT <-> CHANNEL: 通过 ACCOUNT_CHANNEL 多对多关联；路由规划以 `(accountId, currency)` 为扩展状态空间，在同通道成员间生成双向边；ACCOUNT_CHANNEL 承载账户级的费用覆盖与运行时地区覆盖
- ASSET -> ASSET_PRICE_HISTORY: 一对多；每次成功估值写入一条快照，承接资产价格走势与 Dashboard 趋势
- ASSET -> ASSET_COST_HISTORY: 一对多；用户手动调整 cost_price / quantity 时写入一条审计记录
- EXCHANGE_RATE: 独立汇率服务，被资产估值、卡结算、多币种路径规划（FX 换汇边权重）调用
- EVENT: 跨模型通用事件记录（操作型告警：失败、到期、同步过期等），**不再承载成功估值**
- WATCHED_PAIR: 用户关注的币对，触发汇率告警的阈值管理
- DICT_ENTRY: 字典表（转账协议 / 主权地区 / 货币），`is_builtin` 标记内置项
- REGION_GROUP_ORDER: 用户自定义地区分组排序，按 scene 分场景，独立于业务实体
- SEARCH_HISTORY_ENTRY: 全局搜索历史，`unique_key` 幂等去重，独立于业务实体
