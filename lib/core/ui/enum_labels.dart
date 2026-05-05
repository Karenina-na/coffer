/// 枚举的中文展示标签。
///
/// 展示约定：UI 可直接用 `labelZh`（纯中文）或 `labelBilingual`（中文（CODE））。
/// 保持底层 `.code` 与 DB / 同步协议一致，不做改动。
///
/// TODO(i18n): 目前所有标签硬编码为简中。后续接入 flutter_localizations / intl 时，
///   将 `switch (this)` 分支替换为 `AppLocalizations.of(ctx).assetTypeStock` 等 getter，
///   并把 `labelZh` 改为 `labelLocalized(BuildContext)`。调用点已集中在 presentation 层，
///   迁移成本集中在本文件 + 调用处的上下文注入。
library;

import '../../domain/entities/account_enums.dart';
import '../../domain/entities/asset_enums.dart';
import '../../domain/entities/card_enums.dart';
import '../../domain/entities/channel_enums.dart';
import '../../domain/entities/event_enums.dart';
import '../../domain/entities/exchange_rate_enums.dart';

extension AssetTypeLabel on AssetType {
  String get labelZh => switch (this) {
        AssetType.stock => '股票',
        AssetType.equity => '股权',
        AssetType.fund => '基金',
        AssetType.bond => '债券',
        AssetType.cd => '大额存单',
        AssetType.option => '期权',
        AssetType.future => '期货',
        AssetType.warrant => '认股权证',
        AssetType.policy => '保单',
        AssetType.crypto => '加密货币',
        AssetType.perpetual => '永续合约',
        AssetType.contract => '合约',
        AssetType.preciousMetal => '贵金属',
        AssetType.fxAsset => '外汇资产',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension AssetStatusLabel on AssetStatus {
  String get labelZh => switch (this) {
        AssetStatus.holding => '持有中',
        AssetStatus.frozen => '冻结',
        AssetStatus.redeemed => '已赎回',
        AssetStatus.closed => '已关闭',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension AccountTypeLabel on AccountType {
  String get labelZh => switch (this) {
        AccountType.bank => '银行',
        AccountType.broker => '券商',
        AccountType.insurance => '保险',
        AccountType.payment => '支付',
        AccountType.custody => '托管',
        AccountType.cryptoExchange => '加密交易所',
        AccountType.cryptoWallet => '加密钱包',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension AccountStatusLabel on AccountStatus {
  String get labelZh => switch (this) {
        AccountStatus.active => '活跃',
        AccountStatus.inactive => '未激活',
        AccountStatus.dormant => '休眠',
        AccountStatus.closed => '已关闭',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension CardTypeLabel on CardType {
  String get labelZh => switch (this) {
        CardType.debit => '借记卡',
        CardType.credit => '信用卡',
        CardType.prepaid => '预付卡',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension CardStatusLabel on CardStatus {
  String get labelZh => switch (this) {
        CardStatus.active => '正常',
        CardStatus.locked => '已锁定',
        CardStatus.expired => '已过期',
        CardStatus.closed => '已关闭',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension CardOrganizationLabel on CardOrganization {
  String get labelZh => switch (this) {
        CardOrganization.visa => 'Visa',
        CardOrganization.mastercard => 'Mastercard',
        CardOrganization.unionpay => '银联',
        CardOrganization.jcb => 'JCB',
        CardOrganization.amex => '美国运通',
        CardOrganization.discover => 'Discover',
        CardOrganization.diners => '大来',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension RelatedModelLabel on RelatedModel {
  String get labelZh => switch (this) {
        RelatedModel.account => '账户',
        RelatedModel.asset => '资产',
        RelatedModel.card => '银行卡',
        RelatedModel.channel => '转账通道',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension EventStatusLabel on EventStatus {
  String get labelZh => switch (this) {
        EventStatus.pending => '待处理',
        EventStatus.triggered => '已触发',
        EventStatus.resolved => '已解决',
        EventStatus.closed => '已关闭',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension EventPriorityLabel on EventPriority {
  String get labelZh => switch (this) {
        EventPriority.low => '低',
        EventPriority.medium => '中',
        EventPriority.high => '高',
        EventPriority.critical => '紧急',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension HandlingStatusLabel on HandlingStatus {
  String get labelZh => switch (this) {
        HandlingStatus.unhandled => '未处理',
        HandlingStatus.processing => '处理中',
        HandlingStatus.handled => '已处理',
        HandlingStatus.failed => '失败',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension AckRequirementLabel on AckRequirement {
  String get labelZh => switch (this) {
        AckRequirement.notApplicable => '无需确认',
        AckRequirement.optional => '可选确认',
        AckRequirement.required_ => '必须确认',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension AckStatusLabel on AckStatus {
  String get labelZh => switch (this) {
        AckStatus.pending => '待确认',
        AckStatus.confirmed => '已确认',
        AckStatus.dismissed => '已忽略',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension ChannelStatusLabel on ChannelStatus {
  String get labelZh => switch (this) {
        ChannelStatus.enabled => '启用',
        ChannelStatus.disabled => '停用',
        ChannelStatus.maintenance => '维护中',
      };
  String get labelBilingual => '$labelZh（$code）';
}

extension SnapshotTypeLabel on SnapshotType {
  String get labelZh => switch (this) {
        SnapshotType.realtime => '实时',
        SnapshotType.hourly => '小时',
        SnapshotType.daily => '每日',
      };
  String get labelBilingual => '$labelZh（$code）';
}
