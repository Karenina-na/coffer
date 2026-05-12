import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/errors.dart';
import 'package:gwp/core/result.dart';
import 'package:gwp/data/providers/country_data_importer.dart';
import 'package:gwp/domain/entities/dict_entry.dart';
import 'package:gwp/domain/entities/dict_type.dart';
import 'package:gwp/domain/repositories/dict_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('CountryDataImporter updates local countries by name first', () async {
    final repo = _FakeDictRepository.regions([
      _regionEntry(
        id: 1,
        code: 'GE',
        name: '德国',
        nameEn: 'Germany',
      ),
    ]);
    final requestedUris = <Uri>[];
    final importer = CountryDataImporter(
      repo,
      client: MockClient((request) async {
        requestedUris.add(request.url);
        if (request.url.path == '/v3.1/name/Germany') {
          return _jsonResponse([
            _country(
              code: 'DE',
              nameEn: 'Germany',
              nameZh: '德国',
              continent: 'Europe',
              lat: 51,
              lon: 9,
              currencies: ['EUR'],
              flag: '🇩🇪',
            ),
          ]);
        }
        fail('Unexpected request: ${request.url}');
      }),
    );

    final result = await importer.import();

    expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
    expect(requestedUris, hasLength(1));
    expect(requestedUris.single.path, '/v3.1/name/Germany');
    expect(requestedUris.single.queryParameters['fullText'], 'true');
    expect(
      requestedUris.single.queryParameters['fields'],
      'cca2,name,translations,flag,continents,latlng,currencies',
    );
    final summary = result.valueOrNull!;
    expect(summary.updated, 1);
    expect(summary.skippedNoMatch, 0);
    expect(summary.skippedAmbiguous, 0);
    expect(summary.matchedByCodeFallback, 0);
    expect(summary.currencyInserted, 1);
    expect(repo.updatedRegionCodes, ['GE']);
    expect(repo.region('GE')!.name, '德国');
    expect(repo.region('GE')!.nameEn, 'Germany');
    expect(repo.region('GE')!.flagEmoji, '🇩🇪');
    expect(repo.region('GE')!.continent, '欧洲');
    expect(repo.region('GE')!.colorHex, '0xFF7B6BD4');
    expect(repo.region('GE')!.parentRegion, 'EU');
    expect(repo.currencyCodes, contains('EUR'));
    expect(repo.regionCodes, isNot(contains('DE')));
  });

  test('CountryDataImporter falls back to code when name lookup misses', () async {
    final repo = _FakeDictRepository.regions([
      _regionEntry(
        id: 1,
        code: 'DE',
        name: '德意志',
        nameEn: 'Deutschland',
      ),
    ]);
    final requestedUris = <Uri>[];
    final importer = CountryDataImporter(
      repo,
      client: MockClient((request) async {
        requestedUris.add(request.url);
        if (request.url.path == '/v3.1/name/Deutschland') {
          return http.Response('[]', 200);
        }
        if (request.url.path == '/v3.1/name/%E5%BE%B7%E6%84%8F%E5%BF%97') {
          return http.Response('[]', 200);
        }
        if (request.url.path == '/v3.1/alpha/DE') {
          return _jsonResponse({
            'cca2': 'DE',
            'name': {'common': 'Germany'},
            'translations': {
              'zho': {'common': '德国'},
            },
            'flag': '🇩🇪',
            'continents': ['Europe'],
            'latlng': [51, 9],
            'currencies': {
              'EUR': {'name': 'Euro'},
            },
          });
        }
        fail('Unexpected request: ${request.url}');
      }),
    );

    final result = await importer.import();

    expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
    expect(
      requestedUris.map((uri) => uri.path).toList(),
      [
        '/v3.1/name/Deutschland',
        '/v3.1/name/%E5%BE%B7%E6%84%8F%E5%BF%97',
        '/v3.1/alpha/DE',
      ],
    );
    final summary = result.valueOrNull!;
    expect(summary.updated, 1);
    expect(summary.skippedNoMatch, 0);
    expect(summary.skippedAmbiguous, 0);
    expect(summary.matchedByCodeFallback, 1);
    expect(summary.currencyInserted, 1);
    expect(repo.updatedRegionCodes, ['DE']);
    expect(repo.region('DE')!.name, '德国');
    expect(repo.currencyCodes, contains('EUR'));
  });

  test('CountryDataImporter skips ambiguous name when code also fails', () async {
    final repo = _FakeDictRepository.regions([
      _regionEntry(id: 1, code: 'GE', name: '刚果'),
    ]);
    final importer = CountryDataImporter(
      repo,
      client: MockClient((request) async {
        if (request.url.path == '/v3.1/name/%E5%88%9A%E6%9E%9C') {
          return _jsonResponse([
            _country(
              code: 'CG',
              nameEn: 'Republic of the Congo',
              nameZh: '刚果共和国',
              continent: 'Africa',
              lat: -1,
              lon: 15,
              currencies: ['XAF'],
              flag: '🇨🇬',
            ),
            _country(
              code: 'CD',
              nameEn: 'DR Congo',
              nameZh: '刚果民主共和国',
              continent: 'Africa',
              lat: 0,
              lon: 25,
              currencies: ['CDF'],
              flag: '🇨🇩',
            ),
          ]);
        }
        if (request.url.path == '/v3.1/alpha/GE') {
          return http.Response('Not found', 404);
        }
        fail('Unexpected request: ${request.url}');
      }),
    );

    final result = await importer.import();

    expect(result.isOk, isTrue, reason: '${result.errorOrNull}');
    final summary = result.valueOrNull!;
    expect(summary.updated, 0);
    expect(summary.skippedNoMatch, 0);
    expect(summary.skippedAmbiguous, 1);
    expect(summary.matchedByCodeFallback, 0);
    expect(summary.currencyInserted, 0);
    expect(repo.updatedRegionCodes, isEmpty);
    expect(repo.currencyCodes, isNot(contains('XAF')));
    expect(repo.currencyCodes, isNot(contains('CDF')));
    expect(repo.regionCodes, ['GE']);
  });

  test('CountryDataImporter preserves local-only region fields', () async {
    final repo = _FakeDictRepository.regions([
      _regionEntry(
        id: 1,
        code: 'US',
        name: '旧美国',
        sortOrder: 7,
        isBuiltin: false,
      ),
    ]);
    final importer = CountryDataImporter(
      repo,
      client: MockClient((request) async {
        if (request.url.path == '/v3.1/name/%E6%97%A7%E7%BE%8E%E5%9B%BD') {
          return _jsonResponse([
            _country(
              code: 'US',
              nameEn: 'United States',
              nameZh: '美国',
              continent: 'North America',
              lat: 38,
              lon: -97,
              currencies: ['USD'],
              flag: '🇺🇸',
            ),
          ]);
        }
        fail('Unexpected request: ${request.url}');
      }),
    );

    final result = await importer.import();
    expect(result.isOk, isTrue, reason: '${result.errorOrNull}');

    final us = repo.region('US')!;
    expect(us.sortOrder, 7);
    expect(us.isBuiltin, isFalse);
  });

  test('CountryDataImporter does not overwrite existing anchor coords', () async {
    final repo = _FakeDictRepository.regions([
      _regionEntry(
        id: 1,
        code: 'GB',
        name: '英国',
        nameEn: 'United Kingdom',
        mapLon: -3.4360,
        mapLat: 55.3781,
        anchorLon: -0.1276,
        anchorLat: 51.5072,
      ),
    ]);
    final importer = CountryDataImporter(
      repo,
      client: MockClient((request) async {
        if (request.url.path == '/v3.1/name/United%20Kingdom') {
          return _jsonResponse([
            _country(
              code: 'GB',
              nameEn: 'United Kingdom',
              nameZh: '英国',
              continent: 'Europe',
              lat: 55.3781,
              lon: -3.4360,
              currencies: ['GBP'],
              flag: '🇬🇧',
            ),
          ]);
        }
        fail('Unexpected request: ${request.url}');
      }),
    );

    final result = await importer.import();
    expect(result.isOk, isTrue, reason: '${result.errorOrNull}');

    final gb = repo.region('GB')!;
    expect(gb.mapLon, -3.4360);
    expect(gb.mapLat, 55.3781);
    expect(gb.anchorLon, -0.1276);
    expect(gb.anchorLat, 51.5072);
  });
}

DictEntry _regionEntry({
  required int id,
  required String code,
  required String name,
  String? nameEn,
  int sortOrder = 1000,
  bool isBuiltin = true,
  double? mapLon,
  double? mapLat,
  double? anchorLon,
  double? anchorLat,
}) {
  return DictEntry(
    id: id,
    type: DictType.sovereigntyRegion,
    code: code,
    name: name,
    nameEn: nameEn,
    sortOrder: sortOrder,
    isBuiltin: isBuiltin,
    createdAt: DateTime.utc(2025, 1, 1),
    updatedAt: DateTime.utc(2025, 1, 1),
    mapLon: mapLon,
    mapLat: mapLat,
    anchorLon: anchorLon,
    anchorLat: anchorLat,
  );
}

Map<String, dynamic> _country({
  required String code,
  required String nameEn,
  required String nameZh,
  required String continent,
  required double lat,
  required double lon,
  required List<String> currencies,
  required String flag,
}) {
  return {
    'cca2': code,
    'name': {'common': nameEn},
    'translations': {
      'zho': {'common': nameZh},
    },
    'flag': flag,
    'continents': [continent],
    'latlng': [lat, lon],
    'currencies': {
      for (final currency in currencies) currency: {'name': currency},
    },
  };
}

http.Response _jsonResponse(Object body) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

class _FakeDictRepository implements DictRepository {
  _FakeDictRepository.regions(List<DictEntry> regions)
      : _regions = {for (final entry in regions) entry.code: entry};

  int listByTypeCalls = 0;
  int _nextId = 100;
  final updatedRegionCodes = <String>[];
  final Map<String, DictEntry> _regions;
  final Map<String, DictEntry> _currencies = {
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
  Iterable<String> get currencyCodes => _currencies.keys;

  DictEntry? region(String code) => _regions[code];

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
      anchorLon: anchorLon,
      anchorLat: anchorLat,
      parentRegion: parentRegion,
    );
    map[code] = entry;
    return Ok(entry);
  }

  @override
  Future<Result<void, AppError>> deleteCustom(int id) async => const Ok(null);

  @override
  Future<DictEntry?> findByTypeAndCode(DictType type, String code) async {
    final normalized = code.trim().toUpperCase();
    final map = type == DictType.sovereigntyRegion ? _regions : _currencies;
    return map[normalized];
  }

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
    Object? flagEmoji = const DictFieldAbsent(),
    Object? continent = const DictFieldAbsent(),
    Object? colorHex = const DictFieldAbsent(),
    Object? mapLon = const DictFieldAbsent(),
    Object? mapLat = const DictFieldAbsent(),
    Object? anchorLon = const DictFieldAbsent(),
    Object? anchorLat = const DictFieldAbsent(),
    Object? parentRegion = const DictFieldAbsent(),
  }) async {
    final match = _regions.values.firstWhere((e) => e.id == id);
    updatedRegionCodes.add(match.code);
    final updated = match.copyWith(
      name: name ?? match.name,
      nameEn: nameEn ?? match.nameEn,
      sortOrder: sortOrder ?? match.sortOrder,
      flagEmoji:
          flagEmoji is DictFieldAbsent ? match.flagEmoji : flagEmoji as String?,
      continent:
          continent is DictFieldAbsent ? match.continent : continent as String?,
      colorHex:
          colorHex is DictFieldAbsent ? match.colorHex : colorHex as String?,
      mapLon: mapLon is DictFieldAbsent ? match.mapLon : mapLon as double?,
      mapLat: mapLat is DictFieldAbsent ? match.mapLat : mapLat as double?,
      anchorLon: anchorLon is DictFieldAbsent
          ? match.anchorLon
          : anchorLon as double?,
      anchorLat: anchorLat is DictFieldAbsent
          ? match.anchorLat
          : anchorLat as double?,
      parentRegion: parentRegion is DictFieldAbsent
          ? match.parentRegion
          : parentRegion as String?,
    );
    _regions[match.code] = updated;
    return Ok(updated);
  }

  @override
  Stream<List<DictEntry>> watchByType(DictType type) async* {
    yield await listByType(type);
  }

  @override
  Future<Result<void, AppError>> reorderByType(DictType type, List<int> entryIds) {
    throw UnimplementedError();
  }
}
