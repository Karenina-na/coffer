import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ui/design_tokens.dart';

/// Builds the GWP dark institutional theme from DESIGN.md tokens.
ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme(
    brightness: Brightness.dark,
    // Primary
    primary: GwpColors.actionPrimary,
    onPrimary: Colors.white,
    primaryContainer: GwpColors.actionSecondary,
    onPrimaryContainer: GwpColors.textPrimary,
    // Secondary
    secondary: GwpColors.info,
    onSecondary: GwpColors.canvas,
    secondaryContainer: GwpColors.infoBg,
    onSecondaryContainer: GwpColors.info,
    // Tertiary
    tertiary: GwpColors.warning,
    onTertiary: GwpColors.canvas,
    tertiaryContainer: GwpColors.warningBg,
    onTertiaryContainer: GwpColors.warning,
    // Error
    error: GwpColors.negative,
    onError: Colors.white,
    errorContainer: GwpColors.negativeBg,
    onErrorContainer: GwpColors.negative,
    // Surfaces
    surface: GwpColors.surface1,
    onSurface: GwpColors.textPrimary,
    onSurfaceVariant: GwpColors.textSecondary,
    surfaceContainerLowest: GwpColors.canvas,
    surfaceContainerLow: GwpColors.surface1,
    surfaceContainer: GwpColors.surface2,
    surfaceContainerHigh: GwpColors.surface3,
    surfaceContainerHighest: GwpColors.borderStrong,
    // Outline
    outline: GwpColors.border,
    outlineVariant: GwpColors.border,
    // Misc
    inverseSurface: GwpColors.textPrimary,
    onInverseSurface: GwpColors.canvas,
    shadow: Colors.black,
    scrim: Colors.black54,
  );

  final textTheme = _buildTextTheme(colorScheme);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: GwpColors.canvas,
    textTheme: textTheme,

    // ── AppBar ──────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: GwpColors.surface1,
      foregroundColor: GwpColors.textPrimary,
      toolbarHeight: 44,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    // ── Bottom Navigation ───────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: GwpColors.surface1,
      surfaceTintColor: Colors.transparent,
      indicatorColor: GwpColors.actionPrimary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? GwpColors.actionPrimary : GwpColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: selected ? GwpColors.actionPrimary : GwpColors.textMuted,
        );
      }),
      height: 64,
    ),

    // ── TabBar ──────────────────────────────────────────────
    tabBarTheme: TabBarThemeData(
      labelColor: GwpColors.textPrimary,
      unselectedLabelColor: GwpColors.textMuted,
      indicatorColor: GwpColors.actionPrimary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      dividerColor: GwpColors.border,
      dividerHeight: 1,
    ),

    // ── Card ────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: GwpColors.surface1,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: GwpColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Divider ─────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: GwpColors.border,
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
        color: GwpColors.textPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: GwpColors.textSecondary,
        height: 1.4,
      ),
    ),

    // ── Floating Action Button ──────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: GwpColors.actionPrimary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // ── Filled Button ───────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) {
            return GwpColors.surface3;
          }
          return GwpColors.actionPrimary;
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
        foregroundColor: WidgetStateProperty.all(GwpColors.textPrimary),
        side: WidgetStateProperty.all(
          const BorderSide(color: GwpColors.border),
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
        foregroundColor: WidgetStateProperty.all(GwpColors.actionPrimary),
      ),
    ),

    // ── Input ───────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GwpColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GwpColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GwpColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GwpColors.actionPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GwpColors.negative),
      ),
      labelStyle: const TextStyle(
        color: GwpColors.textSecondary,
        fontSize: 14,
      ),
      hintStyle: const TextStyle(
        color: GwpColors.textMuted,
        fontSize: 14,
      ),
      helperStyle: const TextStyle(
        color: GwpColors.textMuted,
        fontSize: 12,
      ),
    ),

    // ── Chip ────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: GwpColors.surface2,
      side: const BorderSide(color: GwpColors.border, width: 0.5),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: GwpColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),

    // ── SegmentedButton ─────────────────────────────────────
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return GwpColors.actionPrimary.withValues(alpha: 0.18);
          }
          return GwpColors.surface2;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return GwpColors.actionPrimary;
          return GwpColors.textSecondary;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: GwpColors.border),
        ),
      ),
    ),

    // ── Switch ──────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return GwpColors.actionPrimary;
        return GwpColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) {
          return GwpColors.actionPrimary.withValues(alpha: 0.3);
        }
        return GwpColors.surface3;
      }),
    ),

    // ── Dialog ──────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: GwpColors.surface2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // ── BottomSheet ─────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: GwpColors.surface1,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: GwpColors.borderStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // ── SnackBar ────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: GwpColors.surface3,
      contentTextStyle: const TextStyle(color: GwpColors.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),

    // ── Icon ────────────────────────────────────────────────
    iconTheme: const IconThemeData(
      color: GwpColors.textSecondary,
      size: 22,
    ),

    // ── Tooltip ─────────────────────────────────────────────
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: GwpColors.surface3,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: GwpColors.textPrimary, fontSize: 12),
    ),

    // ── Page transitions: restrained ────────────────────────
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),

    hintColor: GwpColors.textMuted,
    splashColor: GwpColors.actionPrimary.withValues(alpha: 0.08),
    highlightColor: GwpColors.actionPrimary.withValues(alpha: 0.06),
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
      fontFeatures: GwpTypo.tabularFigures,
    ),
    displayMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
      height: 30 / 24,
      fontFeatures: GwpTypo.tabularFigures,
    ),
    displaySmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
      height: 28 / 22,
      fontFeatures: GwpTypo.tabularFigures,
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
