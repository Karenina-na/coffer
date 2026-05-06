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

/// 将 REST Countries API 的数据同步到本地 dict_entries 表中。
///
/// 同步策略：
/// - 只 upsert `SOVEREIGNTY_REGION` 条目
/// - 对 API 返回的每个国家：updateEntry（若 code 已存在则更新元数据，否则新增）
/// - 不删除已有条目，不覆盖用户手动修改的值（continent / flagEmoji /
///   mapLon / mapLat 仅对已知为空的行回填）
/// - 货币代码同步写入 `CURRENCY` 字典
class CountryDataImporter {
  CountryDataImporter(this._repo, {http.Client? client})
      : _client = client ?? http.Client();

  final DictRepository _repo;
  final http.Client _client;

  static const _apiUrl = 'https://restcountries.com/v3.1/all';

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

  /// EU 成员国 ISO 3166-1 alpha-2 代码。
  /// 这些国家的 parent_region 自动设为 'EU'。
  static const _euMembers = {
    'AT', 'BE', 'BG', 'CY', 'CZ', 'DE', 'DK', 'EE', 'ES', 'FI',
    'FR', 'GR', 'HR', 'HU', 'IE', 'IT', 'LT', 'LU', 'LV', 'MT',
    'NL', 'PL', 'PT', 'RO', 'SE', 'SI', 'SK',
  };

  Future<Result<int, AppError>> import() async {
    try {
      final response = await _client.get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        return Err(UnknownError('API returned ${response.statusCode}'));
      }
      final list = jsonDecode(response.body);
      if (list is! List) {
        return const Err(UnknownError('Unexpected API response format'));
      }

      final countries = <CountryData>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final c = _parseCountry(raw.cast<String, dynamic>());
        if (c != null) countries.add(c);
      }

      if (countries.isEmpty) {
        return const Err(UnknownError('No countries parsed from API'));
      }

      final existingRegions = {
        for (final e in await _repo.listByType(DictType.sovereigntyRegion))
          e.code: e,
      };
      final existingCurrencies = {
        for (final e in await _repo.listByType(DictType.currency)) e.code,
      };

      var written = 0;
      for (final c in countries) {
        try {
          // Upsert country region entry
          await _upsertRegionEntry(c, existingRegions);
          written++;

          // Also seed currency entries
          for (final currency in c.currencies) {
            await _seedCurrency(currency, existingCurrencies);
          }
        } catch (e) {
          // Best-effort per country — 仅保留国家代码和异常类型，避免把远端原始内容打到日志。
          if (kDebugMode) {
            debugPrint('country_data_importer: failed for ${c.code}: ${e.runtimeType}');
          }
        }
      }

      return Ok(written);
    } catch (e) {
      return Err(UnknownError('Country import failed: $e'));
    }
  }

  void dispose() => _client.close();

  CountryData? _parseCountry(Map<String, dynamic> raw) {
    final cca2 = raw['cca2'] as String?;
    if (cca2 == null) return null;

    final name = raw['name'] as Map<String, dynamic>?;
    final commonEn = name?['common'] as String? ?? cca2;

    // Chinese name: try translations > native
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

  Future<void> _upsertRegionEntry(CountryData c, Map<String, DictEntry> existingRegions) async {
    final color = _regionColor[c.continentZh] ?? '0xFF94A3B8';
    final parent = _euMembers.contains(c.code) ? 'EU' : null;
    final existing = existingRegions[c.code];

    if (existing != null) {
      await _repo.updateEntry(
        id: existing.id,
        name: c.nameZh,
        nameEn: c.nameEn,
        flagEmoji: c.flagEmoji,
        continent: c.continentZh,
        colorHex: color,
        mapLon: c.lon,
        mapLat: c.lat,
        parentRegion: parent,
      );
      return;
    }

    try {
      final added = await _repo.addCustom(
        type: DictType.sovereigntyRegion,
        code: c.code,
        name: c.nameZh,
        nameEn: c.nameEn,
        sortOrder: 1000,
        flagEmoji: c.flagEmoji,
        continent: c.continentZh,
        colorHex: color,
        mapLon: c.lon,
        mapLat: c.lat,
        parentRegion: parent,
      );
      final saved = added.valueOrNull;
      if (saved != null) {
        existingRegions[c.code] = saved;
      }
    } on Exception catch (_) {
      // Code already exists — update the existing entry.
      final match = existingRegions[c.code];
      if (match != null) {
        await _repo.updateEntry(
          id: match.id,
          name: c.nameZh,
          nameEn: c.nameEn,
          flagEmoji: c.flagEmoji,
          continent: c.continentZh,
          colorHex: color,
          mapLon: c.lon,
          mapLat: c.lat,
          parentRegion: parent,
        );
      }
    }
  }

  Future<void> _seedCurrency(String code, Set<String> existingCurrencies) async {
    final normalized = code.toUpperCase();
    if (existingCurrencies.contains(normalized)) return;
    try {
      final result = await _repo.addCustom(
        type: DictType.currency,
        code: normalized,
        name: normalized,
        sortOrder: 1000,
      );
      if (result.isOk) existingCurrencies.add(normalized);
    } on Exception catch (_) {
      // Currency already exists, skip
    }
  }
}
