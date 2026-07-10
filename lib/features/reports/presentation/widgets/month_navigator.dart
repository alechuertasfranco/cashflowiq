import 'package:cashflowiq/core/theme/theme_extensions.dart';
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
        color: context.colorSurface,
        borderRadius: context.radiusMdRadius,
        border: Border.all(color: context.colorBorder),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: context.colorPrimary,
            onPressed: onPrevious,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$monthName $year',
                style: context.heading5(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: canGoNext ? context.colorPrimary : context.colorMuted,
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}
