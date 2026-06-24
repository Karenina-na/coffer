import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ui/design_tokens.dart';

/// Builds the Coffer dark institutional theme from DESIGN.md tokens.
ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme(
    brightness: Brightness.dark,
    // Primary
    primary: CofferColors.actionPrimary,
    onPrimary: Colors.white,
    primaryContainer: CofferColors.actionSecondary,
    onPrimaryContainer: CofferColors.textPrimary,
    // Secondary
    secondary: CofferColors.info,
    onSecondary: CofferColors.canvas,
    secondaryContainer: CofferColors.infoBg,
    onSecondaryContainer: CofferColors.info,
    // Tertiary
    tertiary: CofferColors.warning,
    onTertiary: CofferColors.canvas,
    tertiaryContainer: CofferColors.warningBg,
    onTertiaryContainer: CofferColors.warning,
    // Error
    error: CofferColors.negative,
    onError: Colors.white,
    errorContainer: CofferColors.negativeBg,
    onErrorContainer: CofferColors.negative,
    // Surfaces
    surface: CofferColors.surface1,
    onSurface: CofferColors.textPrimary,
    onSurfaceVariant: CofferColors.textSecondary,
    surfaceContainerLowest: CofferColors.canvas,
    surfaceContainerLow: CofferColors.surface1,
    surfaceContainer: CofferColors.surface2,
    surfaceContainerHigh: CofferColors.surface3,
    surfaceContainerHighest: CofferColors.borderStrong,
    // Outline
    outline: CofferColors.border,
    outlineVariant: CofferColors.border,
    // Misc
    inverseSurface: CofferColors.textPrimary,
    onInverseSurface: CofferColors.canvas,
    shadow: Colors.black,
    scrim: Colors.black54,
  );

  final textTheme = _buildTextTheme(colorScheme);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: CofferColors.canvas,
    textTheme: textTheme,

    // ── AppBar ──────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: CofferColors.surface1,
      foregroundColor: CofferColors.textPrimary,
      toolbarHeight: 44,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    // ── Bottom Navigation ───────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CofferColors.surface1,
      surfaceTintColor: Colors.transparent,
      indicatorColor: CofferColors.actionPrimary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? CofferColors.actionPrimary : CofferColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: selected ? CofferColors.actionPrimary : CofferColors.textMuted,
        );
      }),
      height: 64,
    ),

    // ── TabBar ──────────────────────────────────────────────
    tabBarTheme: TabBarThemeData(
      labelColor: CofferColors.textPrimary,
      unselectedLabelColor: CofferColors.textMuted,
      indicatorColor: CofferColors.actionPrimary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      dividerColor: CofferColors.border,
      dividerHeight: 1,
    ),

    // ── Card ────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: CofferColors.surface1,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CofferColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Divider ─────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: CofferColors.border,
      thickness: 0.5,
      space: 0,
    ),

    // ── ListTile ────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      visualDensity: VisualDensity.compact,
      minVerticalPadding: 10,
      titleTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: CofferColors.textPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: CofferColors.textSecondary,
        height: 1.4,
      ),
    ),

    // ── Floating Action Button ──────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: CofferColors.actionPrimary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // ── Filled Button ───────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) {
            return CofferColors.surface3;
          }
          return CofferColors.actionPrimary;
        }),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        minimumSize: WidgetStateProperty.all(const Size(0, 44)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ),

    // ── Outlined Button ─────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(CofferColors.textPrimary),
        side: WidgetStateProperty.all(
          const BorderSide(color: CofferColors.border),
        ),
        minimumSize: WidgetStateProperty.all(const Size(0, 44)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ),

    // ── Text Button ─────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(CofferColors.actionPrimary),
      ),
    ),

    // ── Input ───────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CofferColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CofferColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CofferColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CofferColors.actionPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CofferColors.negative),
      ),
      labelStyle: const TextStyle(
        color: CofferColors.textSecondary,
        fontSize: 14,
      ),
      hintStyle: const TextStyle(
        color: CofferColors.textMuted,
        fontSize: 14,
      ),
      helperStyle: const TextStyle(
        color: CofferColors.textMuted,
        fontSize: 12,
      ),
    ),

    // ── Chip ────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: CofferColors.surface2,
      side: const BorderSide(color: CofferColors.border, width: 0.5),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: CofferColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),

    // ── SegmentedButton ─────────────────────────────────────
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return CofferColors.actionPrimary.withValues(alpha: 0.18);
          }
          return CofferColors.surface2;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return CofferColors.actionPrimary;
          return CofferColors.textSecondary;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: CofferColors.border),
        ),
      ),
    ),

    // ── Switch ──────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return CofferColors.actionPrimary;
        return CofferColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) {
          return CofferColors.actionPrimary.withValues(alpha: 0.3);
        }
        return CofferColors.surface3;
      }),
    ),

    // ── Dialog ──────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: CofferColors.surface2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // ── BottomSheet ─────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: CofferColors.surface1,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: CofferColors.borderStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // ── SnackBar ────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CofferColors.surface3,
      contentTextStyle: const TextStyle(color: CofferColors.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),

    // ── Icon ────────────────────────────────────────────────
    iconTheme: const IconThemeData(
      color: CofferColors.textSecondary,
      size: 22,
    ),

    // ── Tooltip ─────────────────────────────────────────────
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: CofferColors.surface3,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: CofferColors.textPrimary, fontSize: 12),
    ),

    // ── Page transitions: restrained ────────────────────────
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),

    hintColor: CofferColors.textMuted,
    splashColor: CofferColors.actionPrimary.withValues(alpha: 0.08),
    highlightColor: CofferColors.actionPrimary.withValues(alpha: 0.06),
  );
}

TextTheme _buildTextTheme(ColorScheme cs) {
  return TextTheme(
    // display
    displayLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
      height: 34 / 28,
      fontFeatures: CofferTypo.tabularFigures,
    ),
    displayMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
      height: 30 / 24,
      fontFeatures: CofferTypo.tabularFigures,
    ),
    displaySmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
      height: 28 / 22,
      fontFeatures: CofferTypo.tabularFigures,
    ),
    // headline
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
      height: 30 / 22,
    ),
    headlineMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
      height: 26 / 18,
    ),
    headlineSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
      height: 24 / 16,
    ),
    // title
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
      height: 26 / 18,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
      height: 20 / 14,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
      height: 18 / 12,
    ),
    // body
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: cs.onSurface,
      height: 24 / 16,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: cs.onSurface,
      height: 20 / 14,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: cs.onSurfaceVariant,
      height: 18 / 12,
    ),
    // label
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: cs.onSurface,
      height: 20 / 14,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: cs.onSurfaceVariant,
      height: 16 / 12,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: cs.onSurfaceVariant,
      height: 14 / 11,
    ),
  );
}

/// Keep light theme for potential future use (system switch).
ThemeData buildLightTheme() => buildDarkTheme();
