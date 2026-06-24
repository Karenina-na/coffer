import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Unified status badge used across accounts, events, channels, etc.
/// Renders a compact pill with semantic background color.
class CofferStatusBadge extends StatelessWidget {
  const CofferStatusBadge({
    super.key,
    required this.label,
    this.variant = StatusVariant.neutral,
  });

  final String label;
  final StatusVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(variant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

enum StatusVariant { positive, negative, warning, info, neutral, muted }

(Color, Color) _colors(StatusVariant v) => switch (v) {
      StatusVariant.positive => (CofferColors.positiveBg, CofferColors.positive),
      StatusVariant.negative => (CofferColors.negativeBg, CofferColors.negative),
      StatusVariant.warning => (CofferColors.warningBg, CofferColors.warning),
      StatusVariant.info => (CofferColors.infoBg, CofferColors.info),
      StatusVariant.neutral => (CofferColors.surface3, CofferColors.textPrimary),
      StatusVariant.muted => (CofferColors.surface2, CofferColors.textMuted),
    };
