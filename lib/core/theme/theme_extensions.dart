import 'package:flutter/material.dart';
import 'app_color_tokens.dart';
import 'app_motion.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// BuildContext extension for ergonomic access to design tokens.
/// Prefer these over `AppColors.x` / `AppTextStyles.x(context)` in new code —
/// colors here are theme-reactive and adapt to dark mode automatically.
extension AppThemeContext on BuildContext {
  AppColorTokens get _tokens =>
      Theme.of(this).extension<AppColorTokens>() ?? AppColorTokens.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Colors ──────────────────────────────────────────────────────────────
  Color get colorPrimary => _tokens.primary;
  Color get colorSecondary => _tokens.secondary;
  Color get colorComplementary => _tokens.complementary;
  Color get colorAccent => _tokens.accent;
  Color get colorBackground => _tokens.background;
  Color get colorSurface => _tokens.surface;
  Color get colorSurfaceVariant => _tokens.surfaceVariant;
  Color get colorSurfaceElevated => _tokens.surfaceElevated;
  Color get colorBorder => _tokens.border;
  Color get colorDivider => _tokens.divider;
  Color get colorTextPrimary => _tokens.textPrimary;
  Color get colorTextSecondary => _tokens.textSecondary;
  Color get colorOnPrimary => _tokens.onPrimary;
  Color get colorOnSecondary => _tokens.onSecondary;
  Color get colorOnSurface => _tokens.onSurface;
  Color get colorMuted => _tokens.muted;
  Color get colorError => _tokens.error;
  Color get colorErrorStrong => _tokens.errorStrong;
  Color get colorSuccess => _tokens.success;
  Color get colorSuccessStrong => _tokens.successStrong;
  Color get colorWarning => _tokens.warning;
  Color get colorWarningStrong => _tokens.warningStrong;

  // ── Radius ──────────────────────────────────────────────────────────────
  double get radiusSm => AppRadius.sm;
  double get radiusMd => AppRadius.md;
  double get radiusLg => AppRadius.lg;
  double get radiusXl => AppRadius.xl;
  double get radiusPill => AppRadius.pill;
  BorderRadius get radiusSmRadius => AppRadius.smRadius;
  BorderRadius get radiusMdRadius => AppRadius.mdRadius;
  BorderRadius get radiusLgRadius => AppRadius.lgRadius;
  BorderRadius get radiusXlRadius => AppRadius.xlRadius;
  BorderRadius get radiusPillRadius => AppRadius.pillRadius;

  // ── Spacing ─────────────────────────────────────────────────────────────
  double get spaceXs => AppSpacing.xs;
  double get spaceSm => AppSpacing.sm;
  double get spaceMd => AppSpacing.md;
  double get spaceLg => AppSpacing.lg;
  double get spaceXl => AppSpacing.xl;

  // ── Shadows ─────────────────────────────────────────────────────────────
  List<BoxShadow> get shadowCard => AppShadows.card(Theme.of(this).brightness);
  List<BoxShadow> shadowRaised(Color tint) =>
      AppShadows.raised(Theme.of(this).brightness, tint);

  // ── Motion ──────────────────────────────────────────────────────────────
  Duration get motionFast => AppMotion.fast;
  Duration get motionBase => AppMotion.base;
  Duration get motionSlow => AppMotion.slow;
  Curve get motionStandard => AppMotion.standard;
  Curve get motionEmphasized => AppMotion.emphasized;

  // ── Text styles ──────────────────────────────────────────────────────────
  TextStyle heading1({Color? color}) => AppTextStyles.h100(this, color: color);
  TextStyle heading2({Color? color}) => AppTextStyles.h200(this, color: color);
  TextStyle heading3({Color? color}) => AppTextStyles.h300(this, color: color);
  TextStyle heading4({Color? color}) => AppTextStyles.h400(this, color: color);
  TextStyle heading5({Color? color}) => AppTextStyles.h500(this, color: color);
  TextStyle heading6({Color? color}) => AppTextStyles.h600(this, color: color);
  TextStyle textSubtitle1({Color? color}) => AppTextStyles.subtitle1(this, color: color);
  TextStyle textSubtitle2({Color? color}) => AppTextStyles.subtitle2(this, color: color);
  TextStyle textBody1({Color? color}) => AppTextStyles.body1(this, color: color);
  TextStyle textBody2({Color? color}) => AppTextStyles.body2(this, color: color);
  TextStyle textCaption({Color? color}) => AppTextStyles.caption(this, color: color);
  TextStyle textBalance({Color? color}) => AppTextStyles.balance(this, color: color);
}
