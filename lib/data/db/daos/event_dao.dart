import 'package:drift/drift.dart';

import '../../../domain/entities/event_enums.dart';
import '../database.dart';
import '../tables/events.dart';

part 'event_dao.g.dart';

@DriftAccessor(tables: [Events])
class EventDao extends DatabaseAccessor<AppDatabase> with _$EventDaoMixin {
  EventDao(super.db);

  Stream<List<EventRow>> watchRecent({int limit = 100}) {
    return (select(events)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.triggerTime, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  Stream<List<EventRow>> watchByRelated(String model, String id) {
    return (select(events)
          ..where((t) =>
              t.relatedModel.equals(model) &
              t.relatedId.equals(id) &
              t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.triggerTime, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<EventRow>> watchPendingAck({int limit = 100}) {
    return (select(events)
          ..where((t) =>
              t.isDeleted.equals(false) &
              t.ackRequirement.equals('REQUIRED') &
              t.ackStatus.equals('PENDING'))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.triggerTime, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  Future<EventRow?> findBySourceKey(String key) {
    return (select(events)..where((t) => t.sourceKey.equals(key)))
        .getSingleOrNull();
  }

  Future<EventRow?> findById(String id) {
    return (select(events)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertRow(EventsCompanion row) async {
    await into(events).insert(row);
  }

  /// 幂等插入：若存在相同 sourceKey 的行则跳过 INSERT，返回现有行；
  /// 否则插入并返回新行。
  ///
  /// 通过 `InsertMode.insertOrIgnore` 让 SQLite 侧直接吃掉 UNIQUE 约束冲突，
  /// 避免应用层 check-then-insert 存在的 TOCTOU 竞态窗口。
  ///
  /// 语义兼容：sourceKey 为空字符串视同 null（不参与去重），与旧
  /// `DriftEventRepository.record()` 的行为保持一致。
  Future<EventRow> upsertBySourceKey(EventsCompanion row) async {
    final rawKey = row.sourceKey.present ? row.sourceKey.value : null;
    final effectiveKey = (rawKey == null || rawKey.isEmpty) ? null : rawKey;
    // 归一化：空串 → null，防止多个空串挤占唯一索引。
    final normalized = effectiveKey == null
        ? row.copyWith(sourceKey: const Value(null))
        : row;
    return transaction(() async {
      await into(events)
          .insert(normalized, mode: InsertMode.insertOrIgnore);
      if (effectiveKey != null) {
        return (select(events)..where((t) => t.sourceKey.equals(effectiveKey)))
            .getSingle();
      }
      return (select(events)..where((t) => t.id.equals(row.id.value)))
          .getSingle();
    });
  }

  Future<int> updateHandling({
    required String id,
    required String status,
    String? handler,
    String? note,
    required DateTime updatedAt,
  }) {
    return (update(events)..where((t) => t.id.equals(id))).write(
      EventsCompanion(
        handlingStatus: Value(status),
        handler: handler == null ? const Value.absent() : Value(handler),
        handlingNote: note == null ? const Value.absent() : Value(note),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  /// 设置 ack 终态（CONFIRMED / DISMISSED）。
  Future<int> updateAck({
    required String id,
    required String ackStatus,
    String? ackNote,
    required DateTime ackAt,
    required DateTime updatedAt,
  }) {
    return (update(events)..where((t) => t.id.equals(id))).write(
      EventsCompanion(
        ackStatus: Value(ackStatus),
        ackAt: Value(ackAt),
        ackNote: ackNote == null ? const Value.absent() : Value(ackNote),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  /// 原子版 updateAck：仅当事件支持 ack 且当前仍为 PENDING 时才更新。
  /// 通过 WHERE 条件把守卫合并进 SQL，消除应用层 TOCTOU 竞态。
  Future<int> updateAckIfApplicable({
    required String id,
    required String ackStatus,
    String? ackNote,
    required DateTime ackAt,
    required DateTime updatedAt,
  }) {
    return (update(events)
          ..where(
            (t) =>
                t.id.equals(id) &
                t.ackRequirement.equals(AckRequirement.notApplicable.code).not() &
                t.ackStatus.equals(AckStatus.pending.code),
          ))
        .write(
      EventsCompanion(
        ackStatus: Value(ackStatus),
        ackAt: Value(ackAt),
        ackNote: ackNote == null ? const Value.absent() : Value(ackNote),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<int> softDelete(String id, DateTime updatedAt) {
    return (update(events)..where((t) => t.id.equals(id))).write(
      EventsCompanion(isDeleted: const Value(true), updatedAt: Value(updatedAt)),
    );
  }
}
