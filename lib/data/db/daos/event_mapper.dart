import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/entities/domain_event.dart';
import '../../../domain/entities/event_enums.dart';
import '../database.dart';

class EventMapper {
  const EventMapper();

  DomainEvent toDomain(EventRow r) => DomainEvent(
        id: r.id,
        eventType: r.eventType,
        relatedModel: RelatedModel.fromCode(r.relatedModel),
        relatedId: r.relatedId,
        refs: _decodeRefs(r.refs),
        batchId: r.batchId,
        sourceKey: r.sourceKey,
        triggerTime: r.triggerTime,
        dueAt: r.dueAt,
        priority: EventPriority.fromCodeOrNull(r.priority),
        status: EventStatus.fromCode(r.status),
        handlingStatus: HandlingStatus.fromCodeOrNull(r.handlingStatus),
        handler: r.handler,
        handlingNote: r.handlingNote,
        ackRequirement: AckRequirement.fromCode(r.ackRequirement),
        ackStatus: AckStatus.fromCode(r.ackStatus),
        ackAt: r.ackAt,
        ackNote: r.ackNote,
        isDeleted: r.isDeleted,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  EventsCompanion toInsert(DomainEvent e) => EventsCompanion.insert(
        id: e.id,
        eventType: e.eventType,
        relatedModel: e.relatedModel.code,
        relatedId: e.relatedId,
        refs: _val(_encodeRefs(e.refs)),
        batchId: _val(e.batchId),
        sourceKey: _val(e.sourceKey),
        triggerTime: e.triggerTime,
        dueAt: _val(e.dueAt),
        priority: _val(e.priority?.code),
        status: e.status.code,
        handlingStatus: _val(e.handlingStatus?.code),
        handler: _val(e.handler),
        handlingNote: _val(e.handlingNote),
        ackRequirement: Value(e.ackRequirement.code),
        ackStatus: Value(e.ackStatus.code),
        ackAt: _val(e.ackAt),
        ackNote: _val(e.ackNote),
        isDeleted: Value(e.isDeleted),
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  static String? _encodeRefs(Map<String, String>? refs) {
    if (refs == null || refs.isEmpty) return null;
    return jsonEncode(refs);
  }

  static Map<String, String>? _decodeRefs(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw);
      if (m is Map) return m.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (e) {
      // 行损坏不能阻塞读流程，但日志不应回显原始 payload。
      if (kDebugMode) {
        debugPrint('[event_mapper] failed to decode refs: ${e.runtimeType}');
      }
    }
    return null;
  }
}

Value<T> _val<T>(T? v) => v == null ? const Value.absent() : Value(v);
