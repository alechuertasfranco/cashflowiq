import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/features/dashboard/data/dashboard_summary.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/balance_card/currency_utils.dart';
import 'package:flutter/material.dart';

class DashboardCreditCardsList extends StatelessWidget {
  final List<CreditCardBalance> cards;

  const DashboardCreditCardsList({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cards.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Sin tarjetas de crédito',
                  style: AppTextStyles.body1(context, color: AppColors.muted),
                ),
              ),
            ),
          )
        else
          ...cards.map((card) => _CreditCardRow(card: card)),
      ],
    );
  }
}

class _CreditCardRow extends StatelessWidget {
  final CreditCardBalance card;

  const _CreditCardRow({required this.card});

  @override
  Widget build(BuildContext context) {
    final symbol = dashboardCurrencySymbol(card.currencyCode);
    final ratio = card.utilizationRatio;
    final available = card.availableCredit;

    final Color ratioColor;
    if (ratio >= 0.9) {
      ratioColor = AppColors.error;
    } else if (ratio >= 0.7) {
      ratioColor = Colors.orange;
    } else {
      ratioColor = AppColors.success;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(card.name, style: AppTextStyles.subtitle1(context)),
                          const SizedBox(width: 6),
                          _BrandBadge(brand: card.brand),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.bankEntityCode,
                        style: AppTextStyles.caption(context),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AmountText(
                      symbol: symbol,
                      amount: card.usedAmount,
                      style: AppTextStyles.h600(context),
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'de ${card.creditLimit.toStringAsFixed(2)}',
                      style: AppTextStyles.caption(context, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0, 1),
                backgroundColor: AppColors.border,
                color: ratioColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Disponible: $symbol ${available.toStringAsFixed(2)}',
                  style: AppTextStyles.caption(context, color: AppColors.textSecondary),
                ),
                Text(
                  'Cierre: ${card.closingDay}  |  Vcto: ${card.dueDay}',
                  style: AppTextStyles.caption(context, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  final String brand;

  const _BrandBadge({required this.brand});

  @override
  Widget build(BuildContext context) {
    final icon = switch (brand.toUpperCase()) {
      'VISA' => Icons.credit_card,
      'MASTERCARD' => Icons.credit_card,
      'AMEX' => Icons.credit_card,
      'DISCOVER' => Icons.credit_card,
      'DINERS' => Icons.credit_card,
      _ => Icons.credit_card,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            brand.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
