import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class MonthNavigator extends StatelessWidget {
  final String monthName;
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  const MonthNavigator({
    super.key,
    required this.monthName,
    required this.year,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppColors.primary,
            onPressed: onPrevious,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$monthName $year',
                style: AppTextStyles.h500(context),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: canGoNext ? AppColors.primary : AppColors.muted,
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}
