// lib/core/widgets/app_buttons.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';

/// Shared press-scale shell — a small, cheap tactile animation used by all
/// app buttons (matches the "subtle micro-interactions" design goal).
class _PressableScale extends StatefulWidget {
  final bool enabled;
  final VoidCallback? onTap;
  final Color background;
  final BoxBorder? border;
  final BorderRadius radius;
  final Widget child;

  const _PressableScale({
    required this.enabled,
    required this.onTap,
    required this.background,
    required this.radius,
    required this.child,
    this.border,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1;

  void _setPressed(bool pressed) {
    if (!widget.enabled) return;
    setState(() => _scale = pressed ? 0.97 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: context.motionFast,
        curve: context.motionStandard,
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: widget.background,
            borderRadius: widget.radius,
            child: InkWell(
              borderRadius: widget.radius,
              onTap: widget.enabled ? widget.onTap : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(border: widget.border, borderRadius: widget.radius),
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _labelRow(
  BuildContext context, {
  required String label,
  required Color color,
  required bool isLoading,
  IconData? icon,
}) {
  if (isLoading) {
    return SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
      ],
      Text(label, style: context.textSubtitle2(color: color)),
    ],
  );
}

/// Filled CTA — primary action on a screen (submit, save, confirm).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final background = _enabled ? (color ?? context.colorPrimary) : context.colorMuted.withAlpha(90);
    return _PressableScale(
      enabled: _enabled,
      onTap: onPressed,
      radius: context.radiusMdRadius,
      background: background,
      child: _labelRow(
        context,
        label: label,
        color: context.colorOnPrimary,
        isLoading: isLoading,
        icon: icon,
      ),
    );
  }
}

/// Outlined CTA — secondary action alongside a [PrimaryButton] (cancel, back).
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final fg = _enabled ? (color ?? context.colorPrimary) : context.colorMuted;
    return _PressableScale(
      enabled: _enabled,
      onTap: onPressed,
      radius: context.radiusMdRadius,
      background: Colors.transparent,
      border: Border.all(color: _enabled ? (color ?? context.colorPrimary) : context.colorBorder),
      child: _labelRow(context, label: label, color: fg, isLoading: isLoading, icon: icon),
    );
  }
}

/// Text-only CTA — lowest-emphasis action (dismiss, "skip", inline links).
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const GhostButton({super.key, required this.label, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: context.textSubtitle2(color: color ?? context.colorPrimary),
      ),
    );
  }
}
