import 'package:flutter/material.dart';

/// GWP design tokens derived from doc/tmp/DESIGN.md.
/// Dark institutional fintech theme with high data density.
abstract final class GwpColors {
  // ── Core Surfaces ──────────────────────────────────────────
  static const canvas = Color(0xFF0A0A0A);
  static const surface1 = Color(0xFF141414);
  static const surface2 = Color(0xFF1C1C1C);
  static const surface3 = Color(0xFF262626);

  // ── Borders ────────────────────────────────────────────────
  static const border = Color(0xFF2F2F2F);
  static const borderStrong = Color(0xFF404040);

  // ── Text ───────────────────────────────────────────────────
  static const textPrimary = Color(0xFFF2F2F2);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textMuted = Color(0xFF7A7A7A);

  // ── Actions ────────────────────────────────────────────────
  // Monochrome (black-based) accent on dark canvas. 中灰，保证白字可读。
  static const actionPrimary = Color(0xFF5B6470);
  static const actionPrimaryHover = Color(0xFF7A8390);
  static const actionSecondary = Color(0xFF2A2A2A);

  // ── Semantic States ────────────────────────────────────────
  static const positive = Color(0xFF22C55E);
  static const negative = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF9CA3AF);

  // ── Derived ────────────────────────────────────────────────
  static const positiveBg = Color(0xFF142018);
  static const negativeBg = Color(0xFF201414);
  static const warningBg = Color(0xFF201C10);
  static const infoBg = Color(0xFF1A1A1A);
}

/// Spacing scale: 4, 8, 12, 16, 20, 24, 32, 40
abstract final class GwpSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

/// Typography constants. Number columns use monospace with tabularFigures.
abstract final class GwpTypo {
  static const uiFont = 'PingFang SC';
  static const monoFont = 'Menlo';

  static const tabularFigures = [FontFeature.tabularFigures()];
}
