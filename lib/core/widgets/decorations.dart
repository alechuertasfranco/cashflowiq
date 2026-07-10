import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

InputDecoration inputDecoration(BuildContext context, String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: context.textSubtitle2(color: context.colorMuted),
    filled: true,
    fillColor: context.colorSurface,
    border: OutlineInputBorder(
      borderRadius: context.radiusMdRadius,
      borderSide: BorderSide(color: context.colorBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: context.radiusMdRadius,
      borderSide: BorderSide(color: context.colorBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: context.radiusMdRadius,
      borderSide: BorderSide(color: context.colorPrimary, width: 1.5),
    ),
  );
}
