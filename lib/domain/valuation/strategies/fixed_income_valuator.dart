import 'package:decimal/decimal.dart';

import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../entities/asset.dart';
import '../../entities/asset_enums.dart';
import '../asset_valuator.dart';

/// 固收类资产估值引擎：定期存款 (CD) / 债券 (BOND)。
///
/// 用 [Asset.extInfo] 中的以下字段进行计息推算（均可省略，缺失字段走安全回落）：
/// - `principal` (String/num) → 本金；缺省用 `quantity`
/// - `annualRate` (String/num) → 年化利率小数，如 0.035 表示 3.5%
/// - `startDate`   (ISO8601) → 计息起始日；缺省用 `createdAt`
/// - `maturityDate`(ISO8601) → 到期日；到期后利息不再累计
/// - `compounding` (String) → 'simple' | 'daily' | 'monthly' | 'annual'
///     缺省：CD → simple，BOND → annual
/// - `dayCount`    (num)    → 计息基数，缺省 365
///
/// 估值口径：当前持有人可赎回价值 = 本金 + 截至估值时间的已累计利息。
/// 上层会再乘以 `quantity` 得到市值，因此这里的 price 是「单位本金的净值」：
///   price = 1 + accrued_interest_ratio
/// 为保持 `marketValue = quantity * price` 在现有 `ValuateAssetUseCase` 中仍然成立，
/// 这里约定：`quantity` 存的是「本金（按 currency 计价）」。
///
/// 实现要点：
/// - 所有金额相关中间计算全部走 `Decimal`，禁止经过 `double`（AGENTS §4）
/// - 非整数次幂通过「整数部分快速幂 + 分数部分二项级数」组合求解，
///   截断 scale = [_decimalScale] 位，对 r/n 很小（<5e-4）的固收场景
///   误差 < 1e-18，远低于 UI 12 位展示精度
class FixedIncomeValuator implements AssetValuator {
  FixedIncomeValuator({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  static const String source = 'fixed-income-engine';
  static const int _decimalScale = 20;
  static const int _outputScale = 12;
  static final Decimal _maxCompoundExponent = Decimal.fromInt(36500);

  static const _supported = <AssetType>{AssetType.cd, AssetType.bond};

  @override
  bool supports(Asset asset) => _supported.contains(asset.assetType);

  @override
  Future<Result<AssetQuote, AppError>> valueNow(
    Asset asset, {
    bool forceRefresh = false,
  }) async {
    final now = _clock();
    final params = _readParams(asset);
    final effectiveEnd =
        params.maturity != null && now.isAfter(params.maturity!)
        ? params.maturity!
        : now;
    final yearsHeld = _yearsBetween(
      params.start,
      effectiveEnd,
      params.dayCount,
    );
    if (yearsHeld < Decimal.zero) {
      return Ok(_quote(asset, Decimal.one, now));
    }
    final ratio = _accruedRatio(
      rate: params.annualRate,
      years: yearsHeld,
      compounding: params.compounding,
    );
    if (ratio.isErr) return Err(ratio.errorOrNull!);
    final price = (Decimal.one + ratio.valueOrNull!).round(scale: _outputScale);
    return Ok(_quote(asset, price, now));
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> valueHistory(
    Asset asset, {
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    final params = _readParams(asset);
    final start = from.isAfter(params.start) ? from : params.start;
    final end = params.maturity != null && to.isAfter(params.maturity!)
        ? params.maturity!
        : to;
    if (!end.isAfter(start)) {
      return Ok(
        AssetPriceSeries(
          symbol: asset.assetCode ?? asset.id,
          currency: asset.currency,
          points: const [],
          source: source,
        ),
      );
    }
    final points = <AssetPricePoint>[];
    var cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(last)) {
      final years = _yearsBetween(params.start, cursor, params.dayCount);
      final ratio = years <= Decimal.zero
          ? Ok<Decimal, AppError>(Decimal.zero)
          : _accruedRatio(
              rate: params.annualRate,
              years: years,
              compounding: params.compounding,
            );
      if (ratio.isErr) return Err(ratio.errorOrNull!);
      final price = (Decimal.one + ratio.valueOrNull!).round(
        scale: _outputScale,
      );
      points.add(
        AssetPricePoint(t: cursor, price: price, currency: asset.currency),
      );
      cursor = cursor.add(const Duration(days: 1));
    }
    return Ok(
      AssetPriceSeries(
        symbol: asset.assetCode ?? asset.id,
        currency: asset.currency,
        points: points,
        source: source,
      ),
    );
  }

  // —— 工具 ——

  AssetQuote _quote(Asset asset, Decimal price, DateTime now) => AssetQuote(
    symbol: asset.assetCode ?? asset.id,
    price: price,
    currency: asset.currency,
    asOfTime: now,
    source: source,
  );

  _FIParams _readParams(Asset a) {
    final ext = a.extInfo ?? const <String, dynamic>{};
    final dc = _toDecimal(ext['dayCount']) ?? Decimal.fromInt(365);
    final compounding = ext['compounding'];
    return _FIParams(
      annualRate: _toDecimal(ext['annualRate']) ?? Decimal.zero,
      start: _toDate(ext['startDate']) ?? a.createdAt,
      maturity: _toDate(ext['maturityDate']),
      compounding: _Compounding.parse(
        compounding is String ? compounding : null,
        fallback: a.assetType == AssetType.cd
            ? _Compounding.simple
            : _Compounding.annual,
      ),
      dayCount: dc <= Decimal.zero ? Decimal.fromInt(365) : dc,
    );
  }

  /// 以 Decimal 返回两个时刻之间的「年数」，按秒级精度换算。
  Decimal _yearsBetween(DateTime from, DateTime to, Decimal dayCount) {
    final seconds = to.difference(from).inSeconds;
    final days = (Decimal.fromInt(seconds) / Decimal.fromInt(86400)).toDecimal(
      scaleOnInfinitePrecision: _decimalScale,
    );
    return (days / dayCount).toDecimal(scaleOnInfinitePrecision: _decimalScale);
  }

  /// 累计利息比率：
  /// - simple       : r * t
  /// - annual/月/日 : (1 + r/n)^(n*t) - 1
  Result<Decimal, AppError> _accruedRatio({
    required Decimal rate,
    required Decimal years,
    required _Compounding compounding,
  }) {
    if (years <= Decimal.zero || rate == Decimal.zero) {
      return Ok(Decimal.zero);
    }
    switch (compounding) {
      case _Compounding.simple:
        return Ok((rate * years).round(scale: _decimalScale));
      case _Compounding.annual:
      case _Compounding.monthly:
      case _Compounding.daily:
        final n = compounding.periodsPerYear;
        final perPeriodRate = (rate / n).toDecimal(
          scaleOnInfinitePrecision: _decimalScale,
        );
        final exponent = (n * years).round(scale: _decimalScale);
        if (exponent.abs() > _maxCompoundExponent) {
          return const Err(ValidationError('compound exponent too large'));
        }
        final growth = _onePlusXPow(perPeriodRate, exponent);
        if (growth.isErr) return growth;
        return Ok(
          (growth.valueOrNull! - Decimal.one).round(scale: _decimalScale),
        );
    }
  }

  /// 计算 (1 + x)^e，e 可能为非整数。
  ///
  /// 将 e 拆成整数部分 i 与分数部分 f（0 ≤ f < 1）：
  ///   (1+x)^e = (1+x)^i * (1+x)^f
  /// 整数部分用快速幂得到精确值；分数部分用广义二项级数展开：
  ///   (1+x)^f = Σ_{k=0..K} C(f,k) * x^k
  /// 其中 C(f,0)=1，C(f,k) = C(f,k-1) * (f-k+1)/k。
  ///
  /// 本估值场景 x = r/n 通常极小（年利率 < 20%，日复利 n=365 ⇒ x < 5.5e-4），
  /// 取 K=10 项即可把截断误差压到 x^11 ≈ 1e-38 量级，完全覆盖 12 位输出精度。
  Result<Decimal, AppError> _onePlusXPow(Decimal x, Decimal exponent) {
    if (exponent == Decimal.zero) return Ok(Decimal.one);
    final base = Decimal.one + x;

    // 整数部分
    final intPartDec = exponent.truncate();
    final fracPart = (exponent - intPartDec).round(scale: _decimalScale);
    final bigInt = intPartDec.toBigInt();
    if (!bigInt.isValidInt) {
      // 防止极大指数（> 2^63-1）触发 RangeError；此规模的利息计算已无实际意义。
      return const Err(ValidationError('exponent overflow'));
    }
    final intPart = bigInt.toInt();

    Decimal intResult = _intPow(base, intPart);
    if (fracPart == Decimal.zero) {
      return Ok(intResult.round(scale: _decimalScale));
    }

    // 分数部分：广义二项级数
    Decimal coeff = Decimal.one;
    Decimal xPow = Decimal.one;
    Decimal sum = Decimal.one;
    for (int k = 1; k <= 10; k++) {
      final numerator = fracPart - Decimal.fromInt(k - 1);
      coeff = (coeff * numerator / Decimal.fromInt(k)).toDecimal(
        scaleOnInfinitePrecision: _decimalScale,
      );
      xPow = (xPow * x).round(scale: _decimalScale);
      final term = (coeff * xPow).round(scale: _decimalScale);
      sum = sum + term;
      if (term.abs() < _epsilon) break;
    }

    return Ok((intResult * sum).round(scale: _decimalScale));
  }

  /// 整数快速幂（指数可正可负可为 0）。
  Decimal _intPow(Decimal base, int exponent) {
    if (exponent == 0) return Decimal.one;
    final positive = exponent > 0;
    var e = exponent.abs();
    var b = base;
    Decimal result = Decimal.one;
    while (e > 0) {
      if (e & 1 == 1) {
        result = (result * b).round(scale: _decimalScale);
      }
      e >>= 1;
      if (e > 0) {
        b = (b * b).round(scale: _decimalScale);
      }
    }
    if (!positive) {
      result = (Decimal.one / result).toDecimal(
        scaleOnInfinitePrecision: _decimalScale,
      );
    }
    return result;
  }

  static final Decimal _epsilon = Decimal.parse('1e-30');

  Decimal? _toDecimal(dynamic v) {
    if (v == null) return null;
    if (v is Decimal) return v;
    if (v is int) return Decimal.fromInt(v);
    if (v is double) {
      if (v.isNaN || v.isInfinite) return null;
      return Decimal.parse(v.toString());
    }
    if (v is String) return Decimal.tryParse(v);
    return null;
  }

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

class _FIParams {
  const _FIParams({
    required this.annualRate,
    required this.start,
    required this.maturity,
    required this.compounding,
    required this.dayCount,
  });

  final Decimal annualRate;
  final DateTime start;
  final DateTime? maturity;
  final _Compounding compounding;
  final Decimal dayCount;
}

enum _Compounding {
  simple,
  daily,
  monthly,
  annual;

  Decimal get periodsPerYear => switch (this) {
    _Compounding.simple => throw UnsupportedError(
      'simple compounding has no periodsPerYear',
    ),
    _Compounding.daily => Decimal.fromInt(365),
    _Compounding.monthly => Decimal.fromInt(12),
    _Compounding.annual => Decimal.one,
  };

  static _Compounding parse(String? s, {required _Compounding fallback}) {
    switch (s?.toLowerCase()) {
      case 'simple':
        return _Compounding.simple;
      case 'daily':
        return _Compounding.daily;
      case 'monthly':
        return _Compounding.monthly;
      case 'annual':
      case 'yearly':
        return _Compounding.annual;
      default:
        return fallback;
    }
  }
}
