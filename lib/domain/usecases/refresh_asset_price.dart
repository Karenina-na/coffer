import 'dart:convert';

import 'package:decimal/decimal.dart';

import '../../core/date_utils.dart';
import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset.dart';
import '../entities/asset_price_history_point.dart';
import '../entities/domain_event.dart';
import '../entities/event_enums.dart';
import '../events/event_bus.dart';
import '../repositories/asset_price_history_repository.dart';
import '../repositories/asset_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/exchange_rate_repository.dart';
import '../utils/pair_key.dart';
import '../valuation/asset_valuator.dart';
import 'valuate_asset.dart';

/// 批量刷新资产的结果。
class RefreshAssetsResult {
  const RefreshAssetsResult({
    required this.success,
    required this.failed,
  });

  /// 成功刷新的资产 ID 列表。
  final List<String> success;

  /// 失败项：资产 ID → 错误信息。
  final Map<String, String> failed;
}

/// 通过 [AssetValuator] 估值并刷新资产当前价 / 补录历史估值快照的协调器。
///
/// [AssetValuator] 由 Riverpod 层注入，通常是
/// [AssetValuationRouter]（根据资产类别路由到行情、固收、手动等策略）。
///
/// 三种用法：
/// - [refreshLatest]：策略给出最新价 → 通过 [PriceProvider] 换算为资产本币 →
///   走 [ValuateAssetUseCase] 更新 asset.currentPrice 并写估值快照。
///   **始终强制从 API 拉取（`forceRefresh = true`），确保 API 数据为准。**
/// - [refreshHistory]：策略给出 [from,to] 日频序列 → 逐点写
///   `asset_price_history`。**同样始终强制从 API 拉取。**
/// - [refreshAll]：批量刷新全部或指定资产列表的最新价，返回汇总结果。
///
/// 成功估值只写 `asset_price_history`；失败才写 `events`
/// （`ASSET_VALUATION_FAILED`，HIGH / FAILED / OPTIONAL ack），避免
/// 同步事件刷屏淹没真告警。
class RefreshAssetPriceUseCase {
  RefreshAssetPriceUseCase({
    required AssetRepository assets,
    required EventRepository events,
    required AssetPriceHistoryRepository priceHistory,
    required DomainEventBus bus,
    required PriceProvider fxRates,
    required AssetValuator valuator,
    required ValuateAssetUseCase valuate,
    required String Function() idGenerator,
    required DateTime Function() now,
    ExchangeRateRepository? fxRateRepository,
  })  : _assets = assets,
        _events = events,
        _priceHistory = priceHistory,
        _bus = bus,
        _fx = fxRates,
        _fxRepo = fxRateRepository,
        _valuator = valuator,
        _valuate = valuate,
        _idGen = idGenerator,
        _now = now;

  final AssetRepository _assets;
  final EventRepository _events;
  final AssetPriceHistoryRepository _priceHistory;
  final DomainEventBus _bus;
  final PriceProvider _fx;
  final ExchangeRateRepository? _fxRepo;
  final AssetValuator _valuator;
  final ValuateAssetUseCase _valuate;
  final String Function() _idGen;
  final DateTime Function() _now;

  /// 刷新单资产最新价并更新估值。
  ///
  /// [forceRefresh] 为 `true` 时绕过 `MarketQuoteValuator` 进程内缓存；默认走
  /// TTL 缓存，以遵循批量同步的限流约束。
  Future<Result<Asset, AppError>> refreshLatest(
    String assetId, {
    bool forceRefresh = false,
  }) async {
    final found = await _assets.findById(assetId);
    if (found.isErr) return Err(found.errorOrNull!);
    final asset = found.valueOrNull!;

    final quoteRes = await _valuator.valueNow(asset, forceRefresh: forceRefresh);
    if (quoteRes.isErr) {
      final err = quoteRes.errorOrNull!;
      await _recordFailure(
        asset: asset,
        stage: 'latest',
        source: 'unknown',
        error: err.message,
      );
      return Err(err);
    }
    final quote = quoteRes.valueOrNull!;

    final res = await _valuate.call(
      assetId: assetId,
      newPrice: quote.price,
      priceCurrency: quote.currency,
      source: quote.source,
    );
    if (res.isErr) {
      await _recordFailure(
        asset: asset,
        stage: 'latest',
        source: quote.source,
        error: res.errorOrNull!.message,
      );
    }
    return res;
  }

  /// 批量刷新资产最新价。
  ///
  /// 若 [assetIds] 为空，则读取全部活跃资产进行刷新。
  /// [mode] 控制增量（仅最新价）或全量（先补历史序列再刷新最新价）。
  Future<Result<RefreshAssetsResult, AppError>> refreshAll({
    List<String>? assetIds,
    SyncMode mode = SyncMode.incremental,
  }) async {
    final ids = assetIds;
    List<Asset> targets = [];
    final failed = <String, String>{};
    if (ids == null || ids.isEmpty) {
      try {
        final all = await _assets.watchAll().first;
        targets = all;
      } catch (e) {
        return Err(StorageError('读取资产列表失败: $e'));
      }
    } else {
      final results = await _assets.findByIds(ids);
      for (var i = 0; i < ids.length; i++) {
        results[i].when(ok: (a) => targets.add(a), err: (e) => failed[ids[i]] = e.message);
      }
    }

    if (targets.isEmpty) {
      return const Ok(RefreshAssetsResult(success: [], failed: {}));
    }

    final success = <String>[];

    for (final asset in targets) {
      if (mode == SyncMode.full) {
        final now = _now();
        final to = DateTime(now.year, now.month, now.day);
        final from = to.subtract(const Duration(days: 30));
        final hist = await refreshHistory(
          assetId: asset.id,
          from: from,
          to: to,
        );
        if (hist.isErr) {
          // 历史拉取失败则跳过 latest，避免随后的成功把它洗进 success
          // 而用户看到的实际历史数据缺失。
          failed[asset.id] = hist.errorOrNull!.message;
          continue;
        }
      }
      final r = await refreshLatest(asset.id);
      r.when(
        ok: (_) => success.add(asset.id),
        err: (e) => failed[asset.id] = e.message,
      );
    }

    return Ok(RefreshAssetsResult(success: success, failed: failed));
  }

  /// 批量补录历史估值事件。返回成功写入的事件数。
  ///
  /// [forceRefresh] 为 `true` 时绕过历史序列缓存；默认走 TTL 缓存。
  Future<Result<int, AppError>> refreshHistory({
    required String assetId,
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    if (from.isAfter(to)) {
      return const Err(ValidationError('from 不能晚于 to'));
    }
    final found = await _assets.findById(assetId);
    if (found.isErr) return Err(found.errorOrNull!);
    final asset = found.valueOrNull!;

    final seriesRes = await _valuator.valueHistory(
      asset,
      from: from,
      to: to,
      forceRefresh: forceRefresh,
    );
    if (seriesRes.isErr) {
      final err = seriesRes.errorOrNull!;
      await _recordFailure(
        asset: asset,
        stage: 'history',
        source: 'unknown',
        error: err.message,
      );
      return Err(err);
    }
    final series = seriesRes.valueOrNull!;

    // 需要时获取汇率（资产币种 != 报价币种）
    final needsFx = series.currency.toUpperCase() != asset.currency.toUpperCase() &&
        series.points.isNotEmpty;

    // spot rate 作为回退（仅在 _fxRepo 查不到历史点时使用）
    Decimal? spotFxRate;
    if (needsFx) {
      final r = await _fx.getRate(
        baseCurrency: series.currency,
        quoteCurrency: asset.currency,
      );
      if (r.isErr) {
        final err = r.errorOrNull!;
        await _recordFailure(
          asset: asset,
          stage: 'history',
          source: series.source,
          error: err.message,
        );
        return Err(err);
      }
      spotFxRate = r.valueOrNull!;
    }

    var written = 0;
    final batchId = _idGen();

    // 批量预取全部历史汇率，避免逐点 N+1 查询。
    final fxRateMap = <String, Decimal>{};
    if (needsFx && _fxRepo != null) {
      try {
        final pairKey = pairKeyOf(series.currency, asset.currency);
        final allRates = await _fxRepo.querySeriesForPair(
          pairKey: pairKey,
          since: from,
        );
        for (final r in allRates) {
          fxRateMap[utcDayKey(r.asOfTime)] = r.rate;
        }
      } catch (_) {
        // 批量查询失败时退回到逐点 spot rate，不阻塞写入。
      }
    }

    // 采用容错写入：单点失败不中断整批，避免因中途失败导致
    // 已写点被 sourceKey 去重锁死而形成永久空洞。
    // 若全部点均写入失败，则返回最后一次错误。
    AppError? lastErr;
    for (final p in series.points) {
      // 逐点使用历史汇率：优先从预取缓存取值，查不到则降级到 spot rate。
      Decimal? fxRate;
      if (needsFx) {
        final dayKey = utcDayKey(p.t);
        fxRate = fxRateMap[dayKey] ?? spotFxRate;
      }
      final priceInAssetCcy = fxRate == null ? p.price : p.price * fxRate;
      final marketValue = asset.quantity * priceInAssetCcy;
      final dayKey = utcDayKey(p.t);
      final point = AssetPriceHistoryPoint(
        id: _idGen(),
        assetId: assetId,
        price: priceInAssetCcy,
        marketValue: marketValue,
        currency: asset.currency,
        source: series.source,
        batchId: batchId,
        triggerTime: p.t,
        // 同资产同天同源只保留一条，反复 refreshHistory 不会重复写
        sourceKey: '$assetId:$dayKey:${series.source}',
        rawPayload: jsonEncode({
          'price': priceInAssetCcy.toString(),
          'marketValue': marketValue.toString(),
          'currency': asset.currency,
          'source': series.source,
          'symbol': series.symbol,
        }),
        createdAt: _now(),
      );
      final rec = await _priceHistory.record(point);
      if (rec.isErr) {
        lastErr = rec.errorOrNull!;
      } else {
        written++;
      }
    }
    // 全部写入失败才视为整体失败；部分成功则返回成功写入数。
    if (written == 0 && lastErr != null) return Err(lastErr);
    return Ok(written);
  }

  /// 写一条 `ASSET_VALUATION_FAILED` 事件。
  ///
  /// - `priority=HIGH` + `handlingStatus=FAILED`：会出现在事件页「失败」Tab
  /// - `ackRequirement=NOT_APPLICABLE`：不强制阻塞
  /// - `sourceKey` 同一资产同一天同一阶段只记一条，失败重试不会刷屏
  /// - `refs` 带上所属账户，便于 UI 从事件跳账户
  Future<void> _recordFailure({
    required Asset asset,
    required String stage,
    required String source,
    required String error,
  }) async {
    final now = _now();
    final dayKey = utcDayKey(now);
    final event = DomainEvent(
      id: _idGen(),
      eventType: DomainEventTypes.assetValuationFailed,
      relatedModel: RelatedModel.asset,
      relatedId: asset.id,
      triggerTime: now,
      priority: EventPriority.high,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.failed,
      handler: source,
      sourceKey:
          '${DomainEventTypes.assetValuationFailed}:${asset.id}:$dayKey:$stage',
      refs: {'account': asset.accountId},
      ackRequirement: AckRequirement.notApplicable,
      handlingNote: jsonEncode({
        'stage': stage,
        'source': source,
        'error': error,
      }),
      createdAt: now,
      updatedAt: now,
    );
    try {
      final rec = await _events.record(event);
      rec.when(ok: _bus.emit, err: (_) {});
    } catch (_) {
      // Best-effort: event recording failure must not mask the real valuation error
    }
  }
}
