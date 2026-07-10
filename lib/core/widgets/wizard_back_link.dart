// lib/core/widgets/wizard_back_link.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Breadcrumb-style "back" link used at the top of wizard sub-steps (e.g.
/// "‹ Entidades", "‹ Categorías") — a circular chevron badge plus label,
/// replacing the bare `TextButton.icon` that used to sit there.
class WizardBackLink extends StatelessWidget {
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const WizardBackLink({
    super.key,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: accentColor.withAlpha(22), shape: BoxShape.circle),
              child: Icon(Icons.arrow_back_rounded, size: 14, color: accentColor),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: context
                  .textSubtitle2(color: context.colorTextSecondary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill button used for inline "add" actions inside wizard sub-steps
/// (e.g. "+ Nueva categoría") — replaces the bare `TextButton.icon`.
class WizardAddLink extends StatelessWidget {
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const WizardAddLink({
    super.key,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withAlpha(18),
          borderRadius: context.radiusPillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 15, color: accentColor),
            const SizedBox(width: 3),
            Text(
              label,
              style: context.textCaption(color: accentColor).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
