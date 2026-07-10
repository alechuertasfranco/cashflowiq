// lib/core/theme/app_text_styles.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color_tokens.dart';

class AppTextStyles {
  static Color _primary(BuildContext context) =>
      (Theme.of(context).extension<AppColorTokens>() ?? AppColorTokens.light).textPrimary;

  static Color _secondary(BuildContext context) =>
      (Theme.of(context).extension<AppColorTokens>() ?? AppColorTokens.light).textSecondary;

  // =========================
  // Headings (Sora)
  // =========================

  static TextStyle h100(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 32, fontWeight: FontWeight.w700, color: color ?? _primary(context));
  }

  static TextStyle h200(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w700, color: color ?? _primary(context));
  }

  static TextStyle h300(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w600, color: color ?? _primary(context));
  }

  static TextStyle h400(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600, color: color ?? _primary(context));
  }

  static TextStyle h500(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600, color: color ?? _primary(context));
  }

  static TextStyle h600(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? _primary(context));
  }

  // =========================
  // Body (Urbanist)
  // =========================

  static TextStyle subtitle1(BuildContext context, {Color? color}) {
    return GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w500, color: color ?? _primary(context));
  }

  static TextStyle subtitle2(BuildContext context, {Color? color}) {
    return GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w500, color: color ?? _secondary(context));
  }

  static TextStyle body1(BuildContext context, {Color? color}) {
    return GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w400, color: color ?? _primary(context));
  }

  static TextStyle body2(BuildContext context, {Color? color}) {
    return GoogleFonts.urbanist(fontSize: 13, fontWeight: FontWeight.w400, color: color ?? _secondary(context));
  }

  static TextStyle caption(BuildContext context, {Color? color}) {
    return GoogleFonts.urbanist(fontSize: 12, fontWeight: FontWeight.w400, color: color ?? _secondary(context));
  }

  // =========================
  // Custom
  // =========================

  static TextStyle balance(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w700, color: color ?? _primary(context));
  }
}
