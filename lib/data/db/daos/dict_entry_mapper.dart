import '../../../domain/entities/dict_entry.dart';
import '../../../domain/entities/dict_type.dart';
import '../database.dart';

/// DictEntry ↔ DictEntryRow 映射。
///
/// DB 列 `type` 是字符串，在 mapper 里收敛成枚举，让上层只看见 [DictType]。
DictEntry dictEntryFromRow(DictEntryRow row) => DictEntry(
      id: row.id,
      type: DictType.fromCode(row.type),
      code: row.code,
      name: row.name,
      nameEn: row.nameEn,
      sortOrder: row.sortOrder,
      isBuiltin: row.isBuiltin,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      flagEmoji: row.flagEmoji,
      continent: row.continent,
      colorHex: row.colorHex,
      mapLon: row.mapLon,
      mapLat: row.mapLat,
      anchorLon: row.anchorLon,
      anchorLat: row.anchorLat,
      parentRegion: row.parentRegion,
    );
