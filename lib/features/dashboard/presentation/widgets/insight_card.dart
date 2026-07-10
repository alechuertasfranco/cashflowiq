// lib/features/dashboard/presentation/widgets/insight_card.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/features/dashboard/data/dashboard_summary.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/balance_card/currency_utils.dart';
import 'package:flutter/material.dart';

class DashboardInsightCard extends StatelessWidget {
  final AccountBalance? mostActiveAccount;
  final String? mostActiveAccountName;
  final int mostActiveAccountTxCount;

  const DashboardInsightCard({
    super.key,
    required this.mostActiveAccount,
    required this.mostActiveAccountName,
    required this.mostActiveAccountTxCount,
  });

  @override
  Widget build(BuildContext context) {
    if (mostActiveAccountName == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.account_balance_outlined, color: context.colorMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Agrega cuentas bancarias para ver tus insights',
                  style: context.textSubtitle2(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final account = mostActiveAccount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + movimientos
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: context.colorPrimary, size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Cuenta más activa este mes',
                    style: context.textCaption(color: context.colorTextSecondary),
                  ),
                ),
                Text(
                  '$mostActiveAccountTxCount mov. este mes',
                  style: context.textCaption(color: context.colorMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Entidad + nombre + balance
            Row(
              children: [
                if (account != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.colorPrimary.withAlpha(18),
                      borderRadius: context.radiusSmRadius,
                    ),
                    child: Text(
                      account.bankEntityCode,
                      style: context.textCaption(color: context.colorPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    account?.name ?? mostActiveAccountName!,
                    style: context.textSubtitle2(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (account != null) ...[
                  const SizedBox(width: 12),
                  AmountText(
                    symbol: dashboardCurrencySymbol(account.currencyCode),
                    amount: account.balance,
                    style: context.textSubtitle1(),
                    color: context.colorPrimary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
