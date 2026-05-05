import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_channel.freezed.dart';

/// 账户与通道的多对多关联。
///
/// - 一个账户可接入多条 Channel（例如同一张借记卡支持 `UnionPay` + `SWIFT`）。
/// - 一条 Channel 可被多个账户使用。
/// - 路径规划在共同接入同一 Channel 的账户之间建边。
@freezed
abstract class AccountChannel with _$AccountChannel {
  const factory AccountChannel({
    required String accountId,
    required String channelId,
    required DateTime createdAt,
  }) = _AccountChannel;
}
