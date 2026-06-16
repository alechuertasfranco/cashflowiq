import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            label: 'Gasto',
            selected: selected == 'EXPENSE',
            color: AppColors.error,
            onTap: () => onChanged('EXPENSE'),
            isLeft: true,
          ),
          _ToggleOption(
            label: 'Ingreso',
            selected: selected == 'INCOME',
            color: AppColors.success,
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(7) : Radius.zero,
            right: isLeft ? Radius.zero : const Radius.circular(7),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption(
            context,
            color: selected ? color : AppColors.muted,
          ).copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }
}
