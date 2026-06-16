import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/reports/data/reports_models.dart';
import 'package:flutter/material.dart';

class CashflowChartWidget extends StatelessWidget {
  final List<MonthlyTrendPoint> points;
  final List<String> monthShort;

  const CashflowChartWidget({
    super.key,
    required this.points,
    required this.monthShort,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = points.fold(0.0, (max, p) {
      final m = p.totalIncome > p.totalExpense ? p.totalIncome : p.totalExpense;
      return m > max ? m : max;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Evolución mensual', style: AppTextStyles.h500(context)),
                const Spacer(),
                _LegendDot(color: AppColors.success, label: 'Ingresos'),
                const SizedBox(width: 12),
                _LegendDot(color: AppColors.error, label: 'Gastos'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < points.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: _TrendBar(
                        point: points[i],
                        maxVal: maxVal,
                        monthLabel: monthShort[(points[i].month - 1)],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption(context)),
      ],
    );
  }
}

class _TrendBar extends StatelessWidget {
  final MonthlyTrendPoint point;
  final double maxVal;
  final String monthLabel;

  const _TrendBar({
    required this.point,
    required this.maxVal,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    const barAreaHeight = 88.0;
    final incomeH = maxVal > 0 ? (point.totalIncome / maxVal * barAreaHeight) : 0.0;
    final expenseH = maxVal > 0 ? (point.totalExpense / maxVal * barAreaHeight) : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Bar(height: incomeH, color: AppColors.success),
            const SizedBox(width: 2),
            _Bar(height: expenseH, color: AppColors.error),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          monthLabel,
          style: AppTextStyles.caption(context, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      width: 10,
      height: height.clamp(2.0, double.infinity),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
  }
}
