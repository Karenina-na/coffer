import 'package:flutter/material.dart';

import '../../domain/entities/dict_entry.dart';
import 'design_tokens.dart';

/// Metadata for a sovereignty region (country / economic zone).
///
/// Derived from a [DictEntry] whose type is `sovereigntyRegion`.
/// The static [fromDictEntry] factory converts the DB row into a usable
/// UI object; all callers receive a [RegionIndex] (a `Map<String, RegionMeta>`)
/// via `regionMetaIndexProvider` and look up entries with helpers below.
class RegionMeta {
  const RegionMeta({
    required this.code,
    required this.displayName,
    this.shortName,
    this.continent,
    this.color,
    this.mapCoords,
    this.flag,
    this.parentCode,
    this.parentName,
  });

  /// ISO country/region code, e.g. `'CN'`, `'US'`, `'EU'`.
  final String code;

  /// Full display name used in list headers, e.g. `'中国大陆'`, `'中国香港'`.
  final String displayName;

  /// Compact label for space-constrained UI such as map pin tooltips.
  /// Falls back to [displayName] when `null`.
  final String? shortName;

  /// Continent group label, usually `'亚太'` | `'欧洲'` | `'美洲'` | `'中东'`.
  /// Synthetic regions may also use non-geographic groups such as `'数字'`.
  final String? continent;

  /// Accent color for region chips, list bar indicators, etc.
  final Color? color;

  /// Parent region code (e.g. `'EU'` for `DE`).
  final String? parentCode;

  /// Parent region display name (e.g. `'欧盟'` for `DE`). Looked up
  /// from the same index when building from a DictEntry.
  final String? parentName;

  /// Effective map anchor position: (x, y) where
  /// x = (lon + 180) / 360,  y = (90 − lat) / 180.
  /// Prefers financial-center anchor coords and falls back to geo coords.
  /// `null` for regions that have no map pin.
  final (double, double)? mapCoords;

  /// Emoji flag for display in map nodes and compact region indicators.
  final String? flag;

  /// Builds a [RegionMeta] from a `sovereigntyRegion` [DictEntry].
  /// [parentNames] is a code→name lookup used to resolve [parentRegion].
  factory RegionMeta.fromDictEntry(
    DictEntry entry, {
    Map<String, String> parentNames = const {},
  }) {
    final anchorLon = entry.anchorLon;
    final anchorLat = entry.anchorLat;
    final geoLon = entry.mapLon;
    final geoLat = entry.mapLat;
    final lon = anchorLon ?? geoLon;
    final lat = anchorLat ?? geoLat;
    (double, double)? coords;
    if (lon != null && lat != null) {
      coords = ((lon + 180) / 360, (90 - lat) / 180);
    }

    Color? color;
    final hex = entry.colorHex;
    if (hex != null) {
      final value = int.tryParse(hex);
      if (value != null) color = Color(value);
    }

    return RegionMeta(
      code: entry.code,
      displayName: entry.name,
      continent: entry.continent,
      color: color,
      mapCoords: coords,
      flag: entry.flagEmoji,
      parentCode: entry.parentRegion,
      parentName: entry.parentRegion != null
          ? parentNames[entry.parentRegion]
          : null,
    );
  }
}

// ── Region index type ─────────────────────────────────────────────────────────

/// Map from region code → [RegionMeta]. Populated from the database via
/// `regionMetaIndexProvider` and passed explicitly through the widget tree.
typedef RegionIndex = Map<String, RegionMeta>;

// ── Helper functions (take explicit index) ────────────────────────────────────

/// Returns the [RegionMeta] for [code], or `null` if not in [index].
RegionMeta? regionMetaOf(RegionIndex index, String code) => index[code];

/// Chinese display name for [code]; falls back to [code] itself.
/// Format: "区域 | 国家" when parent region exists, otherwise plain name.
String regionLabel(RegionIndex index, String code) {
  final meta = index[code];
  if (meta == null) return code;
  if (meta.parentName != null) {
    return '${meta.parentName} | ${meta.displayName}';
  }
  return meta.displayName;
}

/// Parent/aggregate label for [code].
/// Returns parent region name when present (e.g. `欧盟` for `DE`),
/// otherwise falls back to [regionLabel].
String regionAggregateLabel(RegionIndex index, String code) {
  final meta = index[code];
  if (meta == null) return code;
  return meta.parentName ?? meta.displayName;
}

/// Canonical grouping key for analytics views.
/// EU child regions roll up to `EU`; other regions keep their own code.
String regionAggregateKey(RegionIndex index, String code) {
  final meta = index[code];
  return meta?.parentCode ?? code;
}

/// Accent [Color] for [code]; falls back to [GwpColors.textMuted].
Color regionColor(RegionIndex index, String code) =>
    index[code]?.color ?? GwpColors.textMuted;

/// Accent [Color] for aggregate region display; falls back to child color.
Color regionAggregateColor(RegionIndex index, String code) =>
    regionColor(index, regionAggregateKey(index, code));

/// Emoji flag for [code]; falls back to [code] itself.
String regionFlag(RegionIndex index, String code) =>
    index[code]?.flag ?? code;

// ── Continent metadata ────────────────────────────────────────────────────────

/// Ordered list of the standard continent labels used for filter tabs.
const kContinentList = ['亚太', '欧洲', '美洲', '中东'];

/// Accent colors for continent group labels on the world map.
const kContinentColors = <String, Color>{
  '亚太': Color(0xFF4E8FC0), // steel blue
  '欧洲': Color(0xFF7B6BD4), // muted violet
  '美洲': Color(0xFF3DAA80), // teal-mint
  '中东': Color(0xFFCC9938), // warm amber
  '数字': Color(0xFF38BDF8), // crypto cyan
};

List<String> orderedContinentLabels(Iterable<String> continents) {
  final available = continents.where((c) => c.isNotEmpty).toSet();
  final ordered = <String>[
    ...kContinentList.where(available.contains),
  ];
  final extras = available.where((c) => !kContinentList.contains(c)).toList()
    ..sort();
  ordered.addAll(extras);
  return ordered;
}
