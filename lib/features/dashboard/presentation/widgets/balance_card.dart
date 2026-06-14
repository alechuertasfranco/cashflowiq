// lib/features/dashboard/presentation/widgets/balance_card.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/features/dashboard/data/dashboard_summary.dart';
import 'package:flutter/material.dart';

String dashboardCurrencySymbol(String code) {
  const map = {
    'PEN': 'S/',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'CLP': '\$',
    'COP': '\$',
    'MXN': '\$',
    'BRL': 'R\$',
  };
  return map[code] ?? code;
}

class DashboardBalanceCard extends StatelessWidget {
  final List<AccountBalance> accounts;
  final double netBalance;
  final double totalIncome;
  final double totalExpense;

  const DashboardBalanceCard({
    super.key,
    required this.accounts,
    required this.netBalance,
    required this.totalIncome,
    required this.totalExpense,
  });

  Map<String, double> _balancesByCurrency() {
    final map = <String, double>{};
    for (final a in accounts) {
      map[a.currencyCode] = (map[a.currencyCode] ?? 0) + a.balance;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final byCurrency = _balancesByCurrency();
    final displayCode = byCurrency.isEmpty
        ? null
        : byCurrency.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final symbol = displayCode != null ? dashboardCurrencySymbol(displayCode) : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Flujo del mes', style: AppTextStyles.caption(context)),
                const Spacer(),
                if (displayCode != null) CurrencyBadge(code: displayCode),
              ],
            ),
            const SizedBox(height: 8),

            if (byCurrency.isEmpty)
              Text(
                'Sin cuentas registradas',
                style: AppTextStyles.body1(context, color: AppColors.muted),
              )
            else
              AmountText(
                symbol: symbol,
                amount: netBalance,
                style: AppTextStyles.h100(context),
                color: netBalance >= 0 ? AppColors.textPrimary : AppColors.error,
              ),

            if (byCurrency.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'Ingresos',
                      symbol: symbol,
                      amount: totalIncome,
                      sign: '+',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      label: 'Gastos',
                      symbol: symbol,
                      amount: totalExpense,
                      sign: '-',
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String symbol;
  final double amount;
  final String sign;
  final Color color;

  const _StatChip({
    required this.label,
    required this.symbol,
    required this.amount,
    required this.sign,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption(context, color: color)),
          const SizedBox(height: 4),
          AmountText(
            symbol: symbol,
            amount: amount,
            sign: sign,
            style: AppTextStyles.body2(context),
            color: color,
          ),
        ],
      ),
    );
  }
}
