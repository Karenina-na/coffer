import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/region_meta.dart';
import '../../domain/entities/dict_entry.dart';
import '../../domain/entities/dict_type.dart';
import '../../domain/repositories/dict_repository.dart';
import '../db/daos/dict_entry_dao.dart';
import '../repositories/drift_dict_repository.dart';
import 'account_providers.dart';

final dictEntryDaoProvider = Provider<DictEntryDao>((ref) {
  return ref.watch(appDatabaseProvider).dictEntryDao;
});

final dictRepositoryProvider = Provider<DictRepository>((ref) {
  return DriftDictRepository(ref.watch(dictEntryDaoProvider));
});

/// 订阅某一类字典条目（按 sortOrder + code 升序）。
final dictEntriesProvider =
    StreamProvider.family<List<DictEntry>, DictType>((ref, type) {
  return ref.watch(dictRepositoryProvider).watchByType(type);
});

/// 主权地区索引：code → RegionMeta，由数据库实时驱动。
/// 所有 UI 层通过 `ref.watch(regionMetaIndexProvider)` 获取，
/// 不得直接依赖静态列表。
final regionMetaIndexProvider = StreamProvider<RegionIndex>((ref) {
  return ref
      .watch(dictRepositoryProvider)
      .watchByType(DictType.sovereigntyRegion)
      .map((entries) {
        // First pass: resolve parent names for the index
        final codeToName = <String, String>{
          for (final e in entries) e.code: e.name,
        };
        return {
          for (final e in entries)
            e.code: RegionMeta.fromDictEntry(
              e,
              parentNames: codeToName,
            ),
        };
      });
});
