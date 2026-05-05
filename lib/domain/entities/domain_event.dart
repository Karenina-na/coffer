import 'package:freezed_annotation/freezed_annotation.dart';

import 'event_enums.dart';

part 'domain_event.freezed.dart';

/// 持久化事件记录，字段对齐 doc/data-definitions.md §7。
@freezed
abstract class DomainEvent with _$DomainEvent {
  const factory DomainEvent({
    required String id,
    required String eventType,
    required RelatedModel relatedModel,
    required String relatedId,
    required DateTime triggerTime,
    EventPriority? priority,
    required EventStatus status,
    HandlingStatus? handlingStatus,
    String? handler,
    String? handlingNote,
    // —— 幂等与聚合 ——
    /// 幂等键；形如 `{eventType}:{relatedId}:{yyyymmdd}:{source}`。
    /// 写入前调用方应先查重，存在则跳过。
    String? sourceKey,

    /// 批次 ID：一次同步 / 导入产生的多个事件共享同一 batch，UI 可折叠。
    String? batchId,

    /// 截止时间：REQUIRED 类事件需要在此之前被确认（到期 / 还款）。
    DateTime? dueAt,

    /// 辅助关联；主关联在 [relatedId]，这里放 role → (model, id)。
    Map<String, String>? refs,

    // —— 用户确认维度（与 handling_status 正交）——
    @Default(AckRequirement.notApplicable) AckRequirement ackRequirement,
    @Default(AckStatus.pending) AckStatus ackStatus,
    DateTime? ackAt,
    String? ackNote,

    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DomainEvent;
}
