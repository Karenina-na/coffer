import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/dict_type.dart';
import '../entities/account_channel.dart';
import '../repositories/account_channel_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/channel_repository.dart';
import '../repositories/dict_repository.dart';

class SaveAccountChannelConfigUseCase {
  const SaveAccountChannelConfigUseCase(
    this._links,
    this._accounts,
    this._channels,
    this._dicts,
  );

  final AccountChannelRepository _links;
  final AccountRepository _accounts;
  final ChannelRepository _channels;
  final DictRepository _dicts;

  Future<Result<AccountChannel, AppError>> call({
    required String accountId,
    required String channelId,
    Decimal? feeRateOverride,
    Decimal? fixedFeeOverride,
    String? feeCurrencyOverride,
    String? regionOverride,
  }) async {
    final aid = accountId.trim();
    final cid = channelId.trim();
    final feeCurrency = feeCurrencyOverride?.trim().toUpperCase();

    if (aid.isEmpty || cid.isEmpty) {
      return const Err(ValidationError('账户与通道 ID 不能为空'));
    }
    if (feeRateOverride != null && feeRateOverride < Decimal.zero) {
      return const Err(ValidationError('账户级费率不能为负数'));
    }
    if (fixedFeeOverride != null && fixedFeeOverride < Decimal.zero) {
      return const Err(ValidationError('账户级固定费用不能为负数'));
    }
    if (feeCurrency != null && feeCurrency.isNotEmpty) {
      final currency = await _dicts.findByTypeAndCode(DictType.currency, feeCurrency);
      if (currency == null) {
        return Err(ValidationError('未知币种：$feeCurrency'));
      }
    }

    final account = await _accounts.findById(aid);
    if (account.isErr) return Err(account.errorOrNull!);
    final channel = await _channels.findById(cid);
    if (channel.isErr) return Err(channel.errorOrNull!);

    return _links.saveConfig(
      accountId: aid,
      channelId: cid,
      feeRateOverride: feeRateOverride,
      fixedFeeOverride: fixedFeeOverride,
      feeCurrencyOverride: feeCurrency,
      regionOverride: regionOverride,
    );
  }
}
