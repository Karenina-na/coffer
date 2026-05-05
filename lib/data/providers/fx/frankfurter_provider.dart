import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../../domain/providers/fx_rate_provider.dart';
import '../network_error.dart';

/// 调用 Frankfurter 公开汇率 API。无需 API Key，无限额。
///
/// 仅返回解析后的快照；持久化由上层 UseCase 完成。
///
/// 端点约定：
/// - 最新：`https://api.frankfurter.dev/v1/latest?base=USD&symbols=CNY,JPY`
///   返回：`{ "amount":1.0, "base":"USD", "date":"YYYY-MM-DD", "rates":{...} }`
/// - 时间序列：`/v1/2025-01-01..2025-01-07?base=USD&symbols=CNY`
///   返回：`{ "base":"USD", "start_date":"...", "end_date":"...",
///              "rates":{"2025-01-02":{"CNY":7.23}, ...} }`
class FrankfurterProvider implements FxRateProvider {
  FrankfurterProvider({http.Client? client})
    : _client = client ?? http.Client();

  static const _host = 'api.frankfurter.dev';
  static const _path = '/v1/latest';
  static const _timeout = Duration(seconds: 10);

  final http.Client _client;

  @override
  Future<Result<FxSnapshot, AppError>> fetchLatest({
    required String base,
    required List<String> symbols,
  }) async {
    final b = base.trim().toUpperCase();
    final syms = symbols
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty && s != b)
        .toSet()
        .toList();
    if (b.isEmpty) {
      return const Err(ValidationError('base currency empty'));
    }
    if (syms.isEmpty) {
      return const Err(ValidationError('no symbols to fetch'));
    }

    final uri = Uri.https(_host, _path, {'base': b, 'symbols': syms.join(',')});

    try {
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) {
        return Err(
          classifyHttpStatus('frankfurter', resp.statusCode, resp.body),
        );
      }
      final body = resp.body;
      final json = jsonDecode(body) as Map<String, dynamic>;
      final dateStr = json['date'] as String?;
      final ratesMap = json['rates'] as Map<String, dynamic>?;
      if (dateStr == null || ratesMap == null) {
        return Err(
          NetworkError(
            'frankfurter malformed: $body',
            kind: NetworkErrorKind.malformedResponse,
          ),
        );
      }
      final date = DateTime.tryParse(dateStr);
      if (date == null) {
        return Err(
          NetworkError(
            'frankfurter malformed: invalid date "$dateStr"',
            kind: NetworkErrorKind.malformedResponse,
          ),
        );
      }
      final ratesResult = _readPositiveRates(
        ratesMap: ratesMap,
        requestedSymbols: syms,
        providerName: 'frankfurter',
        body: body,
      );
      if (ratesResult.isErr) return Err(ratesResult.errorOrNull!);
      return Ok(
        FxSnapshot(
          base: (json['base'] as String? ?? b).toUpperCase(),
          date: date,
          rates: ratesResult.valueOrNull!,
          rawPayload: body,
        ),
      );
    } catch (e) {
      return Err(classifyNetworkException('frankfurter', e));
    }
  }

  void dispose() => _client.close();

  /// 拉取 [from] → [to] 之间的时间序列（含边界）。用于 sparkline 走势图。
  @override
  Future<Result<FxTimeSeries, AppError>> fetchTimeSeries({
    required String base,
    required List<String> symbols,
    required DateTime from,
    required DateTime to,
  }) async {
    final b = base.trim().toUpperCase();
    final syms = symbols
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty && s != b)
        .toSet()
        .toList();
    if (b.isEmpty || syms.isEmpty) {
      return const Err(ValidationError('empty base or symbols'));
    }
    String fmtDate(DateTime d) {
      String p(int n) => n.toString().padLeft(2, '0');
      return '${d.year}-${p(d.month)}-${p(d.day)}';
    }

    final path = '/v1/${fmtDate(from)}..${fmtDate(to)}';
    final uri = Uri.https(_host, path, {'base': b, 'symbols': syms.join(',')});
    try {
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) {
        return Err(
          classifyHttpStatus('frankfurter', resp.statusCode, resp.body),
        );
      }
      final body = resp.body;
      final json = jsonDecode(body) as Map<String, dynamic>;
      final ratesMap = json['rates'] as Map<String, dynamic>?;
      if (ratesMap == null) {
        return Err(
          NetworkError(
            'frankfurter malformed: $body',
            kind: NetworkErrorKind.malformedResponse,
          ),
        );
      }
      final entries = <MapEntry<DateTime, Map<String, Decimal>>>[];
      final keys = ratesMap.keys.toList()..sort();
      for (final k in keys) {
        final date = DateTime.tryParse(k);
        final inner = ratesMap[k];
        if (date == null || inner is! Map<String, dynamic>) continue;
        final dailyResult = _readPositiveRates(
          ratesMap: inner,
          requestedSymbols: syms,
          providerName: 'frankfurter-timeseries',
          body: body,
        );
        if (dailyResult.isErr) return Err(dailyResult.errorOrNull!);
        entries.add(MapEntry(date, dailyResult.valueOrNull!));
      }
      return Ok(
        FxTimeSeries(
          base: (json['base'] as String? ?? b).toUpperCase(),
          series: entries,
          rawPayload: body,
        ),
      );
    } catch (e) {
      return Err(classifyNetworkException('frankfurter-timeseries', e));
    }
  }

  Result<Map<String, Decimal>, AppError> _readPositiveRates({
    required Map<String, dynamic> ratesMap,
    required Iterable<String> requestedSymbols,
    required String providerName,
    required String body,
  }) {
    final requested = requestedSymbols.map((s) => s.toUpperCase()).toSet();
    final rates = <String, Decimal>{};
    for (final entry in ratesMap.entries) {
      final symbol = entry.key.toUpperCase();
      final parsed = Decimal.tryParse(entry.value.toString());
      if (parsed == null || parsed <= Decimal.zero) {
        if (requested.contains(symbol)) {
          return Err(
            NetworkError(
              '$providerName malformed: non-positive or invalid rate for $symbol: $body',
              kind: NetworkErrorKind.malformedResponse,
            ),
          );
        }
        continue;
      }
      rates[symbol] = parsed;
    }
    return Ok(rates);
  }
}
