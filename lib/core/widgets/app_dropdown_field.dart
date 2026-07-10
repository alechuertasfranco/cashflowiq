// lib/core/widgets/app_dropdown_field.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';

/// Shared dropdown field: same label-above-field shell as [AppTextField],
/// a brand-colored chevron instead of the stock Material arrow, and a
/// themed popup surface — replaces raw `DropdownButtonFormField` call sites.
class AppDropdownField<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final String? hintText;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const AppDropdownField({
    super.key,
    required this.items,
    required this.onChanged,
    this.label,
    this.value,
    this.hintText,
    this.enabled = true,
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
        Container(
          decoration: fieldShellDecoration(context),
          child: DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: enabled ? onChanged : null,
            icon: Icon(Icons.expand_more_rounded, color: context.colorPrimary),
            dropdownColor: context.colorSurfaceElevated,
            borderRadius: context.radiusLgRadius,
            style: context.textSubtitle1(),
            hint: hintText != null
                ? Text(hintText!, style: context.textSubtitle2(color: context.colorMuted))
                : null,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: context.radiusLgRadius, borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: context.radiusLgRadius, borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: context.radiusLgRadius, borderSide: BorderSide.none),
            ),
          ),
        ),
      ],
    );
  }
}
