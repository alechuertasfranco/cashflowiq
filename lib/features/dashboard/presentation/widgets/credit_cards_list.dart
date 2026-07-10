import 'package:cashflowiq/core/theme/theme_extensions.dart';
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
                  style: context.textBody1(color: context.colorMuted),
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
      ratioColor = context.colorError;
    } else if (ratio >= 0.7) {
      ratioColor = context.colorWarning;
    } else {
      ratioColor = context.colorSuccess;
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
                          Text(card.name, style: context.textSubtitle1()),
                          const SizedBox(width: 6),
                          _BrandBadge(brand: card.brand),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.bankEntityCode,
                        style: context.textCaption(),
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
                      style: context.heading6(),
                      color: context.colorError,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'de ${card.creditLimit.toStringAsFixed(2)}',
                      style: context.textCaption(color: context.colorMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: context.radiusSmRadius,
              child: LinearProgressIndicator(
                value: ratio.clamp(0, 1),
                backgroundColor: context.colorBorder,
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
                  style: context.textCaption(color: context.colorTextSecondary),
                ),
                Text(
                  'Cierre: ${card.closingDay}  |  Vcto: ${card.dueDay}',
                  style: context.textCaption(color: context.colorTextSecondary),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.colorSecondary,
        borderRadius: context.radiusSmRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.credit_card, size: 12, color: context.colorPrimary),
          const SizedBox(width: 3),
          Text(
            brand.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.colorPrimary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
