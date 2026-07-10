// lib/core/widgets/app_text_field.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';

/// Shared text field: optional label above a themed input. Border color
/// transitions on focus are handled automatically by Flutter's
/// `InputDecorationTheme` (registered globally in app_theme.dart).
class AppTextField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: context.textSubtitle2(color: context.colorMuted)),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: obscureText ? 1 : maxLines,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          autofocus: autofocus,
          onChanged: onChanged,
          validator: validator,
          style: context.textSubtitle1(),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: context.textSubtitle2(color: context.colorMuted),
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            prefixText: prefixText,
            prefixStyle: context.textSubtitle1(color: context.colorTextSecondary),
            suffixText: suffixText,
            suffixStyle: context.textSubtitle1(color: context.colorTextSecondary),
          ),
        ),
      ],
    );
  }
}
