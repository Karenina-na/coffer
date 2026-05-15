import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/account.dart';
import '../entities/account_enums.dart';
import '../repositories/account_repository.dart';

/// 新建账户用例。
///
/// 负责：
/// - 基础字段校验（非空、枚举合法性由调用侧的类型系统保证）
/// - id 生成、时间戳写入
/// - 委派仓储持久化
class CreateAccountUseCase {
  CreateAccountUseCase(
    this._repo, {
    required String Function() idGenerator,
    required DateTime Function() now,
  })  : _idGen = idGenerator,
        _now = now;

  final AccountRepository _repo;
  final String Function() _idGen;
  final DateTime Function() _now;

  Future<Result<Account, AppError>> call({
    required AccountType accountType,
    required String sovereigntyRegion,
    required String institutionName,
    String? accountNo,
    DateTime? openedAt,
    Map<String, dynamic>? extInfo,
    AccountStatus status = AccountStatus.active,
    double fxSpreadPercent = 0,
    Decimal? fxFixedFee,
  }) {
    if (sovereigntyRegion.trim().isEmpty) {
      return Future.value(
        const Err(ValidationError('sovereigntyRegion is required')),
      );
    }
    if (institutionName.trim().isEmpty) {
      return Future.value(
        const Err(ValidationError('institutionName is required')),
      );
    }
    final now = _now();
    final account = Account(
      id: _idGen(),
      accountNo: accountNo,
      accountType: accountType,
      sovereigntyRegion: sovereigntyRegion.trim(),
      institutionName: institutionName.trim(),
      status: status,
      openedAt: openedAt,
      extInfo: extInfo,
      fxSpreadPercent: fxSpreadPercent,
      fxFixedFee: fxFixedFee,
      createdAt: now,
      updatedAt: now,
    );
    return _repo.create(account);
  }
}
