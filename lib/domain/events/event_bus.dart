import 'dart:async';

import '../entities/domain_event.dart';
import '../entities/event_enums.dart';

/// 进程内领域事件总线。
///
/// 语义：
/// - 非持久化；订阅后只能收到之后发出的事件
/// - 与 [EventRepository] 配合时，应先 `repo.record()` 再 `bus.emit()`，
///   避免订阅方在持久化失败时仍然收到事件
/// - 订阅键使用 `relatedModel + relatedId`，与数据表定义一致
class DomainEventBus {
  DomainEventBus() : _controller = StreamController<DomainEvent>.broadcast();

  final StreamController<DomainEvent> _controller;

  Stream<DomainEvent> get all => _controller.stream;

  Stream<DomainEvent> ofType(String eventType) =>
      _controller.stream.where((e) => e.eventType == eventType);

  Stream<DomainEvent> forRelated(RelatedModel model, String id) =>
      _controller.stream.where(
        (e) => e.relatedModel == model && e.relatedId == id,
      );

  void emit(DomainEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  Future<void> dispose() => _controller.close();
}

/// 固定事件类型常量。
abstract final class DomainEventTypes {
  /// 资产价格更新（保留作为通用价格变动通知，当前未被写入）。
  static const assetPriceUpdated = 'ASSET_PRICE_UPDATED';
  static const exchangeRateIngested = 'EXCHANGE_RATE_INGESTED';

  /// 资产估值失败：行情 API 取数失败、汇率缺失等。
  /// 由同步层写入，priority=HIGH，handlingStatus=FAILED，ackRequirement=OPTIONAL。
  static const assetValuationFailed = 'ASSET_VALUATION_FAILED';

  /// 资产同步过期聚合提醒：按天一条，列出超过阈值未同步的资产。
  /// priority=MEDIUM，handlingStatus=UNHANDLED，ackRequirement=OPTIONAL，
  /// sourceKey 形如 `ASSET_SYNC_OUTDATED:{yyyymmdd}`。
  static const assetSyncOutdated = 'ASSET_SYNC_OUTDATED';

  /// 汇率预警：关注币对的最新值穿越了用户设置的阈值（上沿/下沿）或
  /// 近两天波动超过百分比阈值。priority=MEDIUM，ackRequirement=OPTIONAL。
  /// sourceKey 形如 `RATE_ALERT:{pairKey}:{yyyymmdd}:{kind}`，kind ∈
  /// `high|low|change`，保证同一币对同一天同一维度只记一条。
  static const rateAlert = 'RATE_ALERT';
}
