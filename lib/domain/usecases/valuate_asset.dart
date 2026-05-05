import 'dart:convert';

import 'package:decimal/decimal.dart';

import '../../core/date_utils.dart';
import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset.dart';
import '../entities/asset_price_history_point.dart';
import '../repositories/asset_price_history_repository.dart';
import '../repositories/asset_repository.dart';
import '../repositories/exchange_rate_repository.dart';

/// 更新某资产的 current_price，重算 market_value，落库并写入估值快照。
///
/// 流程：
/// 1. 读取 Asset；若不存在 → NotFoundError
/// 2. （可选）根据 [priceCurrency] 查询 [PriceProvider] 做币种换算
/// 3. 写回 asset.currentPrice / marketValue / valuationTime
/// 4. 写入 [AssetPriceHistoryPoint]（审计日志表 `asset_price_history`）
///
/// 设计说明（方案 B）：
/// 成功估值**不再写领域事件**——每日同步会刷上百行，淹没真正需要用户感知的告
/// 警。成功路径走独立的审计日志表，UI 照常查询；事件表只收失败、同步过期等
/// 操作型条目。
class ValuateAssetUseCase {
  ValuateAssetUseCase(
    this._assets,
    this._priceHistory,
    this._prices, {
    required String Function() idGenerator,
    required DateTime Function() now,
    Future<T> Function<T>(Future<T> Function())? transaction,
  })  : _idGen = idGenerator,
        _now = now,
        _tx = transaction ?? _defaultTx;

  final AssetRepository _assets;
  final AssetPriceHistoryRepository _priceHistory;
  final PriceProvider _prices;
  final String Function() _idGen;
  final DateTime Function() _now;
  final Future<T> Function<T>(Future<T> Function()) _tx;

  static Future<T> _defaultTx<T>(Future<T> Function() fn) => fn();

  /// [newPrice] 单位为 [priceCurrency]；若 [priceCurrency] 与 asset.currency
  /// 不同，则通过 [PriceProvider] 按最新汇率折算。
  ///
  /// [source] 标识估值来源（`manual` / `yahoo` / `eastmoney` …），
  /// 参与 `sourceKey` 构造以去重同日同源重复写入。
  Future<Result<Asset, AppError>> call({
    required String assetId,
    required Decimal newPrice,
    String? priceCurrency,
    String source = 'manual',
  }) async {
    if (newPrice <= Decimal.zero) {
      return const Err(ValidationError('newPrice must be > 0'));
    }

    final found = await _assets.findById(assetId);
    if (found.isErr) return Err(found.errorOrNull!);
    final asset = found.valueOrNull!;

    Decimal priceInAssetCcy = newPrice;
    if (priceCurrency != null &&
        priceCurrency.toUpperCase() != asset.currency.toUpperCase()) {
      final r = await _prices.getRate(
        baseCurrency: priceCurrency,
        quoteCurrency: asset.currency,
      );
      if (r.isErr) return Err(r.errorOrNull!);
      final rate = r.valueOrNull!;
      if (rate <= Decimal.zero) {
        return const Err(ValidationError('fx rate must be > 0'));
      }
      priceInAssetCcy = newPrice * rate;
    }

    final now = _now();
    final market = asset.quantity * priceInAssetCcy;
    final updated = asset.copyWith(
      currentPrice: priceInAssetCcy,
      marketValue: market,
      valuationTime: now,
      updatedAt: now,
    );

    final dayKey = utcDayKey(now);
    final point = AssetPriceHistoryPoint(
      id: _idGen(),
      assetId: assetId,
      price: priceInAssetCcy,
      marketValue: market,
      currency: asset.currency,
      source: source,
      triggerTime: now,
      // 同资产同天同源只保留一条；重复估值只更新 asset 当前价，不刷历史
      sourceKey: '$assetId:$dayKey:$source',
      rawPayload: jsonEncode({
        'price': priceInAssetCcy.toString(),
        'marketValue': market.toString(),
        'currency': asset.currency,
        'source': source,
      }),
      createdAt: now,
    );

    // 将资产价格写回与审计日志写入包裹在同一事务中，保证两者原子性：
    // 任意一步失败均回滚，避免资产价格已更新但历史快照缺失的不一致状态。
    Result<Asset, AppError>? savedResult;
    Result<AssetPriceHistoryPoint, AppError>? recordedResult;
    try {
      await _tx<void>(() async {
        savedResult = await _assets.update(updated);
        if (savedResult!.isErr) return;
        recordedResult = await _priceHistory.record(point);
        // 审计写失败必须 throw 以触发事务回滚，否则 asset price 落库但
        // price_history 快照缺失，违反注释声明的原子性约束。
        if (recordedResult!.isErr) {
          throw StorageError('record price history failed: ${recordedResult!.errorOrNull?.message}');
        }
      });
    } catch (e) {
      return Err(e is AppError ? e : StorageError('valuate failed: $e'));
    }

    final saved = savedResult;
    if (saved == null || saved.isErr) return Err(saved?.errorOrNull ?? StorageError('update failed'));
    final recorded = recordedResult;
    if (recorded != null && recorded.isErr) return Err(recorded.errorOrNull!);

    return Ok(saved.valueOrNull!);
  }
}
