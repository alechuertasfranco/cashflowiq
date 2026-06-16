import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// BuildContext extension for ergonomic access to design tokens.
/// Prefer these over `AppColors.x` / `AppTextStyles.x(context)` in new code.
extension AppThemeContext on BuildContext {
  // ── Colors ──────────────────────────────────────────────────────────────
  Color get colorPrimary => AppColors.primary;
  Color get colorAccent => AppColors.accent;
  Color get colorBackground => AppColors.background;
  Color get colorSurface => AppColors.surface;
  Color get colorSurfaceVariant => AppColors.surfaceVariant;
  Color get colorBorder => AppColors.border;
  Color get colorTextPrimary => AppColors.textPrimary;
  Color get colorTextSecondary => AppColors.textSecondary;
  Color get colorMuted => AppColors.muted;
  Color get colorError => AppColors.error;
  Color get colorSuccess => AppColors.success;

  // ── Text styles ──────────────────────────────────────────────────────────
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
