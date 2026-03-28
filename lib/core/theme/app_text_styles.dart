// lib/core/theme/app_text_styles.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // =========================
  // 🔷 HEADINGS (Sora)
  // =========================

  static TextStyle h100(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 32, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary);
  }

  static TextStyle h200(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary);
  }

  static TextStyle h300(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary);
  }

  static TextStyle h400(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary);
  }

  static TextStyle h500(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary);
  }

  static TextStyle h600(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary);
  }

  // =========================
  // 🔶 BODY (Urbanist)
  // =========================

  static TextStyle subtitle1(BuildContext context, {Color? color}) {
    return GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w500, color: color ?? AppColors.textPrimary);
  }

  static TextStyle subtitle2(BuildContext context, {Color? color}) {
    return GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w500, color: color ?? AppColors.textSecondary);
  }

  static TextStyle body1(BuildContext context, {Color? color}) {
    return GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w400, color: color ?? AppColors.textPrimary);
  }

  static TextStyle body2(BuildContext context, {Color? color}) {
    return GoogleFonts.urbanist(fontSize: 13, fontWeight: FontWeight.w400, color: color ?? AppColors.textSecondary);
  }

  static TextStyle caption(BuildContext context, {Color? color}) {
    return GoogleFonts.urbanist(fontSize: 12, fontWeight: FontWeight.w400, color: color ?? AppColors.textSecondary);
  }

  // =========================
  // 💰 Personalizado
  // =========================

  static TextStyle balance(BuildContext context, {Color? color}) {
    return GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary);
  }
}
