import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';

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
            Icon(icon, size: 56, color: context.colorTextSecondary),
            const SizedBox(height: 16),
            Text(title, style: context.heading3(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              description,
              style: context.textBody1(color: context.colorTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: actionText, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}
