// lib/features/dashboard/presentation/widgets/insight_card.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
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
              const Icon(Icons.account_balance_outlined, color: AppColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Agrega cuentas bancarias para ver tus insights',
                  style: AppTextStyles.subtitle2(context),
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
                const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Cuenta más activa este mes',
                    style: AppTextStyles.caption(context, color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  '$mostActiveAccountTxCount mov. este mes',
                  style: AppTextStyles.caption(context, color: AppColors.muted),
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
                      color: AppColors.primary.withAlpha(18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      account.bankEntityCode,
                      style: AppTextStyles.caption(context, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    account?.name ?? mostActiveAccountName!,
                    style: AppTextStyles.subtitle2(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (account != null) ...[
                  const SizedBox(width: 12),
                  AmountText(
                    symbol: dashboardCurrencySymbol(account.currencyCode),
                    amount: account.balance,
                    style: AppTextStyles.subtitle1(context),
                    color: AppColors.primary,
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
