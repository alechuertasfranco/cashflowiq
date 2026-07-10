// lib/core/widgets/app_card.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';

/// Shared card shell — consistent radius/padding/elevation across the app.
/// Domain-specific cards (bank account, credit card, investment fund, ...)
/// keep their own internal layout and just wrap it in this shell.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? context.colorSurface,
        borderRadius: context.radiusLgRadius,
        boxShadow: context.shadowCard,
        border: context.isDark ? Border.all(color: context.colorBorder) : null,
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : Material(
              color: Colors.transparent,
              borderRadius: context.radiusLgRadius,
              child: InkWell(
                borderRadius: context.radiusLgRadius,
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
            ),
    );
    return card;
  }
}

/// Row-shaped list item: leading icon in a tinted circle, title/subtitle,
/// optional trailing widget. Generalizes the "item card" pattern repeated
/// across bank accounts / credit cards / investment funds.
class AppListTile extends StatelessWidget {
  final IconData leadingIcon;
  final Color? leadingColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppListTile({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.leadingColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = leadingColor ?? context.colorPrimary;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tint.withAlpha(30), shape: BoxShape.circle),
            child: Icon(leadingIcon, color: tint, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: context.textSubtitle1(), overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: context.textBody2(), overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
