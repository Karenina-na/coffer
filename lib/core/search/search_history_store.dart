import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 一条历史访问项：搜索命中后被点开的实体快照。
///
/// 仅存展示相关的字段（label / sublabel / 跳转目标 id 与 feature）；
/// 恢复后用 id + feature 重新定位到最新实体（避免陈旧副本）。
class SearchVisit {
  const SearchVisit({
    required this.feature,
    required this.targetId,
    required this.label,
    this.sublabel,
    required this.visitedAt,
  });

  /// 同一 feature + id 视为同一访问。
  final String feature; // SearchFeature.name
  final String targetId;
  final String label;
  final String? sublabel;
  final DateTime visitedAt;

  Map<String, dynamic> toJson() => {
        'feature': feature,
        'targetId': targetId,
        'label': label,
        if (sublabel != null) 'sublabel': sublabel,
        'visitedAt': visitedAt.toIso8601String(),
      };

  static SearchVisit? fromJson(Map<String, dynamic> j) {
    try {
      return SearchVisit(
        feature: j['feature'] as String,
        targetId: j['targetId'] as String,
        label: j['label'] as String,
        sublabel: j['sublabel'] as String?,
        visitedAt: DateTime.parse(j['visitedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

class SearchHistory {
  const SearchHistory({
    this.queries = const [],
    this.visits = const [],
    this.loaded = false,
  });

  final List<String> queries; // 最近在前
  final List<SearchVisit> visits; // 最近在前
  final bool loaded;

  SearchHistory copyWith({
    List<String>? queries,
    List<SearchVisit>? visits,
    bool? loaded,
  }) =>
      SearchHistory(
        queries: queries ?? this.queries,
        visits: visits ?? this.visits,
        loaded: loaded ?? this.loaded,
      );
}

const int _kMaxQueries = 8;
const int _kMaxVisits = 10;

/// 跨会话持久化的搜索历史（最近查询 + 最近访问）。
///
/// 落地：应用 Documents 目录下的 `search_history.json`；非敏感数据，
/// 与 SQLCipher 主库分离，避免牵涉 schema 迁移。
class SearchHistoryNotifier extends Notifier<SearchHistory> {
  File? _file;

  @override
  SearchHistory build() {
    // fire-and-forget：加载完成后刷新 state。
    unawaited(_load());
    return const SearchHistory();
  }

  Future<File> _resolveFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'search_history.json'));
  }

  Future<void> _load() async {
    try {
      _file ??= await _resolveFile();
      if (!await _file!.exists()) {
        state = state.copyWith(loaded: true);
        return;
      }
      final txt = await _file!.readAsString();
      final decoded = jsonDecode(txt);
      if (decoded is! Map<String, dynamic>) {
        if (kDebugMode) debugPrint('SearchHistory load failed: unexpected JSON root type');
        state = state.copyWith(loaded: true);
        return;
      }
      final j = decoded;
      final qs = (j['queries'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false);
      final vs = (j['visits'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => SearchVisit.fromJson(m.cast<String, dynamic>()))
          .whereType<SearchVisit>()
          .toList(growable: false);
      state = SearchHistory(queries: qs, visits: vs, loaded: true);
    } catch (e) {
      if (kDebugMode) debugPrint('SearchHistory load failed: $e');
      state = state.copyWith(loaded: true);
    }
  }

  Future<void> _persist() async {
    try {
      _file ??= await _resolveFile();
      final j = {
        'queries': state.queries,
        'visits': state.visits.map((v) => v.toJson()).toList(),
      };
      await _file!.writeAsString(jsonEncode(j), flush: false);
    } catch (e) {
      if (kDebugMode) debugPrint('SearchHistory persist failed: $e');
    }
  }

  void recordQuery(String raw) {
    final q = raw.trim();
    if (q.isEmpty || q.startsWith('>')) return;
    final cur = List<String>.from(state.queries)
      ..removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    cur.insert(0, q);
    if (cur.length > _kMaxQueries) cur.removeRange(_kMaxQueries, cur.length);
    state = state.copyWith(queries: cur);
    unawaited(_persist());
  }

  void recordVisit(SearchVisit v) {
    final cur = List<SearchVisit>.from(state.visits)
      ..removeWhere(
          (e) => e.feature == v.feature && e.targetId == v.targetId);
    cur.insert(0, v);
    if (cur.length > _kMaxVisits) cur.removeRange(_kMaxVisits, cur.length);
    state = state.copyWith(visits: cur);
    unawaited(_persist());
  }

  void clearQueries() {
    state = state.copyWith(queries: const []);
    unawaited(_persist());
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, SearchHistory>(
  SearchHistoryNotifier.new,
);
