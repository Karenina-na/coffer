import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset.dart';
import '../entities/asset_enums.dart';
import '../repositories/account_repository.dart';
import '../repositories/asset_repository.dart';

/// 新建资产用例。
///
/// 职责：
/// - 非空字段、金额正负校验
/// - 校验 account_id 存在
/// - 生成 id 与时间戳
/// - 若提供了 current_price，自动计算 market_value 快照
class CreateAssetUseCase {
  CreateAssetUseCase(
    this._assets,
    this._accounts, {
    required String Function() idGenerator,
    required DateTime Function() now,
  })  : _idGen = idGenerator,
        _now = now;

  final AssetRepository _assets;
  final AccountRepository _accounts;
  final String Function() _idGen;
  final DateTime Function() _now;

  Future<Result<Asset, AppError>> call({
    required String accountId,
    required AssetType assetType,
    required Decimal quantity,
    required String currency,
    String? assetCode,
    Decimal? costPrice,
    Decimal? currentPrice,
    AssetStatus status = AssetStatus.holding,
    Map<String, dynamic>? extInfo,
  }) async {
    if (quantity < Decimal.zero) {
      return const Err(ValidationError('quantity must be >= 0'));
    }
    if (currency.trim().isEmpty) {
      return const Err(ValidationError('currency is required'));
    }
    if (costPrice != null && costPrice < Decimal.zero) {
      return const Err(ValidationError('costPrice must be >= 0'));
    }
    if (currentPrice != null && currentPrice < Decimal.zero) {
      return const Err(ValidationError('currentPrice must be >= 0'));
    }

    final accountCheck = await _accounts.findById(accountId);
    if (accountCheck.isErr) {
      return Err(accountCheck.errorOrNull!);
    }

    final now = _now();
    final market = currentPrice == null ? null : quantity * currentPrice;
    final asset = Asset(
      id: _idGen(),
      accountId: accountId,
      assetType: assetType,
      assetCode: assetCode,
      quantity: quantity,
      costPrice: costPrice,
      currentPrice: currentPrice,
      currency: currency.trim(),
      marketValue: market,
      valuationTime: currentPrice == null ? null : now,
      status: status,
      extInfo: extInfo,
      createdAt: now,
      updatedAt: now,
    );
    return _assets.create(asset);
  }
}
