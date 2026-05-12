library;

import 'package:decimal/decimal.dart';

import '../money/money.dart';

String heroFormat(Decimal val) =>
    Money.formatDecimal(val, fractionDigits: Money.defaultDisplayFractionDigits);

String displayNumber(
  Decimal val, {
  int fractionDigits = Money.defaultDisplayFractionDigits,
  bool alwaysShowSign = false,
}) => Money.formatDecimal(
  val,
  fractionDigits: fractionDigits,
  alwaysShowSign: alwaysShowSign,
);

String displayDouble(
  double val, {
  int fractionDigits = Money.defaultDisplayFractionDigits,
  bool alwaysShowSign = false,
}) => Money.formatDouble(
  val,
  fractionDigits: fractionDigits,
  alwaysShowSign: alwaysShowSign,
);

String displayPercent(
  Decimal val, {
  int fractionDigits = 2,
  bool alwaysShowSign = false,
}) => Money.formatPercent(
  val,
  fractionDigits: fractionDigits,
  alwaysShowSign: alwaysShowSign,
);

String displayPercentDouble(
  double val, {
  int fractionDigits = 2,
  bool alwaysShowSign = false,
}) => Money.formatPercentFromDouble(
  val,
  fractionDigits: fractionDigits,
  alwaysShowSign: alwaysShowSign,
);

String compactValue(double val) {
  if (val.abs() >= 1e6) return '${displayDouble(val / 1e6)}M';
  if (val.abs() >= 1e3) return '${displayDouble(val / 1e3)}K';
  return displayDouble(val);
}

String compactValueCJK(double val) {
  if (val.abs() >= 1e8) return '${displayDouble(val / 1e8)}亿';
  if (val.abs() >= 1e4) return '${displayDouble(val / 1e4)}万';
  if (val.abs() >= 1e6) return '${displayDouble(val / 1e6)}M';
  if (val.abs() >= 1e3) return '${displayDouble(val / 1e3)}K';
  return displayDouble(val);
}
