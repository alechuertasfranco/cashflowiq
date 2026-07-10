// lib/core/theme/app_color_tokens.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-reactive color tokens. Registered on [ThemeData.extensions] once per
/// brightness (see app_theme.dart) so `context.colorX` resolves to the right
/// palette automatically in light and dark mode.
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  final Color primary;
  final Color secondary;
  final Color complementary;
  final Color accent;

  final Color success;
  final Color successStrong;
  final Color error;
  final Color errorStrong;
  final Color warning;
  final Color warningStrong;

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceElevated;

  final Color textPrimary;
  final Color textSecondary;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;

  final Color border;
  final Color divider;
  final Color muted;

  const AppColorTokens({
    required this.primary,
    required this.secondary,
    required this.complementary,
    required this.accent,
    required this.success,
    required this.successStrong,
    required this.error,
    required this.errorStrong,
    required this.warning,
    required this.warningStrong,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.border,
    required this.divider,
    required this.muted,
  });

  static const light = AppColorTokens(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    complementary: AppColors.complementary,
    accent: AppColors.accent,
    success: AppColors.success,
    successStrong: AppColors.successStrong,
    error: AppColors.error,
    errorStrong: AppColors.errorStrong,
    warning: AppColors.warning,
    warningStrong: AppColors.warningStrong,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    surfaceElevated: AppColors.surfaceElevated,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    onPrimary: AppColors.onPrimary,
    onSecondary: AppColors.onSecondary,
    onSurface: AppColors.onSurface,
    border: AppColors.border,
    divider: AppColors.divider,
    muted: AppColors.muted,
  );

  static const dark = AppColorTokens(
    primary: AppColorsDark.primary,
    secondary: AppColorsDark.secondary,
    complementary: AppColorsDark.complementary,
    accent: AppColorsDark.accent,
    success: AppColorsDark.success,
    successStrong: AppColorsDark.successStrong,
    error: AppColorsDark.error,
    errorStrong: AppColorsDark.errorStrong,
    warning: AppColorsDark.warning,
    warningStrong: AppColorsDark.warningStrong,
    background: AppColorsDark.background,
    surface: AppColorsDark.surface,
    surfaceVariant: AppColorsDark.surfaceVariant,
    surfaceElevated: AppColorsDark.surfaceElevated,
    textPrimary: AppColorsDark.textPrimary,
    textSecondary: AppColorsDark.textSecondary,
    onPrimary: AppColorsDark.onPrimary,
    onSecondary: AppColorsDark.onSecondary,
    onSurface: AppColorsDark.onSurface,
    border: AppColorsDark.border,
    divider: AppColorsDark.divider,
    muted: AppColorsDark.muted,
  );

  @override
  AppColorTokens copyWith({
    Color? primary,
    Color? secondary,
    Color? complementary,
    Color? accent,
    Color? success,
    Color? successStrong,
    Color? error,
    Color? errorStrong,
    Color? warning,
    Color? warningStrong,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? onPrimary,
    Color? onSecondary,
    Color? onSurface,
    Color? border,
    Color? divider,
    Color? muted,
  }) {
    return AppColorTokens(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      complementary: complementary ?? this.complementary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      successStrong: successStrong ?? this.successStrong,
      error: error ?? this.error,
      errorStrong: errorStrong ?? this.errorStrong,
      warning: warning ?? this.warning,
      warningStrong: warningStrong ?? this.warningStrong,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onSurface: onSurface ?? this.onSurface,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      muted: muted ?? this.muted,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      complementary: Color.lerp(complementary, other.complementary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      successStrong: Color.lerp(successStrong, other.successStrong, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorStrong: Color.lerp(errorStrong, other.errorStrong, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningStrong: Color.lerp(warningStrong, other.warningStrong, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}
