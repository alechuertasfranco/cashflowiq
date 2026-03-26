import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // =========================
  // 🔷 HEADINGS (Inter)
  // =========================

  static TextStyle h100(BuildContext context) {
    return GoogleFonts.sora(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  }

  static TextStyle h200(BuildContext context) {
    return GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  }

  static TextStyle h300(BuildContext context) {
    return GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  }

  static TextStyle h400(BuildContext context) {
    return GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  }

  static TextStyle h500(BuildContext context) {
    return GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  }

  static TextStyle h600(BuildContext context) {
    return GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  }

  // =========================
  // 🔶 BODY (Poppins)
  // =========================

  static TextStyle subtitle1(BuildContext context) {
    return GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  }

  static TextStyle subtitle2(BuildContext context) {
    return GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  }

  static TextStyle body1(BuildContext context) {
    return GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  }

  static TextStyle body2(BuildContext context) {
    return GoogleFonts.urbanist(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  }

  static TextStyle caption(BuildContext context) {
    return GoogleFonts.urbanist(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  }

  // =========================
  // 💰 Personalizado
  // =========================

  static TextStyle balance(BuildContext context) {
    return GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  }
}
