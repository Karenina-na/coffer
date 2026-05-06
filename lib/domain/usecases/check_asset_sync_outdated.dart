import 'dart:convert';

import '../../core/date_utils.dart';
import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset.dart';
import '../entities/domain_event.dart';
import '../entities/event_enums.dart';
import '../events/event_bus.dart';
import '../repositories/asset_repository.dart';
import '../repositories/event_repository.dart';

/// 扫描活跃资产的 `valuationTime`，当天若存在超过 [thresholdDays] 未同步的
/// 资产，聚合写入一条 `ASSET_SYNC_OUTDATED` 事件。
///
/// 设计动机（方案 B）：
/// - 同步成功不再每资产写一条事件，避免淹没真告警；
/// - 但我们仍需要提醒用户「今天某些资产没同步」；
/// - 所以改为每天一条聚合事件：priority=MEDIUM、handlingStatus=UNHANDLED、
///   ackRequirement=OPTIONAL；
/// - sourceKey 形如 `ASSET_SYNC_OUTDATED:{yyyymmdd-UTC}`，天然幂等。
class CheckAssetSyncOutdatedUseCase {
  CheckAssetSyncOutdatedUseCase({
    required AssetRepository assets,
    required EventRepository events,
    required DomainEventBus bus,
    required String Function() idGenerator,
    required DateTime Function() now,
    Duration thresholdDays = const Duration(days: 3),
  })  : _assets = assets,
        _events = events,
        _bus = bus,
        _idGen = idGenerator,
        _now = now,
        _threshold = thresholdDays;

  final AssetRepository _assets;
  final EventRepository _events;
  final DomainEventBus _bus;
  final String Function() _idGen;
  final DateTime Function() _now;
  final Duration _threshold;

  /// 返回新写入的 outdated 资产数量；若全部已同步 / 同日已写过事件返回 0。
  Future<Result<int, AppError>> call() async {
    final now = _now();
    final cutoff = now.subtract(_threshold);
    late final List<Asset> list;
    try {
      list = await _assets.watchAll().first;
    } catch (e) {
      return Err(StorageError('读取资产列表失败: $e'));
    }
    final outdated = <Map<String, String>>[];
    for (final a in list) {
      if (a.isDeleted) continue;
      final t = a.valuationTime;
      if (t == null || t.isBefore(cutoff)) {
        outdated.add({
          'assetId': a.id,
          'accountId': a.accountId,
          'lastValuationTime': t?.toIso8601String() ?? '',
        });
      }
    }
    if (outdated.isEmpty) return const Ok(0);

    // 排序后取 first，确保同样的 outdated 集合总是指向同一资产（幂等）。
    outdated.sort((a, b) => a['assetId']!.compareTo(b['assetId']!));

    final dayKey = utcDayKey(now);
    final event = DomainEvent(
      id: _idGen(),
      eventType: DomainEventTypes.assetSyncOutdated,
      relatedModel: RelatedModel.asset,
      // 聚合事件，主关联指向第一个资产以便 UI 兜底跳转；明细见 handlingNote
      relatedId: outdated.first['assetId']!,
      triggerTime: now,
      priority: EventPriority.medium,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.unhandled,
      sourceKey: '${DomainEventTypes.assetSyncOutdated}:$dayKey',
      ackRequirement: AckRequirement.optional,
      handlingNote: jsonEncode({
        'thresholdDays': _threshold.inDays,
        'count': outdated.length,
        'assets': outdated,
      }),
      createdAt: now,
      updatedAt: now,
    );
    final rec = await _events.record(event);
    if (rec.isErr) return Err(rec.errorOrNull!);
    _bus.emit(rec.valueOrNull!);
    return Ok(outdated.length);
  }
}
