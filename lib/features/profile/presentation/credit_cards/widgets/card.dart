// lib/features/credit_cards/widgets/card.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';

class CreditCardCard extends StatelessWidget {
  final CreditCard card;
  final VoidCallback? onTap;

  const CreditCardCard({super.key, required this.card, this.onTap});

  @override
  Widget build(BuildContext context) {
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
            /// 🔹 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.name, style: AppTextStyles.subtitle1(context), overflow: TextOverflow.ellipsis),
                      Text(
                        "${card.bankEntity.code} · ${card.bankEntity.name}",
                        style: AppTextStyles.caption(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _BrandBadge(brand: card.brand.name),
              ],
            ),

            const SizedBox(height: 12),

            /// 🔹 LÍNEA DE CRÉDITO (DECISIÓN)
            Text(card.creditLimitMoney.format(), style: AppTextStyles.balance(context)),

            const SizedBox(height: 12),

            /// 🔹 CONTEXTO FINANCIERO
            Row(
              children: [
                Expanded(
                  child: _InfoItem(label: "Cierre", value: "Día ${card.closingDay}"),
                ),
                Expanded(
                  child: _InfoItem(label: "Pago", value: "Día ${card.dueDay}"),
                ),
              ],
            ),

            if (card.interestRate != null) ...[
              const SizedBox(height: 8),
              _InfoItem(label: "Interés", value: "${card.interestRate}%"),
            ],
          ],
        ),
      ),
    );
  }
}

/// 🔹 ITEM DE CONTEXTO (reutilizable)
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption(context)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.body2(context)),
      ],
    );
  }
}

/// 🔹 BADGE DE MARCA
class _BrandBadge extends StatelessWidget {
  final String brand;

  const _BrandBadge({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
      child: Text(brand.toUpperCase(), style: AppTextStyles.caption(context)),
    );
  }
}
