import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/domain_event.dart';
import '../entities/event_enums.dart';

abstract interface class EventRepository {
  Stream<List<DomainEvent>> watchRecent({int limit = 100});

  Stream<List<DomainEvent>> watchByRelated({
    required RelatedModel model,
    required String id,
  });

  /// 订阅所有「待用户确认」的事件（REQUIRED + PENDING，未软删除）。
  Stream<List<DomainEvent>> watchPendingAck({int limit = 100});

  /// 持久化一条事件。若 [DomainEvent.sourceKey] 不为空且数据库已存在相同
  /// `source_key` 的记录，返回 `Ok(existing)` 并不重复写入。
  Future<Result<DomainEvent, AppError>> record(DomainEvent event);

  Future<Result<void, AppError>> updateHandling({
    required String id,
    required HandlingStatus status,
    String? handler,
    String? note,
  });

  /// 用户侧确认或忽略。`ackStatus` 只能是 CONFIRMED 或 DISMISSED。
  Future<Result<void, AppError>> updateAck({
    required String id,
    required AckStatus ackStatus,
    String? note,
  });

  /// 软删除一条事件（从列表中隐藏）。
  Future<Result<void, AppError>> softDelete(String id);
}
