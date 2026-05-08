import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/dict_entries.dart';

part 'dict_entry_dao.g.dart';

/// dict_entries 表读写。
///
/// 查询约定：所有对外 API 都以 `type` 作为首要过滤条件，因为 UI 永远只看
/// 一种字典；列表按 (sort_order ASC, code ASC) 稳定排序，便于前端不需要再
/// 排序一次。
@DriftAccessor(tables: [DictEntries])
class DictEntryDao extends DatabaseAccessor<AppDatabase>
    with _$DictEntryDaoMixin {
  DictEntryDao(super.db);

  Stream<List<DictEntryRow>> watchByType(String type) {
    return (select(dictEntries)
          ..where((t) => t.type.equals(type))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.code),
          ]))
        .watch();
  }

  Future<List<DictEntryRow>> listByType(String type) {
    return (select(dictEntries)
          ..where((t) => t.type.equals(type))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.code),
          ]))
        .get();
  }

  Future<DictEntryRow?> findByTypeAndCode(String type, String code) {
    return (select(dictEntries)
          ..where((t) => t.type.equals(type) & t.code.equals(code)))
        .getSingleOrNull();
  }

  Future<DictEntryRow?> findById(int id) {
    return (select(dictEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 新增自定义条目。内置条目只能通过 migration 插入。
  Future<int> insertCustom(DictEntriesCompanion row) {
    return into(dictEntries).insert(row);
  }

  Future<int> updateById(int id, DictEntriesCompanion patch) {
    return (update(dictEntries)..where((t) => t.id.equals(id))).write(patch);
  }

  Future<int> deleteAllCustom() {
    return (delete(dictEntries)..where((t) => t.isBuiltin.equals(false))).go();
  }

  /// 仅允许删除非内置条目。内置项由 UI 端拒绝触发；这里再加一层兜底。
  Future<int> deleteCustomById(int id) {
    return (delete(dictEntries)
          ..where((t) => t.id.equals(id) & t.isBuiltin.equals(false)))
        .go();
  }
}
