// lib/features/transactions/presentation/widgets/transaction_type_card.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';

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
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              /// Icon badge (foco visual)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  /// Title (decisión)
                  Text(title, style: AppTextStyles.h300(context, color: AppColors.textPrimary)),

                  /// Description (contexto)
                  Text(description, style: AppTextStyles.caption(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
