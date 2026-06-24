import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../../domain/providers/asset_price_provider.dart';
import '../network_error.dart';

/// 基于东方财富公开行情接口的资产价格源（免认证、国内直连）。
///
/// - 最新价：`https://push2.eastmoney.com/api/qt/stock/get`
/// - 日 K 线：`https://push2his.eastmoney.com/api/qt/stock/kline/get`
///
/// 东方财富使用 `secid = 市场前缀.代码`：
///
///   前缀  市场
///   1     上交所（股/ETF/可转债/国债）
///   0     深交所 / 北交所
///   116   香港联交所
///   105   美股 NASDAQ
///   106   美股 NYSE
///   107   美股 AMEX
///   100   伦敦 LSE
///   155   东京证交所
///   153   新加坡交易所
///   154   韩国交易所
///
/// 输入 symbol 可以是：
/// - `0700.HK`（港股，补零到 5 位）
/// - `600519.SS` / `600519.SH`（沪）
/// - `000001.SZ`（深）
/// - `AAPL`（美股，自动尝试 105/106/107）
/// - `AAPL.US`（同上）
/// - `105.AAPL` / `116.00700`（直接传 secid，优先使用）
class EastmoneyProvider implements AssetPriceProvider {
  EastmoneyProvider({http.Client? client}) : _client = client ?? http.Client();

  static const _quoteHost = 'push2delay.eastmoney.com';
  static const _klineHost = 'push2his.eastmoney.com';
  static const _timeout = Duration(seconds: 10);
  static const _source = 'eastmoney';

  final http.Client _client;

  /// 报价字段清单：
  /// f43 当前价；f58 名称；f59 价格小数位数；f60 昨收；f86 行情时间戳(秒)
  static const _quoteFields = 'f43,f58,f59,f60,f86,f162,f169,f170';

  /// K 线字段：
  /// fields2=f51 时间；f52 开盘；f53 收盘；f54 最高；f55 最低；f56 成交量
  static const _klineFields1 = 'f1,f2,f3,f4,f5,f6';
  static const _klineFields2 = 'f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61';

  void dispose() => _client.close();

  @override
  Future<Result<AssetQuote, AppError>> fetchLatest(String symbol) async {
    final s = symbol.trim();
    if (s.isEmpty) return const Err(ValidationError('symbol empty'));
    final candidates = _resolveSecIds(s);
    if (candidates.isEmpty) {
      return const Err(NotFoundError('eastmoney: unsupported symbol'));
    }

    AppError lastErr = const NotFoundError('eastmoney: no candidate matched');
    for (final sec in candidates) {
      final r = await _fetchLatestBySecId(sec, originalSymbol: s);
      if (r.isOk) return r;
      lastErr = r.errorOrNull!;
    }
    return Err(lastErr);
  }

  Future<Result<AssetQuote, AppError>> _fetchLatestBySecId(
    String secid, {
    required String originalSymbol,
  }) async {
    final uri = Uri.https(_quoteHost, '/api/qt/stock/get', {
      'secid': secid,
      'fields': _quoteFields,
      'fltt': '2',
      'invt': '2',
    });
    try {
      final resp = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) {
        return Err(classifyHttpStatus('eastmoney', resp.statusCode, resp.body));
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'];
      if (data is! Map<String, dynamic>) {
        return const Err(NotFoundError('eastmoney: symbol not found'));
      }
      final f43 = data['f43'];
      if (f43 == null || f43 == '-') {
        return const Err(NotFoundError('eastmoney: no price for secid'));
      }
      final priceRaw = Decimal.tryParse(f43.toString());
      if (priceRaw == null) {
        return Err(
          NetworkError(
            'eastmoney malformed price: $f43',
            kind: NetworkErrorKind.malformedResponse,
          ),
        );
      }
      // fltt=2 返回已缩放价格，无需再除以 10^f59。
      final ts = (data['f86'] as num?)?.toInt();
      final asOf = ts != null && ts > 0
          ? DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true)
          : DateTime.now().toUtc();
      final currency = _currencyForSecIdPrefix(secid.split('.').first);
      return Ok(
        AssetQuote(
          symbol: originalSymbol,
          price: priceRaw,
          currency: currency,
          asOfTime: asOf,
          source: _source,
          rawPayload: resp.body,
        ),
      );
    } catch (e) {
      return Err(classifyNetworkException('eastmoney', e));
    }
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> fetchTimeSeries({
    required String symbol,
    required DateTime from,
    required DateTime to,
  }) async {
    final s = symbol.trim();
    if (s.isEmpty) return const Err(ValidationError('symbol empty'));
    if (!to.isAfter(from)) {
      return const Err(ValidationError('to must be after from'));
    }
    final candidates = _resolveSecIds(s);
    if (candidates.isEmpty) {
      return const Err(NotFoundError('eastmoney: unsupported symbol'));
    }

    AppError lastErr = const NotFoundError('eastmoney: no candidate matched');
    for (final sec in candidates) {
      final r = await _fetchSeriesBySecId(
        sec,
        originalSymbol: s,
        from: from,
        to: to,
      );
      if (r.isOk) return r;
      lastErr = r.errorOrNull!;
    }
    return Err(lastErr);
  }

  Future<Result<AssetPriceSeries, AppError>> _fetchSeriesBySecId(
    String secid, {
    required String originalSymbol,
    required DateTime from,
    required DateTime to,
  }) async {
    final beg = _fmtDate(from);
    final end = _fmtDate(to);
    // klt=101 日线；fqt=1 前复权
    final uri = Uri.https(_klineHost, '/api/qt/stock/kline/get', {
      'secid': secid,
      'fields1': _klineFields1,
      'fields2': _klineFields2,
      'klt': '101',
      'fqt': '1',
      'beg': beg,
      'end': end,
    });
    try {
      final resp = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) {
        return Err(classifyHttpStatus('eastmoney', resp.statusCode, resp.body));
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'];
      if (data is! Map<String, dynamic>) {
        return const Err(NotFoundError('eastmoney: klines not found'));
      }
      final klines = (data['klines'] as List<dynamic>?) ?? const [];
      if (klines.isEmpty) {
        return const Err(NotFoundError('eastmoney: empty klines'));
      }
      final currency = _currencyForSecIdPrefix(secid.split('.').first);
      final points = <AssetPricePoint>[];
      for (final raw in klines) {
        if (raw is! String) continue;
        final cols = raw.split(',');
        if (cols.length < 3) continue;
        final date = DateTime.tryParse(cols[0]);
        final close = Decimal.tryParse(cols[2]);
        if (date == null || close == null) continue;
        if (close <= Decimal.zero) {
          return const Err(
            NetworkError(
              'eastmoney malformed: non-positive kline close price',
              kind: NetworkErrorKind.malformedResponse,
            ),
          );
        }
        points.add(
          AssetPricePoint(
            t: DateTime(date.year, date.month, date.day),
            price: close,
            currency: currency,
          ),
        );
      }
      if (points.isEmpty) {
        return const Err(NotFoundError('eastmoney: no valid kline rows'));
      }
      return Ok(
        AssetPriceSeries(
          symbol: originalSymbol,
          currency: currency,
          points: points,
          source: _source,
        ),
      );
    } catch (e) {
      return Err(classifyNetworkException('eastmoney-timeseries', e));
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (Coffer)',
    'Referer': 'https://quote.eastmoney.com/',
  };

  /// 把用户输入的 symbol 解析为一到多个 `secid` 候选。
  ///
  /// 若无法识别，返回空列表，上层将回退到其他 provider。
  List<String> _resolveSecIds(String symbol) {
    final s = symbol.trim();
    if (s.isEmpty) return const [];

    // 1) 已是 `前缀.代码` 形式（例如 `116.00700`）—— 直接透传
    final direct = RegExp(
      r'^(1|0|116|105|106|107|100|155|153|154)\.[A-Za-z0-9]+$',
    );
    if (direct.hasMatch(s)) return [s];

    // 2) `代码.后缀` 形式
    final dotIdx = s.lastIndexOf('.');
    if (dotIdx > 0) {
      final code = s.substring(0, dotIdx);
      final suffix = s.substring(dotIdx + 1).toUpperCase();
      switch (suffix) {
        case 'HK':
          return ['116.${code.padLeft(5, '0')}'];
        case 'SS':
        case 'SH':
          return ['1.$code'];
        case 'SZ':
          return ['0.$code'];
        case 'BJ':
          return ['0.$code'];
        case 'L':
        case 'LSE':
          return ['100.$code'];
        case 'T':
        case 'JP':
          return ['155.$code'];
        case 'SI':
        case 'SG':
          return ['153.$code'];
        case 'KS':
        case 'KR':
          return ['154.$code'];
        case 'US':
          return ['105.$code', '106.$code', '107.$code'];
        default:
          // 未知后缀，尝试纯代码作美股处理
          break;
      }
    }

    // 3) 纯字母（1~5 位）→ 视为美股，尝试三家交易所
    if (RegExp(r'^[A-Za-z][A-Za-z0-9.\-]{0,5}$').hasMatch(s)) {
      final up = s.toUpperCase();
      return ['105.$up', '106.$up', '107.$up'];
    }

    // 4) 纯 6 位数字 → 沪/深猜测
    // （600/601/603/605 → 沪；000/001/002/003/300 → 深；
    //  5xx 开头多为沪市 ETF/LOF，159xxx 系列为深市 ETF，默认沪）
    if (RegExp(r'^\d{6}$').hasMatch(s)) {
      if (s.startsWith('6') || s.startsWith('5')) return ['1.$s'];
      return ['0.$s'];
    }

    // 5) 数字：按位数路由
    // 5 位数字 → 港股（直接用）
    if (RegExp(r'^\d{5}$').hasMatch(s)) {
      return ['116.$s'];
    }

    // 4 位数字：全部路由港股（不足 5 位补零）
    // 0700 → 00700（腾讯）、3690 → 03690（美团）、9988 → 09988（阿里）
    if (RegExp(r'^\d{4}$').hasMatch(s)) {
      return ['116.${s.padLeft(5, '0')}'];
    }

    // 1–3 位数字：同样路由港股（如 2 → 00002，1 → 00001）
    if (RegExp(r'^\d{1,3}$').hasMatch(s)) {
      return ['116.${s.padLeft(5, '0')}'];
    }

    return const [];
  }

  String _currencyForSecIdPrefix(String prefix) {
    switch (prefix) {
      case '1':
      case '0':
        return 'CNY';
      case '116':
        return 'HKD';
      case '105':
      case '106':
      case '107':
        return 'USD';
      case '100':
        return 'GBP';
      case '155':
        return 'JPY';
      case '153':
        return 'SGD';
      case '154':
        return 'KRW';
      default:
        return 'USD';
    }
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y$m$day';
  }
}
