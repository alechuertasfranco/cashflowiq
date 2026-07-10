// lib/features/credit_cards/widgets/card.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_card.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';

class CreditCardCard extends StatelessWidget {
  final CreditCard card;
  final VoidCallback? onTap;

  const CreditCardCard({super.key, required this.card, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
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
                    Text(card.name, style: context.textSubtitle1(), overflow: TextOverflow.ellipsis),
                    Text(
                      "${card.bankEntity.code} · ${card.bankEntity.name}",
                      style: context.textCaption(),
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
          Text(card.creditLimitMoney.format(), style: context.textBalance()),

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
        Text(label, style: context.textCaption()),
        const SizedBox(height: 2),
        Text(value, style: context.textBody2()),
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
      decoration: BoxDecoration(color: context.colorSecondary, borderRadius: context.radiusSmRadius),
      child: Text(brand.toUpperCase(), style: context.textCaption()),
    );
  }
}
