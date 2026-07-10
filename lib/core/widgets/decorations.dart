import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Minimal, flat container used for tappable "field-like" surfaces across
/// the app's forms (date triggers, dropdowns, selectable tiles) — a thin
/// border and a light tint to mark the selected state, no elevation.
BoxDecoration fieldShellDecoration(
  BuildContext context, {
  bool selected = false,
  Color? accentColor,
}) {
  final accent = accentColor ?? context.colorPrimary;
  return BoxDecoration(
    color: selected ? accent.withAlpha(16) : context.colorSurface,
    borderRadius: context.radiusLgRadius,
    border: Border.all(color: selected ? accent : context.colorBorder),
  );
}
