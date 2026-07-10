import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ReportFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const ReportFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorBackground,
        borderRadius: context.radiusSmRadius,
        border: Border.all(color: context.colorBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            label: 'Gasto',
            selected: selected == 'EXPENSE',
            color: context.colorError,
            onTap: () => onChanged('EXPENSE'),
            isLeft: true,
          ),
          _ToggleOption(
            label: 'Ingreso',
            selected: selected == 'INCOME',
            color: context.colorSuccess,
            onTap: () => onChanged('INCOME'),
            isLeft: false,
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final bool isLeft;

  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motionFast,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? Radius.circular(context.radiusSm - 1) : Radius.zero,
            right: isLeft ? Radius.zero : Radius.circular(context.radiusSm - 1),
          ),
        ),
        child: Text(
          label,
          style: context.textCaption(
            color: selected ? color : context.colorMuted,
          ).copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }
}
