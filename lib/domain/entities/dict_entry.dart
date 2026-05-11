import 'package:freezed_annotation/freezed_annotation.dart';

import 'dict_type.dart';

part 'dict_entry.freezed.dart';

/// 业务字典条目（转账协议 / 主权地区 / 货币 三合一）。
///
/// 对应 Drift `dict_entries` 表。内置项由 migration 预置，`isBuiltin = true`
/// 的行不可删除（可改名、排序，不可改 code）。
///
/// 领域不可变：任何字段修改走 `copyWith`。
@freezed
abstract class DictEntry with _$DictEntry {
  const factory DictEntry({
    required int id,
    required DictType type,
    required String code,
    required String name,
    String? nameEn,
    @Default(1000) int sortOrder,
    @Default(false) bool isBuiltin,
    required DateTime createdAt,
    required DateTime updatedAt,
    // ── 地区 UI 元数据（仅 sovereigntyRegion 使用）──────────────────────────
    /// Emoji 国旗，如 `'🇨🇳'`。
    String? flagEmoji,
    /// 大洲分组标签，如 `'亚太'`。
    String? continent,
    /// 强调色十六进制字符串，如 `'0xFFEF4444'`。
    String? colorHex,
    /// 地理经度（-180 ~ 180），表示国家/地区的真实地理参考位置。
    double? mapLon,
    /// 地理纬度（-90 ~ 90），表示国家/地区的真实地理参考位置。
    double? mapLat,
    /// 地图锚点经度（-180 ~ 180），默认用于金融中心点展示。
    double? anchorLon,
    /// 地图锚点纬度（-90 ~ 90），默认用于金融中心点展示。
    double? anchorLat,

    /// 所属上级区域 code（如 `DE` 的 `parent_region = 'EU'`）。
    /// `null` 表示顶级区域。UI 展示为「区域 | 国家」层级格式。
    String? parentRegion,
  }) = _DictEntry;
}
