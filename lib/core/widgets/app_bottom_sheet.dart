// lib/core/widgets/app_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';

/// Shared bottom sheet shell: drag handle + consistent padding/rounding.
/// Colors/shape come from `BottomSheetThemeData` (app_theme.dart) so this
/// only needs to add the drag handle and safe-area padding.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorBorder,
                  borderRadius: context.radiusPillRadius,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(child: builder(context)),
            ],
          ),
        ),
      );
    },
  );
}
