# GWP ER 图

## 1. 说明

本文件仅用于展示 GWP 核心数据模型的实体关系图。

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

    ACCOUNT {
        string id PK
        string account_no
        string account_type
        string sovereignty_region
        string institution_name
        string status
        datetime opened_at
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
        decimal fee_rate
        decimal fixed_fee
        string limit_currency
        decimal daily_limit
        decimal single_limit
        string status
        datetime effective_from
        datetime effective_to
        datetime created_at
        datetime updated_at
    }

    ACCOUNT_CHANNEL {
        string id PK
        string account_id FK
        string channel_id FK
        datetime created_at
    }

    CARD {
        string id PK
        string account_id FK
        string card_organization
        string card_no_masked
        string card_type
        int expire_month
        int expire_year
        string issuer_name
        string currency
        decimal credit_limit
        decimal available_credit
        int billing_cycle_day
        int payment_due_day
        string billing_address
        boolean is_virtual
        string status
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
    }

    EVENT {
        string id PK
        string event_type
        string related_model
        string related_id
        datetime trigger_time
        string priority
        string status
        string handling_status
        string handler
        string handling_note
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
```

## 3. 关系说明

- ACCOUNT -> ASSET: 一对多
- ACCOUNT -> CARD: 一对多
- ACCOUNT <-> CHANNEL: 通过 ACCOUNT_CHANNEL 多对多关联；路由规划以 Account.id 为节点，在同通道成员间生成双向边
- ASSET -> ASSET_PRICE_HISTORY: 一对多；每次成功估值写入一条快照，承接资产价格走势与 Dashboard 趋势
- ASSET -> ASSET_COST_HISTORY: 一对多；用户手动调整 cost_price / quantity 时写入一条审计记录
- EXCHANGE_RATE: 独立汇率服务，被资产估值和卡结算调用
- EVENT: 跨模型通用事件记录（操作型告警：失败、到期、同步过期等），**不再承载成功估值**
