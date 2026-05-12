import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../domain/entities/dict_entry.dart';
import '../../domain/entities/dict_type.dart';
import '../../domain/repositories/dict_repository.dart';
import '../db/database.dart';
import '../db/daos/dict_entry_dao.dart';
import '../db/daos/dict_entry_mapper.dart';

/// 规则：
/// - `code` 必须非空、仅限 A-Z0-9 + 下划线；写入时统一大写
/// - 单一 (type, code) 唯一——内置项靠 migration 的 INSERT OR IGNORE 保证，
///   用户自定义项靠 [addCustom] 在 insert 前查重。SQLite 没有在这里放 UNIQUE
///   索引是因为部分旧数据库经历过 migration 后才加 UNIQUE 反而会报冲突，
///   应用层先查再写更稳。
class DriftDictRepository implements DictRepository {
  DriftDictRepository(this._dao, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final DictEntryDao _dao;
  final DateTime Function() _now;

  static final _codePattern = RegExp(r'^[A-Z0-9_]{1,32}$');

  @override
  Stream<List<DictEntry>> watchByType(DictType type) {
    return _dao.watchByType(type.code).map(
          (rows) => rows.map(dictEntryFromRow).toList(growable: false),
        );
  }

  @override
  Future<List<DictEntry>> listByType(DictType type) async {
    final rows = await _dao.listByType(type.code);
    return rows.map(dictEntryFromRow).toList(growable: false);
  }

  @override
  Future<DictEntry?> findByTypeAndCode(DictType type, String code) async {
    final row = await _dao.findByTypeAndCode(type.code, code.trim().toUpperCase());
    return row == null ? null : dictEntryFromRow(row);
  }

  @override
  Future<Result<DictEntry, AppError>> addCustom({
    required DictType type,
    required String code,
    required String name,
    String? nameEn,
    int sortOrder = 1000,
    String? flagEmoji,
    String? continent,
    String? colorHex,
    double? mapLon,
    double? mapLat,
    double? anchorLon,
    double? anchorLat,
    String? parentRegion,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (!_codePattern.hasMatch(normalized)) {
      return const Err(ValidationError(
        '代码需 1-32 位，大写字母 / 数字 / 下划线组合',
      ));
    }
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Err(ValidationError('名称不能为空'));
    }
    try {
      final existing = await _dao.findByTypeAndCode(type.code, normalized);
      if (existing != null) {
        return Err(ValidationError('代码已存在：$normalized'));
      }
      final ts = _now();
      final id = await _dao.insertCustom(
        DictEntriesCompanion.insert(
          type: type.code,
          code: normalized,
          name: trimmedName,
          nameEn: Value(nameEn?.trim().isEmpty == true ? null : nameEn?.trim()),
          sortOrder: Value(sortOrder),
          isBuiltin: const Value(false),
          createdAt: ts,
          updatedAt: ts,
          flagEmoji: Value(flagEmoji?.trim().isEmpty == true ? null : flagEmoji?.trim()),
          continent: Value(continent?.trim().isEmpty == true ? null : continent?.trim()),
          colorHex: Value(colorHex?.trim().isEmpty == true ? null : colorHex?.trim()),
          mapLon: Value(mapLon),
          mapLat: Value(mapLat),
          anchorLon: Value(anchorLon),
          anchorLat: Value(anchorLat),
          parentRegion: Value(parentRegion?.trim().isEmpty == true ? null : parentRegion?.trim()),
        ),
      );
      return Ok(DictEntry(
        id: id,
        type: type,
        code: normalized,
        name: trimmedName,
        nameEn: nameEn?.trim().isEmpty == true ? null : nameEn?.trim(),
        sortOrder: sortOrder,
        isBuiltin: false,
        createdAt: ts,
        updatedAt: ts,
        flagEmoji: flagEmoji?.trim().isEmpty == true ? null : flagEmoji?.trim(),
        continent: continent?.trim().isEmpty == true ? null : continent?.trim(),
        colorHex: colorHex?.trim().isEmpty == true ? null : colorHex?.trim(),
        mapLon: mapLon,
        mapLat: mapLat,
        anchorLon: anchorLon,
        anchorLat: anchorLat,
        parentRegion: parentRegion?.trim().isEmpty == true ? null : parentRegion?.trim(),
      ));
    } catch (e) {
      return Err(StorageError('addCustom failed: $e'));
    }
  }

  @override
  Future<Result<DictEntry, AppError>> updateEntry({
    required int id,
    String? name,
    String? nameEn,
    int? sortOrder,
    Object? flagEmoji = const DictFieldAbsent(),
    Object? continent = const DictFieldAbsent(),
    Object? colorHex = const DictFieldAbsent(),
    Object? mapLon = const DictFieldAbsent(),
    Object? mapLat = const DictFieldAbsent(),
    Object? anchorLon = const DictFieldAbsent(),
    Object? anchorLat = const DictFieldAbsent(),
    Object? parentRegion = const DictFieldAbsent(),
  }) async {
    try {
      final ts = _now();

      Value<String?> toStringValue(Object? v) {
        if (v is DictFieldAbsent) return const Value.absent();
        final s = v as String?;
        return Value(s?.trim().isEmpty == true ? null : s?.trim());
      }

      Value<double?> toDoubleValue(Object? v) {
        if (v is DictFieldAbsent) return const Value.absent();
        return Value(v as double?);
      }

      final patch = DictEntriesCompanion(
        name: name == null ? const Value.absent() : Value(name.trim()),
        nameEn: nameEn == null
            ? const Value.absent()
            : Value(nameEn.trim().isEmpty ? null : nameEn.trim()),
        sortOrder:
            sortOrder == null ? const Value.absent() : Value(sortOrder),
        updatedAt: Value(ts),
        flagEmoji: toStringValue(flagEmoji),
        continent: toStringValue(continent),
        colorHex: toStringValue(colorHex),
        mapLon: toDoubleValue(mapLon),
        mapLat: toDoubleValue(mapLat),
        anchorLon: toDoubleValue(anchorLon),
        anchorLat: toDoubleValue(anchorLat),
        parentRegion: toStringValue(parentRegion),
      );
      final n = await _dao.updateById(id, patch);
      if (n == 0) return Err(NotFoundError('dict entry not found: $id'));
      final row = await _dao.findById(id);
      if (row == null) {
        return Err(NotFoundError('dict entry vanished after update: $id'));
      }
      return Ok(dictEntryFromRow(row));
    } catch (e) {
      return Err(StorageError('updateEntry failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> deleteCustom(int id) async {
    try {
      final n = await _dao.deleteCustomById(id);
      if (n == 0) {
        return const Err(ValidationError('内置条目不可删除，或条目不存在'));
      }
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('deleteCustom failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> reorderByType(
    DictType type,
    List<int> entryIds,
  ) async {
    try {
      final existing = await _dao.listByType(type.code);
      final existingIds = existing.map((e) => e.id).toSet();
      if (!entryIds.every(existingIds.contains)) {
        return const Err(ValidationError('reorder contains unknown dict entry id'));
      }
      for (var i = 0; i < entryIds.length; i++) {
        await _dao.updateSortOrder(entryIds[i], 100 + i * 10);
      }
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('reorderByType failed: $e'));
    }
  }
}

class DictFieldAbsent {
  const DictFieldAbsent();
}
