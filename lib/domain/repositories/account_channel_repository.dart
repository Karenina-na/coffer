import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/account_channel.dart';

/// 账户-通道关联仓储。
abstract interface class AccountChannelRepository {
  Stream<List<AccountChannel>> watchAll();

  Stream<List<AccountChannel>> watchByAccount(String accountId);

  Future<Result<List<AccountChannel>, AppError>> listByChannel(String channelId);

  Future<Result<AccountChannel, AppError>> link({
    required String accountId,
    required String channelId,
  });

  Future<Result<AccountChannel, AppError>> saveConfig({
    required String accountId,
    required String channelId,
    Decimal? feeRateOverride,
    Decimal? fixedFeeOverride,
    String? feeCurrencyOverride,
    String? regionOverride,
  });

  Future<Result<void, AppError>> unlink({
    required String accountId,
    required String channelId,
  });

  Future<Result<void, AppError>> replaceForAccount({
    required String accountId,
    required List<String> channelIds,
  });
}
