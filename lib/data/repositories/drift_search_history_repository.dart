import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/search_history_repository.dart';
import '../db/daos/search_history_dao.dart';
import 'search_history_protector.dart';

class DriftSearchHistoryRepository implements SearchHistoryRepository {
  DriftSearchHistoryRepository(this._dao, {SearchHistoryProtector? protector})
    : _protector = protector ?? SearchHistoryProtector();

  final SearchHistoryDao _dao;
  final SearchHistoryProtector _protector;

  @override
  Future<void> migrateLegacyHistoryIfNeeded() async {
    final existingQueries = await listQueries(limit: 1);
    final existingVisits = await listVisits(limit: 1);
    if (existingQueries.isNotEmpty || existingVisits.isNotEmpty) return;

    final dir = await getApplicationDocumentsDirectory();
    final candidates = [
      File(p.join(dir.path, 'search_history.dat')),
      File(p.join(dir.path, 'search_history.json')),
    ];

    for (final file in candidates) {
      if (!await file.exists()) continue;
      try {
        final txt = await file.readAsString();
        final decoded = await _decodeLegacyPayload(txt);
        if (decoded == null) continue;

        final queries = (decoded['queries'] as List? ?? const [])
            .whereType<String>()
            .toList(growable: false);
        final visits = (decoded['visits'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => _legacyVisitFromJson(m.cast<String, dynamic>()))
            .whereType<SearchHistoryVisitRecord>()
            .toList(growable: false);

        for (final query in queries.reversed) {
          final trimmed = query.trim();
          if (trimmed.isEmpty || trimmed.startsWith('>')) continue;
          await upsertQuery(
            query: trimmed,
            normalized: trimmed.toLowerCase(),
            now: DateTime.now(),
          );
        }
        for (final visit in visits.reversed) {
          await upsertVisit(
            feature: visit.feature,
            targetId: visit.targetId,
            label: visit.label,
            sublabel: visit.sublabel,
            visitedAt: visit.visitedAt,
          );
        }
        await file.delete();
        return;
      } catch (_) {
        // Try the next legacy candidate.
      }
    }
  }

  @override
  Future<List<String>> listQueries({int limit = 8}) async {
    final rows = await _dao.listQueries(limit: limit);
    return rows.map((r) => r.query).whereType<String>().toList(growable: false);
  }

  @override
  Future<List<SearchHistoryVisitRecord>> listVisits({int limit = 10}) async {
    final rows = await _dao.listVisits(limit: limit);
    return rows
        .where(
          (r) => r.feature != null && r.targetId != null && r.label != null,
        )
        .map(
          (r) => SearchHistoryVisitRecord(
            feature: r.feature!,
            targetId: r.targetId!,
            label: r.label!,
            sublabel: r.sublabel,
            visitedAt: r.visitedAt,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> upsertQuery({
    required String query,
    required String normalized,
    required DateTime now,
  }) {
    return _dao.upsertQuery(query: query, normalized: normalized, now: now);
  }

  @override
  Future<void> upsertVisit({
    required String feature,
    required String targetId,
    required String label,
    String? sublabel,
    required DateTime visitedAt,
  }) {
    return _dao.upsertVisit(
      feature: feature,
      targetId: targetId,
      label: label,
      sublabel: sublabel,
      visitedAt: visitedAt,
    );
  }

  @override
  Future<void> clearQueries() {
    return _dao.clearQueries();
  }

  Future<Map<String, dynamic>?> _decodeLegacyPayload(String txt) async {
    final encrypted = await _protector.decode(txt);
    if (encrypted != null) return encrypted;
    try {
      final decoded = jsonDecode(txt);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  SearchHistoryVisitRecord? _legacyVisitFromJson(Map<String, dynamic> json) {
    try {
      return SearchHistoryVisitRecord(
        feature: json['feature'] as String,
        targetId: json['targetId'] as String,
        label: json['label'] as String,
        sublabel: json['sublabel'] as String?,
        visitedAt: DateTime.parse(json['visitedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}
