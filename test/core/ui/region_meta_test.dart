import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/ui/region_meta.dart';
import 'package:coffer/domain/entities/dict_entry.dart';
import 'package:coffer/domain/entities/dict_type.dart';

void main() {
  group('RegionMeta.fromDictEntry', () {
    test('prefers anchor coordinates for mapCoords', () {
      final meta = RegionMeta.fromDictEntry(
        DictEntry(
          id: 1,
          type: DictType.sovereigntyRegion,
          code: 'GB',
          name: '英国',
          createdAt: DateTime.utc(2025, 1, 1),
          updatedAt: DateTime.utc(2025, 1, 1),
          mapLon: -3.4360,
          mapLat: 55.3781,
          anchorLon: -0.1276,
          anchorLat: 51.5072,
        ),
      );

      expect(meta.mapCoords?.$1, closeTo((179.8724) / 360, 1e-6));
      expect(meta.mapCoords?.$2, closeTo((90 - 51.5072) / 180, 1e-6));
    });

    test('falls back to geographic coordinates when no anchor exists', () {
      final meta = RegionMeta.fromDictEntry(
        DictEntry(
          id: 2,
          type: DictType.sovereigntyRegion,
          code: 'DE',
          name: '德国',
          createdAt: DateTime.utc(2025, 1, 1),
          updatedAt: DateTime.utc(2025, 1, 1),
          mapLon: 9,
          mapLat: 51,
        ),
      );

      expect(meta.mapCoords?.$1, closeTo((189) / 360, 1e-6));
      expect(meta.mapCoords?.$2, closeTo((90 - 51) / 180, 1e-6));
    });
  });
}
