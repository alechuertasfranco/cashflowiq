// lib/features/profile/presentation/categories/widgets/category_card.dart

import 'package:cashflowiq/core/widgets/app_bottom_sheet.dart';
import 'package:cashflowiq/core/widgets/app_card.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_budget_screen.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/money.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/shared/models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  final bool isExpanded;
  final VoidCallback? onToggle;
  final void Function(Category category)? onEdit;
  final void Function(Category category)? onDelete;
  final VoidCallback? onBudgetUpdated;

  const CategoryCard({
    super.key,
    required this.category,
    this.isExpanded = false,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.onBudgetUpdated,
  });

  bool get _isParent => category.parentId == null;

  double? get _amount => category.budget?.amount;
  double? get _spent => category.budget?.spent;

  bool get _hasBudget => _amount != null && _amount! > 0;
  Currency? get _budgetCurrency => category.budget?.currency;

  double? get _progress {
    if (_amount == null || _amount == 0) return null;
    return (_spent ?? 0) / _amount!;
  }

  Future<void> _onSetBudget(BuildContext context) async {
    final result = await showAppBottomSheet<bool>(
      context,
      builder: (_) => FormBudgetScreen(category: category),
    );
    if (result == true) onBudgetUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: _isParent ? 14 : 10,
      ),
      onTap: _isParent ? onToggle : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIcon(context),
          const SizedBox(width: 12),
          Expanded(child: _buildContent(context)),
          _buildActions(context),
        ],
      ),
    );
  }

  // ── Icon ──────────────────────────────────────────────────────────────────

  Widget _buildIcon(BuildContext context) {
    final cat = parseHexColor(category.color);
    final double size = _isParent ? 38 : 28;
    final double iconSize = _isParent ? 20 : 14;
    final radius = _isParent ? context.radiusSmRadius : context.radiusSmRadius;

    // Parent: solid color background, contrast icon
    // Child: light tint background, saturated category color icon
    final bgColor = _isParent ? cat : cat.withAlpha(30);
    final iconColor = _isParent ? getContrastColor(cat) : cat;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
      ),
      child: Icon(parseIcon(category.icon), color: iconColor, size: iconSize),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name,
          style: _isParent
              ? context.textSubtitle1()
              : context.textBody2(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (_isParent && _hasBudget && _budgetCurrency != null) ...[
          const SizedBox(height: 8),
          _BudgetBar(
            spent: _spent ?? 0,
            amount: _amount!,
            currency: _budgetCurrency!,
            progress: (_progress ?? 0).clamp(0.0, 1.0),
            progressColor: _progressColor(context),
          ),
        ],
        if (_isParent && !_hasBudget) ...[
          const SizedBox(height: 2),
          Text(
            'Sin presupuesto',
            style: context.textCaption(color: context.colorMuted),
          ),
        ],
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isParent) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onSetBudget(context),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: context.colorPrimary,
              ),
            ),
          ),
        ],
        PopupMenuButton<String>(
          iconSize: 18,
          padding: EdgeInsets.zero,
          icon: Icon(Icons.more_vert, color: context.colorMuted),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 16, color: context.colorComplementary),
                  const SizedBox(width: 10),
                  Text('Editar', style: context.textBody2()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 16, color: context.colorError),
                  const SizedBox(width: 10),
                  Text('Eliminar', style: context.textBody2(color: context.colorError)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') onEdit?.call(category);
            if (value == 'delete') onDelete?.call(category);
          },
        ),
        if (_isParent) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: context.motionFast,
                child: Icon(Icons.keyboard_arrow_down, size: 22, color: context.colorMuted),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _progressColor(BuildContext context) {
    final p = _progress ?? 0;
    if (p < 0.7) return context.colorAccent;
    if (p < 1.0) return context.colorComplementary;
    return context.colorError;
  }
}

// ── Budget Bar ───────────────────────────────────────────────────────────────

class _BudgetBar extends StatelessWidget {
  final double spent;
  final double amount;
  final Currency currency;
  final double progress;
  final Color progressColor;

  const _BudgetBar({
    required this.spent,
    required this.amount,
    required this.currency,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = progress >= 1.0;
    final remaining = amount - spent;
    final pct = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Money(amount: spent, currency: currency).format(),
              style: context.textBody2(),
            ),
            Text(
              '$pct%',
              style: context.textCaption(color: progressColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: context.colorBorder,
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isOver
                  ? 'Excedido: ${Money(amount: -remaining, currency: currency).format()}'
                  : 'Disponible: ${Money(amount: remaining, currency: currency).format()}',
              style: context.textCaption(
                color: isOver ? context.colorError : context.colorMuted,
              ),
            ),
            Text(
              Money(amount: amount, currency: currency).format(),
              style: context.textCaption(color: context.colorMuted),
            ),
          ],
        ),
      ],
    );
  }
}
