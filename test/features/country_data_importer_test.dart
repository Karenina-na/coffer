import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/data/providers/country_data_importer.dart';
import 'package:gwp/domain/entities/dict_entry.dart';
import 'package:gwp/domain/entities/dict_type.dart';
import 'package:gwp/domain/repositories/dict_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  test('CountryDataImporter preloads dictionaries once', () async {
    final repo = _FakeDictRepository();
    final client = MockClient((request) async {
      return http.Response.bytes(
        utf8.encode(
        '''
[
  {
    "cca2": "US",
    "name": {"common": "United States"},
    "translations": {"zho": {"common": "美国"}},
    "flag": "🇺🇸",
    "continents": ["North America"],
    "latlng": [38, -97],
    "currencies": {"USD": {"name": "United States dollar"}}
  },
  {
    "cca2": "DE",
    "name": {"common": "Germany"},
    "translations": {"zho": {"common": "德国"}},
    "flag": "🇩🇪",
    "continents": ["Europe"],
    "latlng": [51, 9],
    "currencies": {"EUR": {"name": "Euro"}}
  }
]
''',
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final importer = CountryDataImporter(repo, client: client);
    final result = await importer.import();

    expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
    expect(result.valueOrNull, 2);
    expect(repo.listByTypeCalls, 2);
    expect(repo.updatedRegionCodes, ['US']);
    expect(repo.regionCodes, contains('DE'));
  });
}

class _FakeDictRepository implements DictRepository {
  int listByTypeCalls = 0;
  int _nextId = 10;
  final updatedRegionCodes = <String>[];
  final _regions = <String, DictEntry>{
    'US': DictEntry(
      id: 1,
      type: DictType.sovereigntyRegion,
      code: 'US',
      name: '旧美国',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
    ),
  };
  final _currencies = <String, DictEntry>{
    'USD': DictEntry(
      id: 2,
      type: DictType.currency,
      code: 'USD',
      name: 'USD',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
    ),
  };

  Iterable<String> get regionCodes => _regions.keys;

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
    String? parentRegion,
  }) async {
    final map = type == DictType.sovereigntyRegion ? _regions : _currencies;
    if (map.containsKey(code)) {
      throw Exception('duplicate');
    }
    final entry = DictEntry(
      id: _nextId++,
      type: type,
      code: code,
      name: name,
      nameEn: nameEn,
      sortOrder: sortOrder,
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
      flagEmoji: flagEmoji,
      continent: continent,
      colorHex: colorHex,
      mapLon: mapLon,
      mapLat: mapLat,
      parentRegion: parentRegion,
    );
    map[code] = entry;
    return Ok(entry);
  }

  @override
  Future<Result<void, AppError>> deleteCustom(int id) async => const Ok(null);

  @override
  Future<List<DictEntry>> listByType(DictType type) async {
    listByTypeCalls++;
    final map = type == DictType.sovereigntyRegion ? _regions : _currencies;
    return map.values.toList(growable: false);
  }

  @override
  Future<Result<DictEntry, AppError>> updateEntry({
    required int id,
    String? name,
    String? nameEn,
    int? sortOrder,
    Object? flagEmoji = const _Absent(),
    Object? continent = const _Absent(),
    Object? colorHex = const _Absent(),
    Object? mapLon = const _Absent(),
    Object? mapLat = const _Absent(),
    Object? parentRegion = const _Absent(),
  }) async {
    final match = _regions.values.firstWhere((e) => e.id == id);
    updatedRegionCodes.add(match.code);
    final updated = match.copyWith(
      name: name ?? match.name,
      nameEn: nameEn ?? match.nameEn,
      sortOrder: sortOrder ?? match.sortOrder,
      flagEmoji: flagEmoji is _Absent ? match.flagEmoji : flagEmoji as String?,
      continent: continent is _Absent ? match.continent : continent as String?,
      colorHex: colorHex is _Absent ? match.colorHex : colorHex as String?,
      mapLon: mapLon is _Absent ? match.mapLon : mapLon as double?,
      mapLat: mapLat is _Absent ? match.mapLat : mapLat as double?,
      parentRegion: parentRegion is _Absent ? match.parentRegion : parentRegion as String?,
    );
    _regions[match.code] = updated;
    return Ok(updated);
  }

  @override
  Stream<List<DictEntry>> watchByType(DictType type) async* {
    yield await listByType(type);
  }
}

class _Absent {
  const _Absent();
}
