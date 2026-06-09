// lib/features/investment_fund/widgets/card.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/shared/models/investment_fund.dart';

class InvestmentFundCard extends StatelessWidget {
  final InvestmentFund fund;
  final VoidCallback? onTap;

  const InvestmentFundCard({super.key, required this.fund, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasCurrentValue = fund.currentValue != null;
    final diff = hasCurrentValue ? fund.currentValue! - fund.investedAmount : null;
    final isGain = diff != null && diff >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    fund.name,
                    style: AppTextStyles.subtitle1(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _TypeBadge(type: fund.fundType),
              ],
            ),

            const SizedBox(height: 12),

            // Primary: current value if available, otherwise invested amount
            Text(
              hasCurrentValue
                  ? fund.currentValueMoney!.format()
                  : fund.investedMoney.format(),
              style: AppTextStyles.balance(context),
            ),

            if (hasCurrentValue) ...[
              const SizedBox(height: 4),
              // Secondary: invested amount
              Text(
                "Invertido: ${fund.investedMoney.format()}",
                style: AppTextStyles.body2(context, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              // Diff chip: gain or loss
              _DiffChip(
                diff: diff!,
                symbol: fund.currency.symbol,
                decimals: fund.currency.decimals,
                isGain: isGain,
              ),
            ],

            const SizedBox(height: 8),
            Text(fund.bankEntity.name, style: AppTextStyles.body2(context)),
          ],
        ),
      ),
    );
  }
}

class _DiffChip extends StatelessWidget {
  final double diff;
  final String symbol;
  final int decimals;
  final bool isGain;

  const _DiffChip({
    required this.diff,
    required this.symbol,
    required this.decimals,
    required this.isGain,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGain ? AppColors.success : AppColors.error;
    final sign = isGain ? '+' : '';
    final label = '$sign$symbol ${diff.abs().toStringAsFixed(decimals)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGain ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption(context, color: color)),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final InvestmentFundType type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: type.color, borderRadius: BorderRadius.circular(8)),
      child: Text(type.toLabel(), style: AppTextStyles.caption(context)),
    );
  }
}
