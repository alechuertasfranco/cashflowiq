// lib/core/widgets/app_dialog.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';

/// Confirmation dialog shell (delete/discard/leave-without-saving prompts).
/// Shape/color come from `DialogThemeData` (app_theme.dart).
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirmar',
  String cancelText = 'Cancelar',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title, style: context.heading4()),
        content: Text(message, style: context.textBody1(color: context.colorTextSecondary)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Expanded(
            child: SecondaryButton(
              label: cancelText,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: confirmText,
              color: isDestructive ? context.colorError : null,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
