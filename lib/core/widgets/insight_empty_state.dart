import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';

class InsightEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionText;
  final VoidCallback onAction;

  const InsightEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 🔹 Icono (contexto)
            Icon(icon, size: 56, color: AppColors.textSecondary),

            const SizedBox(height: 16),

            /// 🔹 Título (decisión)
            Text(title, style: AppTextStyles.h300(context), textAlign: TextAlign.center),

            const SizedBox(height: 8),

            /// 🔹 Descripción (educación financiera)
            Text(
              description,
              style: AppTextStyles.body1(context, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            /// 🔹 Acción (decisión)
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionText, style: AppTextStyles.subtitle2(context, color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
