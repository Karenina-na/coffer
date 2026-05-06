import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../../domain/providers/asset_price_provider.dart';
import '../network_error.dart';

/// 基于 OKX 公开 API v5 的加密货币价格源（免 API Key，支持现货与衍生品）。
///
/// 支持的 symbol 形式：
/// - 现货（默认）：`BTC`、`ETH`、`SOL` → `BTC-USDT`、`ETH-USDT`…
/// - 永续合约：`BTC-PERP`、`ETH-PERP` → `BTC-USD-SWAP`、`ETH-USD-SWAP`…
/// - Yahoo 风格：`BTC-USD` → `BTC-USDT`（剥离 `-USD` 后缀）
///
/// 端点：
/// - 最新价：`GET /api/v5/market/ticker`
/// - 历史 K 线：`GET /api/v5/market/candles`
///
/// 公开端点限速约 20 req / 2s（轻量使用无限流风险）；
/// 本 provider 目前只支持 USDT 计价对，用于行情补充。
class OkxProvider implements AssetPriceProvider {
  OkxProvider({http.Client? client})
      : _client = client ?? http.Client();

  static const _host = 'www.okx.com';
  static const _timeout = Duration(seconds: 12);
  static const _source = 'okx';

  final http.Client _client;

  void dispose() => _client.close();

  /// 将用户侧 symbol 转换为 OKX instId。
  ///
  /// 仅做格式层面的清理与映射；不做业务层面的币种白名单校验——
  /// 资产分类（现货 / 衍生品 / 股票等）由上游 AssetValuator 的路由逻辑负责。
  ///
  /// - `BTC` / `ETH` → `BTC-USDT`（默认现货）
  /// - `BTC-PERP` / `ETH-PERP` → `BTC-USD-SWAP`（永续）
  /// - `BTC-USD` → `BTC-USDT`（剥离 `-USD` 后缀）
  ///
  /// 返回 null 仅当输入格式明显无效（含特殊字符 / 过长）。
  static String? _resolveInstId(String raw) {
    final s = raw.trim().toUpperCase();
    if (s.isEmpty || s.length > 10) return null;

    // 仅允许大写字母+数字+短横线
    if (RegExp(r'^[A-Z0-9]+(-[A-Z0-9]+)?$').firstMatch(s) == null) return null;

    // 永续合约
    if (s.endsWith('-PERP')) {
      final base = s.substring(0, s.length - 5);
      return '$base-USD-SWAP';
    }

    // Yahoo 风格 `BTC-USD` / `BTC-USDT` → BTC-USDT 现货
    final base = s.replaceFirst(RegExp(r'-(USD|USDT)$'), '');

    // 默认现货
    return '$base-USDT';
  }

  @override
  Future<Result<AssetQuote, AppError>> fetchLatest(String symbol) async {
    final instId = _resolveInstId(symbol);
    if (instId == null) {
      return Err(NotFoundError('okx: unsupported symbol $symbol'));
    }

    final uri = Uri.https(_host, '/api/v5/market/ticker', {
      'instId': instId,
    });

    try {
      final resp = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);

      if (resp.statusCode != 200) {
        return Err(classifyHttpStatus(_source, resp.statusCode, resp.body));
      }

      final json = jsonDecode(resp.body) as Map<String, dynamic>?;
      final code = json?['code'] as String?;
      if (code != '0') {
        final msg = json?['msg'] as String? ?? 'unknown';
        return Err(NetworkError('okx: $msg', kind: NetworkErrorKind.malformedResponse));
      }

      final data = json?['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) {
        return Err(NotFoundError('okx: no ticker data for $instId'));
      }

      final ticker = data[0] as Map<String, dynamic>?;
      if (ticker == null) {
        return Err(NotFoundError('okx: no ticker data for $instId'));
      }

      final lastStr = ticker['last'] as String?;
      if (lastStr == null || lastStr.isEmpty) {
        return const Err(
          NetworkError('okx: missing last price', kind: NetworkErrorKind.malformedResponse),
        );
      }
      final price = Decimal.parse(lastStr);

      final ts = ticker['ts'] as String?;
      final asOf = ts != null
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(ts), isUtc: true)
          : DateTime.now().toUtc();

      return Ok(
        AssetQuote(
          symbol: symbol.toUpperCase(),
          price: price,
          currency: 'USD',
          asOfTime: asOf,
          source: _source,
          rawPayload: resp.body,
        ),
      );
    } catch (e) {
      return Err(classifyNetworkException(_source, e));
    }
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> fetchTimeSeries({
    required String symbol,
    required DateTime from,
    required DateTime to,
  }) async {
    final instId = _resolveInstId(symbol);
    if (instId == null) {
      return Err(NotFoundError('okx: unsupported symbol $symbol'));
    }

    final uri = Uri.https(_host, '/api/v5/market/candles', {
      'instId': instId,
      'bar': '1D',
      'after': '${from.millisecondsSinceEpoch}',
      'before': '${to.millisecondsSinceEpoch}',
      'limit': '300',
    });

    try {
      final resp = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);

      if (resp.statusCode != 200) {
        return Err(classifyHttpStatus(_source, resp.statusCode, resp.body));
      }

      final json = jsonDecode(resp.body) as Map<String, dynamic>?;
      final code = json?['code'] as String?;
      if (code != '0') {
        final msg = json?['msg'] as String? ?? 'unknown';
        return Err(NetworkError('okx: $msg', kind: NetworkErrorKind.malformedResponse));
      }

      final data = json?['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) {
        return Err(NotFoundError('okx: empty candle series for $instId'));
      }

      final points = <AssetPricePoint>[];
      for (final candle in data) {
        final row = candle as List<dynamic>;
        if (row.length < 5) continue;
        final ts = (row[0] as String);
        // close price is row[4]
        final p = row[4] as String?;
        if (p == null || p.isEmpty) continue;
        points.add(
          AssetPricePoint(
            t: DateTime.fromMillisecondsSinceEpoch(int.parse(ts), isUtc: true),
            price: Decimal.parse(p),
            currency: 'USD',
          ),
        );
      }
      if (points.isEmpty) {
        return Err(NotFoundError('okx: empty price series for $instId'));
      }

      // OKX 返回倒序（新→旧），按时间升序返回
      points.sort((a, b) => a.t.compareTo(b.t));

      return Ok(
        AssetPriceSeries(
          symbol: symbol.toUpperCase(),
          currency: 'USD',
          points: points,
          source: _source,
        ),
      );
    } catch (e) {
      return Err(classifyNetworkException(_source, e));
    }
  }
}
