import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// 金额解析与渲染的统一入口。
///
/// 约束：
/// - 存储与计算一律使用 [Decimal]，禁止使用 double
/// - DB 列以十进制字符串保存，由 [parseOrNull] / [stringifyOrNull]
///   在边界转换
/// - [format] 不走 double，避免大额/多位小数的精度丢失
class Money {
  const Money._();

  static const int defaultRatioScale = 10;

  /// 将 DB 中的文本列（可空）解析为 [Decimal]。
  static Decimal? parseOrNull(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return Decimal.parse(raw);
    } on FormatException {
      return null;
    }
  }

  /// 将 [Decimal] 序列化为 DB 用字符串。
  static String? stringifyOrNull(Decimal? value) => value?.toString();

  /// 在 Decimal 域内安全计算比率，避免无限小数在 toDecimal() 时抛错。
  static Decimal ratio(
    Decimal numerator,
    Decimal denominator, {
    int scale = defaultRatioScale,
  }) {
    if (denominator == Decimal.zero) return Decimal.zero;
    return (numerator / denominator).toDecimal(
      scaleOnInfinitePrecision: scale,
    );
  }

  /// 在 Decimal 域内安全计算百分比，结果已乘以 100。
  static Decimal percent(
    Decimal numerator,
    Decimal denominator, {
    int scale = defaultRatioScale,
  }) {
    if (denominator == Decimal.zero) return Decimal.zero;
    return ratio(
      numerator * Decimal.fromInt(100),
      denominator,
      scale: scale,
    );
  }

  /// 按币种精度渲染展示文本。
  ///
  /// 通过 [currency] 决定分隔符与小数位数；默认 2 位小数。
  ///
  /// 实现不经 `Decimal.toDouble()`：
  ///  1. 在 Decimal 域内按目标精度取整；
  ///  2. 从 [NumberFormat] 提取千分位 / 小数分隔符 / 货币符号；
  ///  3. 自行做整数部分的千分位分组，避免超过 double 安全整数
  ///     （2^53）范围时的尾数截断。
  static String format(
    Decimal value, {
    required String currency,
    String? locale,
    int? fractionDigits,
  }) {
    final digits = fractionDigits ?? _defaultFractionDigits(currency);
    final rounded = value.round(scale: digits);
    final nf = NumberFormat.currency(
      locale: locale,
      name: currency,
      decimalDigits: digits,
    );
    final groupSep = nf.symbols.GROUP_SEP;
    final decSep = nf.symbols.DECIMAL_SEP;
    final symbol = nf.currencySymbol;

    final isNeg = rounded < Decimal.zero;
    final absStr = (isNeg ? -rounded : rounded).toString();
    final dotIdx = absStr.indexOf('.');
    final intPart = dotIdx >= 0 ? absStr.substring(0, dotIdx) : absStr;
    var fracPart = dotIdx >= 0 ? absStr.substring(dotIdx + 1) : '';
    if (fracPart.length > digits) {
      fracPart = fracPart.substring(0, digits);
    } else if (fracPart.length < digits) {
      fracPart = fracPart.padRight(digits, '0');
    }

    final grouped = _groupThousands(intPart, groupSep);
    final body = digits > 0 ? '$grouped$decSep$fracPart' : grouped;
    // 项目涉及币种（CNY/USD/HKD/EUR/GBP/JPY/SGD/AUD/加密）均为前缀符号格式，
    // 统一 `{symbol}{signedNumber}`。如果后续新增后缀型币种，再按 locale
    // pattern 拆分。
    return isNeg ? '-$symbol$body' : '$symbol$body';
  }

  static String _groupThousands(String digits, String sep) {
    if (digits.length <= 3) return digits;
    final buf = StringBuffer();
    final len = digits.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write(sep);
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  static int _defaultFractionDigits(String currency) {
    // 加密资产、贵金属等需要更高精度；法币默认 2 位。
    const highPrecision = {'BTC', 'ETH', 'SOL', 'XAU', 'XAG'};
    if (highPrecision.contains(currency.toUpperCase())) return 8;
    return 2;
  }
}
