// lib/core/theme/app_radius.dart

import 'package:flutter/material.dart';

/// Shared corner-radius scale. Replaces the ~11 ad hoc `BorderRadius.circular()`
/// values (2–100px) previously scattered across the app.
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
}
