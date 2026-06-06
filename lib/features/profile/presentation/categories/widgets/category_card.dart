// lib/features/profile/presentation/categories/widgets/category_card.dart

import 'package:cashflowiq/features/profile/presentation/categories/form_budget_screen.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/money.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
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

  double get _iconSize => _isParent ? 36 : 24;
  double get _iconInnerSize => _isParent ? 22 : 14;
  double get _radius => _isParent ? 8 : 4;

  TextStyle _textStyle(BuildContext context) {
    return _isParent ? AppTextStyles.subtitle1(context) : AppTextStyles.subtitle2(context);
  }

  bool get _hasBudget => _amount != null;
  Currency? get _budgetCurrency => category.budget?.currency;

  double? get _progress {
    if (_amount == null || _amount == 0) return null;
    return (_spent ?? 0) / _amount!;
  }

  Future<void> _onSetBudget(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => FormBudgetScreen(category: category),
    );

    if (result == true) onBudgetUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [_buildIcon(), const SizedBox(width: 16), _buildContent(context), _buildActions(context)],
          ),
        ),
      ),
    );
  }

  /// ---------------- ICON ----------------
  Widget _buildIcon() {
    final categoryColor = parseHexColor(category.color);

    final bgColor = _isParent ? categoryColor : getContrastColor(categoryColor);
    final iconColor = _isParent ? getContrastColor(categoryColor) : categoryColor;

    return Container(
      width: _iconSize,
      height: _iconSize,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(_radius)),
      child: Icon(parseIcon(category.icon), color: iconColor, size: _iconInnerSize),
    );
  }

  /// ---------------- CONTENT ----------------
  Widget _buildContent(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category.name, style: _textStyle(context)),

          /// 💡 PRESUPUESTO (solo padres)
          if (_isParent && _hasBudget && _budgetCurrency != null) ...[
            const SizedBox(height: 8),

            /// monto
            Text(
              "${Money(amount: _spent ?? 0, currency: _budgetCurrency!).format()} / "
              "${Money(amount: _amount!, currency: _budgetCurrency!).format()}",
            ),

            const SizedBox(height: 6),

            /// barra progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress!.clamp(0, 1),
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(_getProgressColor()),
              ),
            ),
          ],

          /// 💡 sin presupuesto
          if (_isParent && !_hasBudget) ...[
            const SizedBox(height: 8),
            Text("Sin presupuesto", style: AppTextStyles.body2(context, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  /// ---------------- ACTIONS ----------------
  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isParent) ...[
          const SizedBox(width: 8),
          _ActionIcon(
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.primary,
            size: 20,
            onPressed: () => _onSetBudget(context),
          ),
        ],
        _ActionIcon(
          icon: Icons.edit,
          color: AppColors.complementary,
          size: _isParent ? 20 : 16,
          onPressed: () => onEdit?.call(category),
        ),
        const SizedBox(width: 8),
        _ActionIcon(
          icon: Icons.delete_outline,
          color: AppColors.error,
          size: _isParent ? 20 : 16,
          onPressed: () => onDelete?.call(category),
        ),
        if (_isParent) ...[
          const SizedBox(width: 4),
          _ActionIcon(
            icon: isExpanded ? Icons.expand_less : Icons.expand_more,
            color: AppColors.textSecondary,
            size: 28,
            onPressed: onToggle,
          ),
        ],
      ],
    );
  }

  Color _getProgressColor() {
    if (_progress == null) return AppColors.border;

    if (_progress! < 0.7) return AppColors.accent; // bien
    if (_progress! < 1) return AppColors.complementary; // alerta
    return AppColors.error; // sobre gasto
  }
}

/// ---------------- REUSABLE ACTION ICON ----------------
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onPressed;

  const _ActionIcon({required this.icon, required this.color, required this.size, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
