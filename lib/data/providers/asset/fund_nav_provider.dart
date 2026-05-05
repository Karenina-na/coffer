import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../../domain/providers/asset_price_provider.dart';
import '../network_error.dart';

/// 基金净值数据源，支持大陆 / 香港 / 全球基金。
///
/// ## 支持范围
///
/// | 地区 | 代码格式 | 示例 | API |
/// |------|---------|------|-----|
/// | 大陆 | 6 位数字 | `110011`、`161725` | 东方财富基金接口 |
/// | 香港 | `XXXXX.HK` | `0001.HK`（盈富基金）| Yahoo Finance |
/// | 全球 | Yahoo ticker | `VFIAX`、`0P0000T5IY.L` | Yahoo Finance |
///
/// ## 大陆基金代码规则
///
/// - 6 位纯数字，且**不在**沪深股票代码空间内（非 60xxxx/68xxxx/00xxxx/30xxxx）
/// - 常见前缀：`0`（货基/债基）、`1`（混合/股票）、`2`（债券/保本）、
///   `3`（专户）、`4`（三板）、`5`（ETF/LOF）、`6`（科创/北交）、
///   `7`（配售）、`8`（北交所）、`9`（B 类货基）
/// - 实际判断：以 `1`、`0`、`2`、`3`、`4`、`5`、`6`、`7`、`8`、`9` 开头的 6 位数字，
///   但排除沪深股票代码空间
class FundNavProvider implements AssetPriceProvider {
  FundNavProvider({http.Client? client})
      : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 10);
  static const _source = 'fund';
  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (GWP)',
    'Referer': 'https://fund.eastmoney.com/',
  };

  final http.Client _client;

  void dispose() => _client.close();

  /// 判断 symbol 是否可能是基金代码。
  ///
  /// 用于 [CompositeAssetPriceProvider] 在路由时决定是否尝试本 provider。
  static bool looksLikeFund(String symbol) {
    final s = symbol.trim();
    // 大陆基金：6 位数字，且不在沪深股票代码空间
    if (RegExp(r'^\d{6}$').hasMatch(s)) {
      return _isCnFundCode(s);
    }
    // 香港基金：5 位数字 + .HK
    if (RegExp(r'^\d{4,5}\.HK$', caseSensitive: false).hasMatch(s)) {
      return true;
    }
    // 全球基金 ticker：字母开头，长度 3-12，可含点号
    if (RegExp(r'^[A-Za-z][A-Za-z0-9.\-]{2,11}$').hasMatch(s) &&
        !RegExp(r'^[A-Z]{1,5}$').hasMatch(s)) {
      // 排除纯大写短 ticker（股票），基金 ticker 通常含小写或更长
      return true;
    }
    return false;
  }

  /// 判断 6 位数字是否为大陆基金代码（排除沪深股票）。
  static bool _isCnFundCode(String code) {
    // 沪市股票：600xxx, 601xxx, 603xxx, 605xxx, 688xxx (科创板)
    if (code.startsWith('600') ||
        code.startsWith('601') ||
        code.startsWith('603') ||
        code.startsWith('605') ||
        code.startsWith('688')) {
      return false;
    }
    // 深市股票：000xxx, 001xxx, 002xxx, 003xxx, 300xxx (创业板)
    if (code.startsWith('000') ||
        code.startsWith('001') ||
        code.startsWith('002') ||
        code.startsWith('003') ||
        code.startsWith('300')) {
      return false;
    }
    // 北交所：8xxxxx 且以 83/87/88 开头的主要是股票，基金较少
    // 保留为基金候选，由 API 判断
    return true;
  }

  @override
  Future<Result<AssetQuote, AppError>> fetchLatest(String symbol) async {
    final s = symbol.trim();
    if (s.isEmpty) return const Err(ValidationError('symbol empty'));

    // 大陆基金
    if (RegExp(r'^\d{6}$').hasMatch(s) && _isCnFundCode(s)) {
      return _fetchCnFundNav(s);
    }

    // 香港基金：5 位数字 + .HK
    if (RegExp(r'^\d{4,5}\.HK$', caseSensitive: false).hasMatch(s)) {
      return _fetchYahooNav(s);
    }

    // 全球基金 ticker：含小写字母或较长的 ticker
    if (looksLikeFund(s)) {
      return _fetchYahooNav(s);
    }

    // 不是基金代码，跳过
    return Err(NotFoundError('fund: not a fund symbol: $s'));
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> fetchTimeSeries({
    required String symbol,
    required DateTime from,
    required DateTime to,
  }) async {
    final s = symbol.trim();
    if (s.isEmpty) return const Err(ValidationError('symbol empty'));

    // 大陆基金历史净值
    if (RegExp(r'^\d{6}$').hasMatch(s) && _isCnFundCode(s)) {
      return _fetchCnFundHistory(s, from: from, to: to);
    }

    // 香港基金
    if (RegExp(r'^\d{4,5}\.HK$', caseSensitive: false).hasMatch(s)) {
      return _fetchYahooHistory(s, from: from, to: to);
    }

    // 全球基金 ticker
    if (looksLikeFund(s)) {
      return _fetchYahooHistory(s, from: from, to: to);
    }

    // 不是基金代码，跳过
    return Err(NotFoundError('fund: not a fund symbol: $s'));
  }

  // ════════════════════════════════════════════════════════════════
  // 大陆基金 — 东方财富基金接口
  // ════════════════════════════════════════════════════════════════

  /// 获取大陆基金最新净值。
  ///
  /// 使用东方财富基金估值接口：
  /// `https://fundgz.1702502d.com/js/{code}.js`
  ///
  /// 返回 JSONP 格式：`jsonpgz({...})`
  /// 字段说明：
  /// - `fundcode`: 基金代码
  /// - `name`: 基金名称
  /// - `dwjz`: 单位净值
  /// - `gsz`: 估算净值
  /// - `gszzl`: 估算涨跌幅
  /// - `gztime`: 估算时间
  Future<Result<AssetQuote, AppError>> _fetchCnFundNav(String code) async {
    final uri = Uri.https('fundgz.1702502d.com', '/js/$code.js');
    try {
      final resp =
          await _client.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) {
        return Err(
            classifyHttpStatus('fund-cn', resp.statusCode, resp.body));
      }
      final body = resp.body;
      // 解析 JSONP: jsonpgz({...})
      final jsonStr = _extractJsonp(body);
      if (jsonStr == null) {
        return const Err(NetworkError(
          'fund-cn: invalid JSONP response',
          kind: NetworkErrorKind.malformedResponse,
        ));
      }
      Map<String, dynamic> data;
      try {
        data = jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        return Err(NetworkError(
          'fund-cn: failed to parse JSON: $e',
          kind: NetworkErrorKind.malformedResponse,
        ));
      }
      final navStr = data['dwjz'] as String? ?? data['gsz'] as String?;
      if (navStr == null || navStr.isEmpty) {
        return const Err(NetworkError(
          'fund-cn: missing NAV in response',
          kind: NetworkErrorKind.malformedResponse,
        ));
      }
      final nav = Decimal.tryParse(navStr);
      if (nav == null) {
        return Err(NetworkError(
          'fund-cn: invalid NAV value: $navStr',
          kind: NetworkErrorKind.malformedResponse,
        ));
      }
      final name = data['name'] as String? ?? code;
      final gzTime = data['gztime'] as String?;
      final asOf = _parseCnFundTime(gzTime) ?? DateTime.now().toUtc();
      return Ok(AssetQuote(
        symbol: code,
        price: nav,
        currency: 'CNY',
        asOfTime: asOf,
        source: _source,
        rawPayload: body,
      ));
    } catch (e) {
      return Err(classifyNetworkException('fund-cn', e));
    }
  }

  /// 获取大陆基金历史净值。
  ///
  /// 使用东方财富基金历史接口：
  /// `https://push2his.eastmoney.com/api/qt/fund/kline/get`
  Future<Result<AssetPriceSeries, AppError>> _fetchCnFundHistory(
    String code, {
    required DateTime from,
    required DateTime to,
  }) async {
    final fromStr = _formatDate(from);
    final toStr = _formatDate(to);
    final uri =
        Uri.https('push2his.eastmoney.com', '/api/qt/fund/kline/get', {
      'fields1': 'f1,f2,f3,f4,f5',
      'fields2': 'f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61',
      'klt': '101', // 日频
      'fqt': '1',
      'code': code,
      'beg': fromStr,
      'end': toStr,
    });
    try {
      final resp =
          await _client.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) {
        return Err(
            classifyHttpStatus('fund-cn', resp.statusCode, resp.body));
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return const Err(NotFoundError('fund-cn: no data for this code'));
      }
      final klines = data['klines'] as List<dynamic>?;
      if (klines == null || klines.isEmpty) {
        return const Err(NotFoundError('fund-cn: no history data'));
      }
      final points = <AssetPricePoint>[];
      for (final k in klines) {
        final parts = (k as String).split(',');
        if (parts.length < 3) continue;
        final date = DateTime.tryParse(parts[0]);
        final close = Decimal.tryParse(parts[2]);
        if (date != null && close != null) {
          points.add(AssetPricePoint(
            t: date.toUtc(),
            price: close,
            currency: 'CNY',
          ));
        }
      }
      if (points.isEmpty) {
        return const Err(NotFoundError('fund-cn: no valid data points'));
      }
      return Ok(AssetPriceSeries(
        symbol: code,
        currency: 'CNY',
        points: points,
        source: _source,
      ));
    } catch (e) {
      return Err(classifyNetworkException('fund-cn', e));
    }
  }

  // ════════════════════════════════════════════════════════════════
  // 香港 / 全球基金 — Yahoo Finance
  // ════════════════════════════════════════════════════════════════

  /// 通过 Yahoo Finance 获取基金最新净值。
  ///
  /// 香港基金 ticker 格式：`XXXXX.HK`（如 `0001.HK` 盈富基金）
  /// 全球基金 ticker：直接使用 Yahoo Finance 的 ticker（如 `VFIAX`）
  Future<Result<AssetQuote, AppError>> _fetchYahooNav(String symbol) async {
    // Yahoo Finance ticker 映射
    final ticker = _toYahooTicker(symbol);
    final uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/$ticker',
      const {'interval': '1d', 'range': '5d'},
    );
    try {
      final resp = await _client
          .get(uri, headers: const {'User-Agent': 'Mozilla/5.0 (GWP)'})
          .timeout(_timeout);
      final body = resp.body;
      final contentType = resp.headers['content-type'] ?? '';
      if (contentType.contains('text/html') &&
          (body.contains('中国大陆') || body.contains('G.F.W'))) {
        return const Err(NetworkError(
          'fund-yahoo blocked: Yahoo Finance 在中国大陆不可用',
          kind: NetworkErrorKind.connectivity,
        ));
      }
      if (resp.statusCode != 200) {
        return Err(
            classifyHttpStatus('fund-yahoo', resp.statusCode, body));
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final chart = json['chart'] as Map<String, dynamic>?;
      if (chart == null) {
        return const Err(NetworkError(
          'fund-yahoo: missing chart data',
          kind: NetworkErrorKind.malformedResponse,
        ));
      }
      final result = (chart['result'] as List<dynamic>?)?.firstOrNull
          as Map<String, dynamic>?;
      if (result == null) {
        return Err(NotFoundError('fund-yahoo: symbol not found: $symbol'));
      }
      final meta = result['meta'] as Map<String, dynamic>;
      final priceRaw = meta['regularMarketPrice'] as num?;
      if (priceRaw == null) {
        return const Err(NetworkError(
          'fund-yahoo: missing price',
          kind: NetworkErrorKind.malformedResponse,
        ));
      }
      final price = Decimal.parse(priceRaw.toString());
      final currency = (meta['currency'] as String?) ?? 'USD';
      final ts = meta['regularMarketTime'] as int?;
      final asOf = ts != null
          ? DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true)
          : DateTime.now().toUtc();
      return Ok(AssetQuote(
        symbol: symbol,
        price: price,
        currency: currency,
        asOfTime: asOf,
        source: 'fund-yahoo',
        rawPayload: body,
      ));
    } catch (e) {
      return Err(classifyNetworkException('fund-yahoo', e));
    }
  }

  /// 通过 Yahoo Finance 获取基金历史净值。
  Future<Result<AssetPriceSeries, AppError>> _fetchYahooHistory(
    String symbol, {
    required DateTime from,
    required DateTime to,
  }) async {
    final ticker = _toYahooTicker(symbol);
    final period1 = from.millisecondsSinceEpoch ~/ 1000;
    final period2 = to.millisecondsSinceEpoch ~/ 1000;
    final uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/$ticker',
      {
        'interval': '1d',
        'period1': period1.toString(),
        'period2': period2.toString(),
      },
    );
    try {
      final resp = await _client
          .get(uri, headers: const {'User-Agent': 'Mozilla/5.0 (GWP)'})
          .timeout(_timeout);
      if (resp.statusCode != 200) {
        return Err(
            classifyHttpStatus('fund-yahoo', resp.statusCode, resp.body));
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final chart = json['chart'] as Map<String, dynamic>?;
      final result = (chart?['result'] as List<dynamic>?)?.firstOrNull
          as Map<String, dynamic>?;
      if (result == null) {
        return Err(NotFoundError('fund-yahoo: no data for $symbol'));
      }
      final timestamps = result['timestamp'] as List<dynamic>?;
      final indicators = result['indicators'] as Map<String, dynamic>?;
      final quotes =
          (indicators?['quote'] as List<dynamic>?)?.firstOrNull
              as Map<String, dynamic>?;
      if (timestamps == null || quotes == null) {
        return const Err(NetworkError(
          'fund-yahoo: missing time series data',
          kind: NetworkErrorKind.malformedResponse,
        ));
      }
      final closes = quotes['close'] as List<dynamic>?;
      final currency = (result['meta'] as Map<String, dynamic>?)?['currency']
              as String? ??
          'USD';
      final points = <AssetPricePoint>[];
      for (var i = 0; i < timestamps.length; i++) {
        final ts = timestamps[i] as int?;
        final close = closes != null && i < closes.length
            ? closes[i] as num?
            : null;
        if (ts != null && close != null) {
          points.add(AssetPricePoint(
            t: DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true),
            price: Decimal.parse(close.toString()),
            currency: currency,
          ));
        }
      }
      if (points.isEmpty) {
        return const Err(NotFoundError('fund-yahoo: no valid data points'));
      }
      return Ok(AssetPriceSeries(
        symbol: symbol,
        currency: currency,
        points: points,
        source: 'fund-yahoo',
      ));
    } catch (e) {
      return Err(classifyNetworkException('fund-yahoo', e));
    }
  }

  // ════════════════════════════════════════════════════════════════
  // 工具方法
  // ════════════════════════════════════════════════════════════════

  /// 将 symbol 转换为 Yahoo Finance ticker。
  ///
  /// - `0001.HK` → `0001.HK`（直接使用）
  /// - `VFIAX` → `VFIAX`（直接使用）
  /// - 其他 → 原样返回
  String _toYahooTicker(String symbol) {
    final s = symbol.trim();
    // 已经是 Yahoo 格式
    if (s.contains('.')) return s.toUpperCase();
    return s.toUpperCase();
  }

  /// 从 JSONP 响应中提取 JSON 字符串。
  ///
  /// 格式：`jsonpgz({...})` → `{...}`
  String? _extractJsonp(String body) {
    // 查找第一个 { 和最后一个 }
    final start = body.indexOf('{');
    final end = body.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return body.substring(start, end + 1);
  }

  /// 解析大陆基金时间字符串。
  ///
  /// 格式：`2024-01-15 15:00` → DateTime (UTC)
  DateTime? _parseCnFundTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      // 格式：2024-01-15 15:00
      final parts = timeStr.split(' ');
      if (parts.length != 2) return null;
      final dateParts = parts[0].split('-');
      final timeParts = parts[1].split(':');
      if (dateParts.length != 3 || timeParts.length != 2) return null;
      return DateTime.utc(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  /// 格式化日期为 `yyyyMMdd`。
  String _formatDate(DateTime dt) {
    return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
  }
}
