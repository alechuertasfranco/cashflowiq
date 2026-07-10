// lib/features/transactions/presentation/widgets/transaction_type_card.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';

class TransactionTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color; // 👈 color semántico (acción)
  final VoidCallback onTap;

  const TransactionTypeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorSurfaceVariant,
      borderRadius: context.radiusLgRadius,
      child: InkWell(
        borderRadius: context.radiusLgRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: context.radiusLgRadius,
            border: Border.all(color: context.colorBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              /// Icon badge (foco visual)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: context.radiusMdRadius),
                child: Icon(icon, color: color, size: 28),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  /// Title (decisión)
                  Text(title, style: context.heading3(color: context.colorTextPrimary)),

                  /// Description (contexto)
                  Text(description, style: context.textCaption()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
