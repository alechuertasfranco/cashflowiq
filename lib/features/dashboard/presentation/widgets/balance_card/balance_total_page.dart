import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/balance_card/stat_chip.dart';
import 'package:flutter/material.dart';

class BalanceTotalPage extends StatelessWidget {
  final String symbol;
  final String? displayCode;
  final bool hasAccounts;
  final double totalBalance;
  final double allTimeIncome;
  final double allTimeExpense;

  const BalanceTotalPage({
    super.key,
    required this.symbol,
    required this.displayCode,
    required this.hasAccounts,
    required this.totalBalance,
    required this.allTimeIncome,
    required this.allTimeExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Balance total', style: AppTextStyles.caption(context)),
              const Spacer(),
              if (displayCode != null) CurrencyBadge(code: displayCode!),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasAccounts)
            Text('Sin cuentas registradas', style: AppTextStyles.body1(context, color: AppColors.muted))
          else
            AmountText(
              symbol: symbol,
              amount: totalBalance,
              style: AppTextStyles.h100(context),
              color: AppColors.textPrimary,
            ),
          const SizedBox(height: 16),
          if (hasAccounts)
            Row(
              children: [
                Expanded(
                  child: StatChip(
                    label: 'Ingresos totales',
                    symbol: symbol,
                    amount: allTimeIncome,
                    sign: '+',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatChip(
                    label: 'Gastos totales',
                    symbol: symbol,
                    amount: allTimeExpense,
                    sign: '-',
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
