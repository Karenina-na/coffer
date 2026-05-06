import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/providers/account_providers.dart';
import '../crypto/field_cipher.dart';
import '../crypto/key_derivation.dart';
import '../crypto/secure_key_store.dart';

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

class SearchHistoryProtector {
  SearchHistoryProtector({
    SecureKeyStore? keyStore,
    KeyDerivation? keyDerivation,
    FieldCipher? fieldCipher,
    Future<SecretKey> Function()? masterKeyLoader,
  })  : _keyStore = keyStore ?? SecureKeyStore(),
        _kdf = keyDerivation ?? KeyDerivation(),
        _cipher = fieldCipher ?? FieldCipher(),
        _masterKeyLoader = masterKeyLoader;

  static const purpose = 'app.search_history';

  final SecureKeyStore _keyStore;
  final KeyDerivation _kdf;
  final FieldCipher _cipher;
  final Future<SecretKey> Function()? _masterKeyLoader;

  SecretKey? _derived;

  Future<SecretKey> _key() async {
    final cached = _derived;
    if (cached != null) return cached;
    final master = await (_masterKeyLoader?.call() ?? _keyStore.loadOrCreateMaster());
    final derived = await _kdf.derive(master: master, purpose: purpose);
    _derived = derived;
    return derived;
  }

  Future<String?> encode(Map<String, dynamic> payload) async {
    final key = await _key();
    final encoded = jsonEncode(payload);
    final result = await _cipher.encryptString(encoded, key);
    return result.valueOrNull;
  }

  Future<Map<String, dynamic>?> decode(String ciphertext) async {
    final key = await _key();
    final result = await _cipher.decryptString(ciphertext, key);
    final plain = result.valueOrNull;
    if (plain == null) return null;
    final decoded = jsonDecode(plain);
    return decoded is Map<String, dynamic> ? decoded : null;
  }
}

/// 跨会话持久化的搜索历史（最近查询 + 最近访问）。
///
/// 落地：应用 Documents 目录下的 `search_history.dat`；内容用主密钥派生子密钥
/// 做 AES-GCM 加密，避免暴露访问轨迹与搜索词。
class SearchHistoryNotifier extends Notifier<SearchHistory> {
  File? _file;
  final SearchHistoryProtector _protector = SearchHistoryProtector();

  @override
  SearchHistory build() {
    // fire-and-forget：加载完成后刷新 state。
    unawaited(_load());
    return const SearchHistory();
  }

  Future<File> _resolveFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'search_history.dat'));
  }

  Future<File> _resolveLegacyJsonFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'search_history.json'));
  }

  Map<String, dynamic>? _decodePlainJson(String txt) {
    try {
      final decoded = jsonDecode(txt);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _migrateLegacyFileIfNeeded() async {
    final dao = ref.read(appDatabaseProvider).searchHistoryDao;
    final existingQueries = await dao.listQueries(limit: 1);
    final existingVisits = await dao.listVisits(limit: 1);
    if (existingQueries.isNotEmpty || existingVisits.isNotEmpty) return;

    _file ??= await _resolveFile();
    final legacyJson = await _resolveLegacyJsonFile();
    final candidates = <File>[_file!, legacyJson];
    for (final file in candidates) {
      if (!await file.exists()) continue;
      try {
        final txt = await file.readAsString();
        Map<String, dynamic>? decoded = await _protector.decode(txt);
        decoded ??= _decodePlainJson(txt);
        if (decoded == null) continue;

        final qs = (decoded['queries'] as List? ?? const [])
            .whereType<String>()
            .toList(growable: false);
        final vs = (decoded['visits'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => SearchVisit.fromJson(m.cast<String, dynamic>()))
            .whereType<SearchVisit>()
            .toList(growable: false);

        for (final q in qs.reversed) {
          final trimmed = q.trim();
          if (trimmed.isEmpty || trimmed.startsWith('>')) continue;
          await dao.upsertQuery(
            query: trimmed,
            normalized: trimmed.toLowerCase(),
            now: DateTime.now(),
          );
        }
        for (final v in vs.reversed) {
          await dao.upsertVisit(
            feature: v.feature,
            targetId: v.targetId,
            label: v.label,
            sublabel: v.sublabel,
            visitedAt: v.visitedAt,
          );
        }
        await file.delete();
        return;
      } catch (_) {
        // Try next legacy format.
      }
    }
  }

  Future<void> _load() async {
    try {
      await _migrateLegacyFileIfNeeded();
      final dao = ref.read(appDatabaseProvider).searchHistoryDao;
      final queryRows = await dao.listQueries(limit: _kMaxQueries);
      final visitRows = await dao.listVisits(limit: _kMaxVisits);
      final qs = queryRows
          .map((r) => r.query)
          .whereType<String>()
          .toList(growable: false);
      final vs = visitRows
          .where((r) => r.feature != null && r.targetId != null && r.label != null)
          .map((r) => SearchVisit(
                feature: r.feature!,
                targetId: r.targetId!,
                label: r.label!,
                sublabel: r.sublabel,
                visitedAt: r.visitedAt,
              ))
          .toList(growable: false);
      state = SearchHistory(queries: qs, visits: vs, loaded: true);
    } catch (e) {
      if (kDebugMode) debugPrint('SearchHistory load failed: $e');
      state = state.copyWith(loaded: true);
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
    final dao = ref.read(appDatabaseProvider).searchHistoryDao;
    unawaited(dao.upsertQuery(
      query: q,
      normalized: q.toLowerCase(),
      now: DateTime.now(),
    ));
  }

  void recordVisit(SearchVisit v) {
    final cur = List<SearchVisit>.from(state.visits)
      ..removeWhere(
          (e) => e.feature == v.feature && e.targetId == v.targetId);
    cur.insert(0, v);
    if (cur.length > _kMaxVisits) cur.removeRange(_kMaxVisits, cur.length);
    state = state.copyWith(visits: cur);
    final dao = ref.read(appDatabaseProvider).searchHistoryDao;
    unawaited(dao.upsertVisit(
      feature: v.feature,
      targetId: v.targetId,
      label: v.label,
      sublabel: v.sublabel,
      visitedAt: v.visitedAt,
    ));
  }

  void clearQueries() {
    state = state.copyWith(queries: const []);
    final dao = ref.read(appDatabaseProvider).searchHistoryDao;
    unawaited(dao.clearQueries());
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, SearchHistory>(
  SearchHistoryNotifier.new,
);
