// lib/core/theme/app_shadows.dart

import 'package:flutter/material.dart';

/// Elevation as shadows in light mode; shadows are barely visible on dark
/// surfaces, so dark mode gets a subtle top highlight border instead.
class AppShadows {
  static List<BoxShadow> card(Brightness brightness) {
    if (brightness == Brightness.dark) return const [];
    return [
      BoxShadow(
        color: Colors.black.withAlpha(15),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> raised(Brightness brightness, Color tint) {
    if (brightness == Brightness.dark) {
      return [
        BoxShadow(color: tint.withAlpha(90), blurRadius: 20, offset: const Offset(0, 8)),
      ];
    }
    return [
      BoxShadow(color: tint.withAlpha(70), blurRadius: 16, offset: const Offset(0, 6)),
    ];
  }
}
