import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Semantic sign for value display: positive, negative, or neutral.
enum ValueSign { positive, negative, neutral }

/// Monospace number text with tabular-nums, supporting dual-currency display
/// and explicit positive/negative semantics (color + icon + text).
///
/// Usage:
/// ```dart
/// CofferNumberText(value: '+12,345.67', sign: ValueSign.positive)
/// CofferNumberText.dual(primary: 'CNY 12,345.67', secondary: 'USD 1,780.00')
/// ```
class CofferNumberText extends StatelessWidget {
  const CofferNumberText({
    super.key,
    required this.value,
    this.sign = ValueSign.neutral,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.showIcon = true,
    this.textAlign = TextAlign.end,
  });

  final String value;
  final ValueSign sign;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showIcon;
  final TextAlign textAlign;

  /// Dual-currency display: primary line (larger) + secondary line (smaller, muted).
  static Widget dual({
    Key? key,
    required String primary,
    String? secondary,
    ValueSign sign = ValueSign.neutral,
    double primarySize = 14,
    double secondarySize = 11,
  }) {
    return _DualNumberText(
      key: key,
      primary: primary,
      secondary: secondary,
      sign: sign,
      primarySize: primarySize,
      secondarySize: secondarySize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _signColor(sign);
    final icon = showIcon ? _signIcon(sign) : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (icon != null) ...[
          Icon(icon, size: fontSize * 0.9, color: color),
          const SizedBox(width: 2),
        ],
        Flexible(
          child: Text(
            value,
            textAlign: textAlign,
            style: TextStyle(
              fontFamily: CofferTypo.monoFont,
              fontFeatures: CofferTypo.tabularFigures,
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DualNumberText extends StatelessWidget {
  const _DualNumberText({
    super.key,
    required this.primary,
    required this.secondary,
    required this.sign,
    required this.primarySize,
    required this.secondarySize,
  });

  final String primary;
  final String? secondary;
  final ValueSign sign;
  final double primarySize;
  final double secondarySize;

  @override
  Widget build(BuildContext context) {
    final color = _signColor(sign);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primary,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontFamily: CofferTypo.monoFont,
            fontFeatures: CofferTypo.tabularFigures,
            fontSize: primarySize,
            fontWeight: FontWeight.w600,
            color: color,
            height: 1.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (secondary != null)
          Text(
            secondary!,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: CofferTypo.monoFont,
              fontFeatures: CofferTypo.tabularFigures,
              fontSize: secondarySize,
              fontWeight: FontWeight.w400,
              color: CofferColors.textMuted,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

Color _signColor(ValueSign sign) => switch (sign) {
      ValueSign.positive => CofferColors.positive,
      ValueSign.negative => CofferColors.negative,
      ValueSign.neutral => CofferColors.textPrimary,
    };

IconData? _signIcon(ValueSign sign) => switch (sign) {
      ValueSign.positive => Icons.arrow_drop_up,
      ValueSign.negative => Icons.arrow_drop_down,
      ValueSign.neutral => null,
    };
