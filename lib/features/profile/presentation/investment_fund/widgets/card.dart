// lib/features/investment_fund/widgets/card.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_card.dart';
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

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fund.name,
                  style: context.textSubtitle1(),
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
            style: context.textBalance(),
          ),

          if (hasCurrentValue) ...[
            const SizedBox(height: 4),
            // Secondary: invested amount
            Text(
              "Invertido: ${fund.investedMoney.format()}",
              style: context.textBody2(color: context.colorTextSecondary),
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
          Text(fund.bankEntity.name, style: context.textBody2()),
        ],
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
    final color = isGain ? context.colorSuccess : context.colorError;
    final sign = isGain ? '+' : '';
    final label = '$sign$symbol ${diff.abs().toStringAsFixed(decimals)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: context.radiusSmRadius,
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
          Text(label, style: context.textCaption(color: color)),
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
      decoration: BoxDecoration(color: type.color, borderRadius: context.radiusSmRadius),
      child: Text(type.toLabel(), style: context.textCaption()),
    );
  }
}
