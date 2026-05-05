/// 展示层通用格式化工具。
///
/// - [heroFormat]：带千分位分隔符的金额字符串，精确到分（`1,234.56`）。
///   用于资产详情页、持仓分析页、账户详情页等英雄区大数字展示。
/// - [compactValueCJK]：中文单位压缩（亿/万/M/K），用于持仓分析紧凑显示。
/// - [compactValue]：英文单位压缩（M/K），用于资产/账户页。
library;

import 'package:decimal/decimal.dart';

/// 带千分位、保留两位小数的金额格式化，如 `1,234.56`、`-0.05`。
///
/// 接受 [Decimal] 以保持金额精度，内部使用 Decimal 运算避免 double 精度丢失。
String heroFormat(Decimal val) {
  final rounded = val.round(scale: 2);
  final isNeg = rounded < Decimal.zero;
  final abs = isNeg ? -rounded : rounded;
  final parts = abs.toString().split('.');
  final intPart = parts[0];
  final frac = parts.length > 1 ? parts[1].padRight(2, '0') : '00';

  // 千分位分隔
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  buf.write('.$frac');
  return isNeg ? '-$buf' : buf.toString();
}

/// 英文单位压缩：≥1M → `1.2M`；≥1K → `1.2K`；其余直接整数。
/// 用于资产详情页、账户详情页等英文风格布局。
String compactValue(double val) {
  if (val.abs() >= 1e6) return '${(val / 1e6).toStringAsFixed(1)}M';
  if (val.abs() >= 1e3) return '${(val / 1e3).toStringAsFixed(1)}K';
  return val.toStringAsFixed(0);
}

/// 中文单位压缩：≥1亿 → `1.2亿`；≥1万 → `1.2万`；之后与 [compactValue] 相同。
/// 用于持仓分析页等国内用户友好的布局。
String compactValueCJK(double val) {
  if (val.abs() >= 1e8) return '${(val / 1e8).toStringAsFixed(1)}亿';
  if (val.abs() >= 1e4) return '${(val / 1e4).toStringAsFixed(1)}万';
  if (val.abs() >= 1e6) return '${(val / 1e6).toStringAsFixed(1)}M';
  if (val.abs() >= 1e3) return '${(val / 1e3).toStringAsFixed(1)}K';
  return val.toStringAsFixed(0);
}
