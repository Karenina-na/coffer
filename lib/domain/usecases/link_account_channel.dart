import '../../core/errors.dart';
import '../../core/result.dart';
import '../repositories/account_channel_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/channel_repository.dart';

class LinkAccountChannelUseCase {
  const LinkAccountChannelUseCase(
    this._links,
    this._accounts,
    this._channels,
  );

  final AccountChannelRepository _links;
  final AccountRepository _accounts;
  final ChannelRepository _channels;

  Future<Result<void, AppError>> link({
    required String accountId,
    required String channelId,
  }) async {
    if (accountId.trim().isEmpty || channelId.trim().isEmpty) {
      return const Err(ValidationError('账户与通道 ID 不能为空'));
    }
    final account = await _accounts.findById(accountId);
    if (account.isErr) return Err(account.errorOrNull!);
    final channel = await _channels.findById(channelId);
    if (channel.isErr) return Err(channel.errorOrNull!);
    final linked = await _links.link(accountId: accountId, channelId: channelId);
    return linked.when(
      ok: (_) => const Ok(null),
      err: Err.new,
    );
  }

  Future<Result<void, AppError>> unlink({
    required String accountId,
    required String channelId,
  }) {
    if (accountId.trim().isEmpty || channelId.trim().isEmpty) {
      return Future.value(const Err(ValidationError('账户与通道 ID 不能为空')));
    }
    return _links.unlink(accountId: accountId, channelId: channelId);
  }
}
