import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../money/money.dart';
import 'design_tokens.dart';

enum ValuedAmountDisplayMode {
  inline,
  stacked,
  nativePrimary,
}

class ValuedAmountText extends StatelessWidget {
  const ValuedAmountText({
    super.key,
    required this.valuedAmount,
    required this.valuationCurrency,
    required this.nativeAmount,
    required this.nativeCurrency,
    this.valuedStyle,
    this.nativeStyle,
    this.mode = ValuedAmountDisplayMode.inline,
    this.gap = 4,
  });

  final Decimal? valuedAmount;
  final String valuationCurrency;
  final Decimal? nativeAmount;
  final String nativeCurrency;
  final TextStyle? valuedStyle;
  final TextStyle? nativeStyle;
  final ValuedAmountDisplayMode mode;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final primaryStyle =
        valuedStyle ??
        const TextStyle(
          fontFamily: GwpTypo.monoFont,
          fontFeatures: GwpTypo.tabularFigures,
          color: GwpColors.textPrimary,
        );
    final secondaryStyle =
        nativeStyle ??
        const TextStyle(
          fontFamily: GwpTypo.monoFont,
          fontFeatures: GwpTypo.tabularFigures,
          color: GwpColors.textMuted,
        );

    final valuedText = valuedAmount == null
        ? '—'
        : Money.format(valuedAmount!, currency: valuationCurrency);
    final nativeText = nativeAmount == null
        ? '—'
        : Money.format(nativeAmount!, currency: nativeCurrency);

    if (mode == ValuedAmountDisplayMode.stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(valuedText, style: primaryStyle, overflow: TextOverflow.ellipsis),
          SizedBox(height: gap),
          Text('/ $nativeText', style: secondaryStyle, overflow: TextOverflow.ellipsis),
        ],
      );
    }

    if (mode == ValuedAmountDisplayMode.nativePrimary) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(nativeText, style: primaryStyle, overflow: TextOverflow.ellipsis),
          SizedBox(height: gap),
          Text(
            valuedAmount == null ? '计价值缺失' : '≈ $valuedText',
            style: secondaryStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(text: valuedText, style: primaryStyle),
          TextSpan(text: ' / $nativeText', style: secondaryStyle),
        ],
      ),
    );
  }
}
