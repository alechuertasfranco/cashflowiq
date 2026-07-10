// lib/core/widgets/app_text_field.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';

/// Shared text field: label above a soft, shadow-elevated shell that glows
/// with the accent color on focus instead of the flat Material outline.
class AppTextField extends StatefulWidget {
  final String? label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
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
    this.focusNode,
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
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focused != _focusNode.hasFocus) setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final accent = hasError ? context.colorError : context.colorPrimary;
    final borderColor = hasError
        ? context.colorError
        : (_focused ? context.colorPrimary : context.colorBorder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: context
                .textCaption(color: _focused ? accent : context.colorTextSecondary)
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: context.motionFast,
          curve: context.motionStandard,
          decoration: BoxDecoration(
            color: widget.enabled ? context.colorSurface : context.colorSurfaceVariant,
            borderRadius: context.radiusLgRadius,
            border: Border.all(color: borderColor),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.textCapitalization,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            validator: widget.validator,
            style: context.textSubtitle1(),
            cursorColor: context.colorPrimary,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: context.textSubtitle2(color: context.colorMuted),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              prefixText: widget.prefixText,
              prefixStyle: context.textSubtitle1(color: context.colorTextSecondary),
              suffixText: widget.suffixText,
              suffixStyle: context.textSubtitle1(color: context.colorTextSecondary),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: context.radiusLgRadius, borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: context.radiusLgRadius, borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: context.radiusLgRadius, borderSide: BorderSide.none),
              disabledBorder: OutlineInputBorder(
                  borderRadius: context.radiusLgRadius, borderSide: BorderSide.none),
              errorBorder: OutlineInputBorder(
                  borderRadius: context.radiusLgRadius, borderSide: BorderSide.none),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: context.radiusLgRadius, borderSide: BorderSide.none),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 14, color: context.colorError),
              const SizedBox(width: 4),
              Flexible(
                child: Text(widget.errorText!, style: context.textCaption(color: context.colorError)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
