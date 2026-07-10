// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

/// Light palette. Also the source of compile-time `const` color values used
/// in the rare places that require a const default (e.g. default parameter
/// values). Everywhere else, prefer the reactive `context.colorX` getters in
/// theme_extensions.dart so colors adapt to dark mode.
class AppColors {
  // Brand
  static const primary = Color(0xFF1A6982);
  static const secondary = Color(0xFFD5EFF1);
  static const complementary = Color(0xFF2989C7);
  static const accent = Color(0xFF3DC3A2);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const successStrong = Color(0xFF16A34A);
  static const error = Color(0xFFEF4444);
  static const errorStrong = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const warningStrong = Color(0xFFD97706);

  // Surfaces
  static const background = Color(0xFFF1F5F9);
  static const surface = Colors.white;
  static const surfaceVariant = Color(0xFFF8FAFC);
  static const surfaceElevated = Colors.white;

  // Text
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const onPrimary = Colors.white;
  static const onSecondary = Colors.white;
  static const onSurface = Color(0xFF0F172A);

  // UI
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEEF2F6);
  static const muted = Color(0xFF94A3B8);
}

/// Dark palette — mirrors [AppColors] field-for-field so both can back the
/// same [AppColorTokens] theme extension.
class AppColorsDark {
  // Brand — lightened for contrast against dark surfaces.
  static const primary = Color(0xFF4FB8D6);
  static const secondary = Color(0xFF1B3A42);
  static const complementary = Color(0xFF5AA9E0);
  static const accent = Color(0xFF52D9B5);

  // Semantic
  static const success = Color(0xFF34D399);
  static const successStrong = Color(0xFF10B981);
  static const error = Color(0xFFF87171);
  static const errorStrong = Color(0xFFEF4444);
  static const warning = Color(0xFFFBBF24);
  static const warningStrong = Color(0xFFF59E0B);

  // Surfaces
  static const background = Color(0xFF0B1220);
  static const surface = Color(0xFF121A2B);
  static const surfaceVariant = Color(0xFF182238);
  static const surfaceElevated = Color(0xFF1B2740);

  // Text
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const onPrimary = Color(0xFF04141A);
  static const onSecondary = Color(0xFFF1F5F9);
  static const onSurface = Color(0xFFF1F5F9);

  // UI
  static const border = Color(0xFF263349);
  static const divider = Color(0xFF1E293B);
  static const muted = Color(0xFF64748B);
}
