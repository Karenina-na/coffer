import 'package:drift/drift.dart';

/// Event: 跨模型事件记录。
///
/// See doc/data-definitions.md §7.
/// `relatedModel` + `relatedId` 组成订阅键，连接 ACCOUNT / ASSET / CARD / CHANNEL。
/// v3 新增：幂等键 / 批次 / 截止 / 辅助关联 / 用户确认维度 / 软删除。
@DataClassName('EventRow')
class Events extends Table {
  TextColumn get id => text()();
  TextColumn get eventType => text().named('event_type')();
  TextColumn get relatedModel => text().named('related_model')();
  TextColumn get relatedId => text().named('related_id')();
  TextColumn get refs => text().nullable()(); // JSON: {role: "model:id"}
  TextColumn get batchId => text().named('batch_id').nullable()();
  TextColumn get sourceKey => text().named('source_key').nullable().unique()();
  DateTimeColumn get triggerTime => dateTime().named('trigger_time')();
  DateTimeColumn get dueAt => dateTime().named('due_at').nullable()();
  TextColumn get priority => text().nullable()();
  TextColumn get status => text()();
  TextColumn get handlingStatus =>
      text().named('handling_status').nullable()();
  TextColumn get handler => text().nullable()();
  TextColumn get handlingNote => text().named('handling_note').nullable()();
  TextColumn get ackRequirement => text()
      .named('ack_requirement')
      .withDefault(const Constant('NOT_APPLICABLE'))();
  TextColumn get ackStatus => text()
      .named('ack_status')
      .withDefault(const Constant('PENDING'))();
  DateTimeColumn get ackAt => dateTime().named('ack_at').nullable()();
  TextColumn get ackNote => text().named('ack_note').nullable()();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
