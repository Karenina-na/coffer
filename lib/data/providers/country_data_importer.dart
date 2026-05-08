import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../domain/entities/dict_entry.dart';
import '../../domain/entities/dict_type.dart';
import '../../domain/repositories/dict_repository.dart';

/// 从 REST Countries 拉取到的单条国家数据。
class CountryData {
  const CountryData({
    required this.code,
    required this.nameZh,
    required this.nameEn,
    required this.continentZh,
    required this.flagEmoji,
    required this.lat,
    required this.lon,
    required this.currencies,
  });

  final String code;
  final String nameZh;
  final String nameEn;
  final String continentZh;
  final String flagEmoji;
  final double lat;
  final double lon;
  final List<String> currencies;
}

class CountrySyncSummary {
  const CountrySyncSummary({
    required this.updated,
    required this.skippedNoMatch,
    required this.skippedAmbiguous,
    required this.matchedByCodeFallback,
    required this.currencyInserted,
  });

  final int updated;
  final int skippedNoMatch;
  final int skippedAmbiguous;
  final int matchedByCodeFallback;
  final int currencyInserted;
}

/// 仅针对本地已存在的主权地区条目做 REST Countries 定向补全。
class CountryDataImporter {
  CountryDataImporter(this._repo, {http.Client? client})
      : _client = client ?? http.Client();

  final DictRepository _repo;
  final http.Client _client;

  static const _fields =
      'cca2,name,translations,flag,continents,latlng,currencies';

  static const _continentZh = <String, String>{
    'Asia': '亚太',
    'Europe': '欧洲',
    'North America': '美洲',
    'South America': '美洲',
    'Africa': '非洲',
    'Oceania': '亚太',
    'Antarctica': '南极洲',
  };

  static const _regionColor = <String, String>{
    '亚太': '0xFF4E8FC0',
    '欧洲': '0xFF7B6BD4',
    '美洲': '0xFF3DAA80',
    '中东': '0xFFCC9938',
    '非洲': '0xFFF59E0B',
  };

  static const _euMembers = {
    'AT',
    'BE',
    'BG',
    'CY',
    'CZ',
    'DE',
    'DK',
    'EE',
    'ES',
    'FI',
    'FR',
    'GR',
    'HR',
    'HU',
    'IE',
    'IT',
    'LT',
    'LU',
    'LV',
    'MT',
    'NL',
    'PL',
    'PT',
    'RO',
    'SE',
    'SI',
    'SK',
  };

  Future<Result<CountrySyncSummary, AppError>> import() async {
    try {
      final existingRegions = await _repo.listByType(DictType.sovereigntyRegion);
      final existingCurrencies = {
        for (final e in await _repo.listByType(DictType.currency)) e.code,
      };

      var updated = 0;
      var skippedNoMatch = 0;
      var skippedAmbiguous = 0;
      var matchedByCodeFallbackCount = 0;
      var currencyInserted = 0;

      for (final entry in existingRegions) {
        try {
          final resolved = await _resolveCountry(entry);
          switch (resolved) {
            case _ResolvedCountryFound(:final country, :final matchedByCodeFallback):
              final changed = await _updateRegionEntry(entry, country);
              if (changed) updated++;
              if (matchedByCodeFallback) matchedByCodeFallbackCount++;
              for (final currency in country.currencies) {
                final added = await _seedCurrency(currency, existingCurrencies);
                if (added) currencyInserted++;
              }
            case _ResolvedCountryNoMatch():
              skippedNoMatch++;
            case _ResolvedCountryAmbiguous():
              skippedAmbiguous++;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              'country_data_importer: failed for ${entry.code}/${entry.name}: ${e.runtimeType}',
            );
          }
          skippedNoMatch++;
        }
      }

      return Ok(CountrySyncSummary(
        updated: updated,
        skippedNoMatch: skippedNoMatch,
        skippedAmbiguous: skippedAmbiguous,
        matchedByCodeFallback: matchedByCodeFallbackCount,
        currencyInserted: currencyInserted,
      ));
    } catch (e) {
      return Err(UnknownError('Country import failed: $e'));
    }
  }

  void dispose() => _client.close();

  Future<_ResolvedCountry> _resolveCountry(DictEntry entry) async {
    final nameCandidates = <String>[];
    if (_isNonEmpty(entry.nameEn)) nameCandidates.add(entry.nameEn!.trim());
    if (_isNonEmpty(entry.name)) {
      final name = entry.name.trim();
      if (!nameCandidates.contains(name)) nameCandidates.add(name);
    }

    for (final candidate in nameCandidates) {
      final matched = await _fetchByName(candidate, entry);
      if (matched is _ResolvedCountryFound) return matched;
      if (matched is _ResolvedCountryAmbiguous) {
        final codeMatched = await _fetchByCode(entry.code);
        if (codeMatched != null) {
          return _ResolvedCountryFound(
            country: codeMatched,
            matchedByCodeFallback: true,
          );
        }
        return matched;
      }
    }

    final codeMatched = await _fetchByCode(entry.code);
    if (codeMatched != null) {
      return _ResolvedCountryFound(
        country: codeMatched,
        matchedByCodeFallback: true,
      );
    }
    return const _ResolvedCountryNoMatch();
  }

  Future<_ResolvedCountry> _fetchByName(String query, DictEntry entry) async {
    final uri = Uri.https('restcountries.com', '/v3.1/name/$query', {
      'fullText': 'true',
      'fields': _fields,
    });
    final response = await _client.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode == 404) return const _ResolvedCountryNoMatch();
    if (response.statusCode != 200) {
      throw UnknownError('API returned ${response.statusCode} for name lookup');
    }

    final rawList = jsonDecode(response.body);
    if (rawList is! List) return const _ResolvedCountryNoMatch();
    final countries = rawList
        .whereType<Map>()
        .map((raw) => _parseCountry(raw.cast<String, dynamic>()))
        .whereType<CountryData>()
        .toList(growable: false);
    if (countries.isEmpty) return const _ResolvedCountryNoMatch();

    final matches = countries.where((country) => _matchesEntry(country, entry)).toList();
    if (matches.length == 1) {
      return _ResolvedCountryFound(country: matches.single);
    }
    if (matches.length > 1) {
      return const _ResolvedCountryAmbiguous();
    }
    if (countries.length == 1) {
      return _ResolvedCountryFound(country: countries.single);
    }
    return const _ResolvedCountryAmbiguous();
  }

  Future<CountryData?> _fetchByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    final uri = Uri.https('restcountries.com', '/v3.1/alpha/$normalized', {
      'fields': _fields,
    });
    final response = await _client.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw UnknownError('API returned ${response.statusCode} for code lookup');
    }

    final raw = jsonDecode(response.body);
    if (raw is List) {
      for (final item in raw.whereType<Map>()) {
        final parsed = _parseCountry(item.cast<String, dynamic>());
        if (parsed != null) return parsed;
      }
      return null;
    }
    if (raw is Map<String, dynamic>) {
      return _parseCountry(raw);
    }
    return null;
  }

  Future<bool> _updateRegionEntry(DictEntry existing, CountryData country) async {
    final color = _regionColor[country.continentZh] ?? '0xFF94A3B8';
    final parent = _euMembers.contains(country.code) ? 'EU' : null;
    final coordPatch = _coordPatch(
      existing.mapLon,
      existing.mapLat,
      country.lon,
      country.lat,
    );
    final changed = _didRegionChange(existing, country, color, parent);
    final result = await _repo.updateEntry(
      id: existing.id,
      name: country.nameZh,
      nameEn: country.nameEn,
      flagEmoji: _stringPatch(existing.flagEmoji, country.flagEmoji),
      continent: _stringPatch(existing.continent, country.continentZh),
      colorHex: _stringPatch(existing.colorHex, color),
      mapLon: coordPatch.$1,
      mapLat: coordPatch.$2,
      parentRegion: _stringPatch(existing.parentRegion, parent),
    );
    if (result.isErr) {
      throw result.errorOrNull!;
    }
    return changed;
  }

  CountryData? _parseCountry(Map<String, dynamic> raw) {
    final cca2 = raw['cca2'] as String?;
    if (cca2 == null) return null;

    final name = raw['name'] as Map<String, dynamic>?;
    final commonEn = name?['common'] as String? ?? cca2;

    final translations = raw['translations'] as Map<String, dynamic>?;
    final zh = translations?['zho'] ?? translations?['chi'];
    final nameZh = zh is Map<String, dynamic>
        ? (zh['common'] as String? ?? commonEn)
        : commonEn;

    final flag = raw['flag'] as String? ?? '';
    final continents = raw['continents'] as List<dynamic>?;
    final continentEn = continents?.isNotEmpty == true
        ? continents!.first.toString()
        : '';
    final continentZh = _continentZh[continentEn] ?? '';

    final latlng = raw['latlng'] as List<dynamic>?;
    double lat = 0, lon = 0;
    if (latlng != null && latlng.length >= 2) {
      lat = (latlng[0] as num).toDouble();
      lon = (latlng[1] as num).toDouble();
    }

    final currenciesRaw = raw['currencies'] as Map<String, dynamic>?;
    final currencies = <String>[];
    if (currenciesRaw != null) {
      currencies.addAll(currenciesRaw.keys.cast<String>());
    }

    return CountryData(
      code: cca2.toUpperCase(),
      nameZh: nameZh,
      nameEn: commonEn,
      continentZh: continentZh,
      flagEmoji: flag,
      lat: lat,
      lon: lon,
      currencies: currencies,
    );
  }

  bool _matchesEntry(CountryData country, DictEntry entry) {
    final candidates = <String>{
      _normalize(country.nameZh),
      _normalize(country.nameEn),
      _normalize(country.code),
      if (_isNonEmpty(entry.name)) _normalize(entry.name),
      if (_isNonEmpty(entry.nameEn)) _normalize(entry.nameEn!),
      _normalize(entry.code),
    }..removeWhere((value) => value.isEmpty);

    final remoteNames = <String>{
      _normalize(country.nameZh),
      _normalize(country.nameEn),
      _normalize(country.code),
    };
    final localNames = <String>{
      if (_isNonEmpty(entry.name)) _normalize(entry.name),
      if (_isNonEmpty(entry.nameEn)) _normalize(entry.nameEn!),
      _normalize(entry.code),
    };
    return remoteNames.any(localNames.contains) || candidates.isNotEmpty && remoteNames.intersection(candidates).isNotEmpty;
  }

  String _normalize(String value) => value.trim().toUpperCase();

  bool _isNonEmpty(String? value) => value != null && value.trim().isNotEmpty;

  Object _stringPatch(String? current, String? remote) {
    final normalizedRemote = remote?.trim();
    if (normalizedRemote == null || normalizedRemote.isEmpty) {
      return const DictFieldAbsent();
    }
    final normalizedCurrent = current?.trim();
    if (normalizedCurrent == normalizedRemote) {
      return const DictFieldAbsent();
    }
    return normalizedRemote;
  }

  (Object, Object) _coordPatch(
    double? currentLon,
    double? currentLat,
    double remoteLon,
    double remoteLat,
  ) {
    if (!_hasUsableCoords(remoteLon, remoteLat)) {
      return (const DictFieldAbsent(), const DictFieldAbsent());
    }
    final sameLon =
        currentLon != null && (currentLon - remoteLon).abs() < 0.000001;
    final sameLat =
        currentLat != null && (currentLat - remoteLat).abs() < 0.000001;
    if (sameLon && sameLat) {
      return (const DictFieldAbsent(), const DictFieldAbsent());
    }
    return (remoteLon, remoteLat);
  }

  bool _didRegionChange(
    DictEntry existing,
    CountryData remote,
    String color,
    String? parent,
  ) {
    if (existing.name != remote.nameZh) return true;
    if ((existing.nameEn ?? '') != remote.nameEn) return true;
    if ((existing.flagEmoji ?? '') != remote.flagEmoji) return true;
    if ((existing.continent ?? '') != remote.continentZh) return true;
    if ((existing.colorHex ?? '') != color) return true;
    if ((existing.parentRegion ?? '') != (parent ?? '')) return true;
    if (!_hasUsableCoords(remote.lon, remote.lat)) return false;
    if (existing.mapLon == null || existing.mapLat == null) return true;
    return (existing.mapLon! - remote.lon).abs() >= 0.000001 ||
        (existing.mapLat! - remote.lat).abs() >= 0.000001;
  }

  bool _hasUsableCoords(double lon, double lat) =>
      lon >= -180 && lon <= 180 && lat >= -90 && lat <= 90 &&
      !(lon == 0 && lat == 0);

  Future<bool> _seedCurrency(String code, Set<String> existingCurrencies) async {
    final normalized = code.toUpperCase();
    if (existingCurrencies.contains(normalized)) return false;
    try {
      final result = await _repo.addCustom(
        type: DictType.currency,
        code: normalized,
        name: normalized,
        sortOrder: 1000,
      );
      if (result.isOk) {
        existingCurrencies.add(normalized);
        return true;
      }
      return false;
    } on Exception catch (_) {
      return false;
    }
  }
}

sealed class _ResolvedCountry {
  const _ResolvedCountry();
}

class _ResolvedCountryFound extends _ResolvedCountry {
  const _ResolvedCountryFound({
    required this.country,
    this.matchedByCodeFallback = false,
  });

  final CountryData country;
  final bool matchedByCodeFallback;
}

class _ResolvedCountryNoMatch extends _ResolvedCountry {
  const _ResolvedCountryNoMatch();
}

class _ResolvedCountryAmbiguous extends _ResolvedCountry {
  const _ResolvedCountryAmbiguous();
}
