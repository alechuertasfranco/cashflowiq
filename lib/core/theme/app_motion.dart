// lib/core/theme/app_motion.dart

import 'package:flutter/material.dart';

/// Shared motion tokens for micro-interactions and transitions.
class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve press = Curves.easeOut;
}
