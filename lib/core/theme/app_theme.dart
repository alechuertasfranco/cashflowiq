import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color_tokens.dart';
import 'app_colors.dart';
import 'app_motion.dart';
import 'app_radius.dart';

/// Fade + subtle upward slide used for every `Navigator.push`d route across
/// the app (registered once here — no per-screen changes needed).
class _AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.emphasized);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

final _pageTransitionsTheme = const PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _AppPageTransitionsBuilder(),
    TargetPlatform.iOS: _AppPageTransitionsBuilder(),
    TargetPlatform.macOS: _AppPageTransitionsBuilder(),
    TargetPlatform.windows: _AppPageTransitionsBuilder(),
    TargetPlatform.linux: _AppPageTransitionsBuilder(),
    TargetPlatform.fuchsia: _AppPageTransitionsBuilder(),
  },
);

class AppTheme {
  static ThemeData get light => _build(AppColorTokens.light, Brightness.light);
  static ThemeData get dark => _build(AppColorTokens.dark, Brightness.dark);

  static ThemeData _build(AppColorTokens tokens, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: tokens.background,
    );

    return base.copyWith(
      extensions: [tokens],
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      pageTransitionsTheme: _pageTransitionsTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: tokens.primary,
        secondary: tokens.complementary,
        surface: tokens.surface,
        error: tokens.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: tokens.textPrimary,
        iconTheme: IconThemeData(color: tokens.primary),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      ),
      dividerTheme: DividerThemeData(color: tokens.divider, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          disabledBackgroundColor: tokens.muted.withAlpha(90),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primary,
          side: BorderSide(color: tokens.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: tokens.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: tokens.error),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.onSurface,
        contentTextStyle: TextStyle(color: tokens.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: BoxDecoration(color: tokens.primary, borderRadius: AppRadius.pillRadius),
        labelColor: tokens.onPrimary,
        unselectedLabelColor: tokens.textSecondary,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        splashBorderRadius: AppRadius.pillRadius,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: tokens.border, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? tokens.primary : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(tokens.onPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? tokens.primary : tokens.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? tokens.primary.withAlpha(70) : tokens.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? tokens.primary : tokens.muted,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceVariant,
        selectedColor: tokens.primary,
        disabledColor: tokens.surfaceVariant,
        labelStyle: TextStyle(color: tokens.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        secondaryLabelStyle: TextStyle(color: tokens.onPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        side: BorderSide(color: tokens.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.primary,
        circularTrackColor: tokens.border,
        linearTrackColor: tokens.border,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        headerBackgroundColor: tokens.primary,
        headerForegroundColor: tokens.onPrimary,
        headerHeadlineStyle: GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w700),
        headerHelpStyle: GoogleFonts.urbanist(fontSize: 13, fontWeight: FontWeight.w600),
        weekdayStyle: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.textSecondary,
          height: 1,
        ),
        // Explicit `height: 1` keeps the digit vertically centered inside the
        // fixed-size selection circle — Inter's default line-height (from the
        // app-wide GoogleFonts textTheme) otherwise pushes it off-center.
        dayStyle: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600, height: 1),
        yearStyle: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w500, height: 1),
        // `todayForegroundColor` used to be a flat constant, so a selected
        // "today" rendered primary-on-primary text — invisible against its
        // own fill. Resolve it by selection state like every other day.
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? tokens.onPrimary : tokens.primary,
        ),
        todayBorder: BorderSide(color: tokens.primary, width: 1.2),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? tokens.onPrimary : tokens.textPrimary,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? tokens.primary : Colors.transparent,
        ),
        dayOverlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : tokens.primary.withAlpha(20),
        ),
        todayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? tokens.primary : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: tokens.textSecondary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: tokens.primary),
      ),
    );
  }
}
