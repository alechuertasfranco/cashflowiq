import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/balance_card/stat_chip.dart';
import 'package:flutter/material.dart';

class MonthlyFlowPage extends StatelessWidget {
  final String symbol;
  final String? displayCode;
  final bool hasAccounts;
  final double netBalance;
  final double totalIncome;
  final double totalExpense;

  const MonthlyFlowPage({
    super.key,
    required this.symbol,
    required this.displayCode,
    required this.hasAccounts,
    required this.netBalance,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Flujo del mes', style: context.textCaption()),
              const Spacer(),
              if (displayCode != null) CurrencyBadge(code: displayCode!),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasAccounts)
            Text('Sin cuentas registradas', style: context.textBody1(color: context.colorMuted))
          else
            AmountText(
              symbol: symbol,
              amount: netBalance,
              style: context.heading1(),
              color: netBalance >= 0 ? context.colorTextPrimary : context.colorError,
            ),
          const SizedBox(height: 16),
          if (hasAccounts)
            Row(
              children: [
                Expanded(
                  child: StatChip(
                    label: 'Ingresos',
                    symbol: symbol,
                    amount: totalIncome,
                    sign: '+',
                    color: context.colorSuccess,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatChip(
                    label: 'Gastos',
                    symbol: symbol,
                    amount: totalExpense,
                    sign: '-',
                    color: context.colorError,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
