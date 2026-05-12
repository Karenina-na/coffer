import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/dict_entry.dart';
import '../entities/dict_type.dart';

abstract interface class DictRepository {
  Stream<List<DictEntry>> watchByType(DictType type);

  Future<List<DictEntry>> listByType(DictType type);

  Future<DictEntry?> findByTypeAndCode(DictType type, String code);

  /// 新增自定义条目。返回 [ValidationError] 当：
  /// - `code` 为空或非法；
  /// - 同 `type + code` 已存在。
  Future<Result<DictEntry, AppError>> addCustom({
    required DictType type,
    required String code,
    required String name,
    String? nameEn,
    int sortOrder,
    // 地区 UI 元数据（仅 sovereigntyRegion 使用）
    String? flagEmoji,
    String? continent,
    String? colorHex,
    double? mapLon,
    double? mapLat,
    double? anchorLon,
    double? anchorLat,
    String? parentRegion,
  });

  /// 更新条目名称、英文名、排序。内置项允许改名/排序，不允许改 code。
  /// 地区 UI 元数据字段（flagEmoji / continent / colorHex / mapLon / mapLat
  /// / anchorLon / anchorLat / parentRegion）内置项和自定义项均可编辑。
  Future<Result<DictEntry, AppError>> updateEntry({
    required int id,
    String? name,
    String? nameEn,
    int? sortOrder,
    // 地区 UI 元数据（仅 sovereigntyRegion 使用）
    Object? flagEmoji = const DictFieldAbsent(),
    Object? continent = const DictFieldAbsent(),
    Object? colorHex = const DictFieldAbsent(),
    Object? mapLon = const DictFieldAbsent(),
    Object? mapLat = const DictFieldAbsent(),
    Object? anchorLon = const DictFieldAbsent(),
    Object? anchorLat = const DictFieldAbsent(),
    Object? parentRegion = const DictFieldAbsent(),
  });

  /// 删除自定义条目。拒绝删除 `isBuiltin = true` 的条目。
  Future<Result<void, AppError>> deleteCustom(int id);

  Future<Result<void, AppError>> reorderByType(
    DictType type,
    List<int> entryIds,
  );
}

/// Sentinel used to distinguish "not passed" from `null` in [DictRepository.updateEntry].
class DictFieldAbsent {
  const DictFieldAbsent();
}
