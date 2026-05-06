import '../../core/errors.dart';
import '../../core/result.dart';
import '../../domain/entities/domain_event.dart';
import '../../domain/entities/event_enums.dart';
import '../../domain/repositories/event_repository.dart';
import '../db/daos/event_dao.dart';
import '../db/daos/event_mapper.dart';

class DriftEventRepository implements EventRepository {
  DriftEventRepository(
    this._dao, {
    EventMapper mapper = const EventMapper(),
    DateTime Function()? now,
  })  : _mapper = mapper,
        _now = now ?? DateTime.now;

  final EventDao _dao;
  final EventMapper _mapper;
  final DateTime Function() _now;

  @override
  Stream<List<DomainEvent>> watchRecent({int limit = 100}) =>
      _dao.watchRecent(limit: limit).map(
          (rows) => rows.map(_mapper.toDomain).toList(growable: false));

  @override
  Stream<List<DomainEvent>> watchByRelated({
    required RelatedModel model,
    required String id,
  }) =>
      _dao.watchByRelated(model.code, id).map(
          (rows) => rows.map(_mapper.toDomain).toList(growable: false));

  @override
  Stream<List<DomainEvent>> watchPendingAck({int limit = 100}) =>
      _dao.watchPendingAck(limit: limit).map(
          (rows) => rows.map(_mapper.toDomain).toList(growable: false));

  @override
  Future<Result<DomainEvent, AppError>> record(DomainEvent event) async {
    try {
      // DAO 侧通过 INSERT OR IGNORE + 读回实现原子幂等，避免应用层
      // check-then-insert 的 TOCTOU 竞态。
      final saved = await _dao.upsertBySourceKey(_mapper.toInsert(event));
      return Ok(_mapper.toDomain(saved));
    } catch (e) {
      return Err(StorageError('record failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> updateHandling({
    required String id,
    required HandlingStatus status,
    String? handler,
    String? note,
  }) async {
    try {
      final n = await _dao.updateHandling(
        id: id,
        status: status.code,
        handler: handler,
        note: note,
        updatedAt: _now(),
      );
      if (n == 0) return Err(NotFoundError('event not found: $id'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('updateHandling failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> updateAck({
    required String id,
    required AckStatus ackStatus,
    String? note,
  }) async {
    if (ackStatus == AckStatus.pending) {
      return const Err(
        ValidationError('ackStatus 只能是 CONFIRMED 或 DISMISSED'),
      );
    }
    try {
      final now = _now();
      // 将 NOT_APPLICABLE 检查合并到单条 UPDATE 的 WHERE 条件中，
      // 消除 findById + update 的 TOCTOU 竞态窗口。
      final n = await _dao.updateAckIfApplicable(
        id: id,
        ackStatus: ackStatus.code,
        ackNote: note,
        ackAt: now,
        updatedAt: now,
      );
      if (n == 0) {
        // 行不存在 / 不支持 ack / 已进入终态 → 查一下原因
        final existing = await _dao.findById(id);
        if (existing == null) {
          return Err(NotFoundError('event not found: $id'));
        }
        if (existing.ackRequirement == AckRequirement.notApplicable.code) {
          return const Err(ValidationError('NOT_APPLICABLE 事件不支持 ack'));
        }
        return const Err(ValidationError('事件 ack 已进入终态，不可重复修改'));
      }
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('updateAck failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> softDelete(String id) async {
    try {
      final n = await _dao.softDelete(id, _now());
      if (n == 0) return Err(NotFoundError('event not found: $id'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('softDelete failed: $e'));
    }
  }
}
