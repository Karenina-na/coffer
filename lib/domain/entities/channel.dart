import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'channel_enums.dart';

part 'channel.freezed.dart';

/// 转账通道（网络/协议级定义），字段对齐 doc/data-definitions.md §4。
///
/// **语义**：Channel 描述一个独立的转账网络或协议（如 SWIFT、SEPA、微信支付、
/// 闪电网络），携带费率、限额、区域规则等。账户通过 `AccountChannel` 关联
/// 表声明自己"接入了哪些通道"。两个账户只要共享同一条 Channel，即可经由
/// 该通道互相转账，多跳路径规划据此推导。
///
/// [sovereigntyRegionRule] 采用简单 DSL，见 `domain/usecases/channel_rule.dart`：
/// ```json
/// {
///   "allowedRegions": ["CN", "HK"],
///   "blockedRegions": ["KP"],
///   "requireSameRegion": false
/// }
/// ```
@freezed
abstract class Channel with _$Channel {
  const factory Channel({
    required String id,
    required String name,
    /// 转账协议代码（如 SWIFT / ACH / SEPA / 用户自定义）。
    ///
    /// 值来自 `dict_entries` 表的 `TRANSFER_PROTOCOL` 类型，应用层只按代码字符串
    /// 处理，展示时通过 [DictRepository] 查出对应名称。
    required String transferProtocol,
    Decimal? feeRate,
    Decimal? fixedFee,
    Map<String, dynamic>? sovereigntyRegionRule,
    String? limitCurrency,
    Decimal? dailyLimit,
    Decimal? singleLimit,
    required ChannelStatus status,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Channel;
}
