// lib/features/profile/presentation/categories/widgets/category_group_card.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_budget_screen.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_categories_screen.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/money.dart';
import 'package:flutter/material.dart';

class CategoryGroupCard extends StatefulWidget {
  final Category parent;
  final List<Category> children;
  final VoidCallback? onUpdated;

  const CategoryGroupCard({
    super.key,
    required this.parent,
    required this.children,
    this.onUpdated,
  });

  @override
  State<CategoryGroupCard> createState() => _CategoryGroupCardState();
}

class _CategoryGroupCardState extends State<CategoryGroupCard> {
  bool _expanded = false;
  final _service = CategoryService();

  // ── Computed budget helpers ─────────────────────────────────────────────

  double? get _amount => widget.parent.budget?.amount;
  double? get _spent => widget.parent.budget?.spent;
  bool get _hasBudget => _amount != null && _amount! > 0;
  Currency? get _budgetCurrency => widget.parent.budget?.currency;

  double? get _progress {
    if (_amount == null || _amount == 0) return null;
    return (_spent ?? 0) / _amount!;
  }

  Color get _progressColor {
    final p = _progress ?? 0;
    if (p < 0.7) return AppColors.accent;
    if (p < 1.0) return AppColors.complementary;
    return AppColors.error;
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  Future<void> _goToCreateSubcategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormCategoriesScreen(
          initialType: widget.parent.type,
          parent: widget.parent,
        ),
      ),
    );
    if (result == true) widget.onUpdated?.call();
  }

  Future<void> _goToEditCategory(Category cat) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormCategoriesScreen(
          category: cat,
          parent: (cat.parentId == widget.parent.id) ? widget.parent : null,
        ),
      ),
    );
    if (result == true) widget.onUpdated?.call();
  }

  Future<void> _deleteCategory(Category cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Eliminar categoría', style: AppTextStyles.subtitle1(context)),
        content: Text('¿Seguro que quieres eliminarla?', style: AppTextStyles.body2(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: AppTextStyles.body2(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: AppTextStyles.body2(context, color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteCategory(cat.id);
      widget.onUpdated?.call();
    }
  }

  Future<void> _onSetBudget() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => FormBudgetScreen(category: widget.parent),
    );
    if (result == true) widget.onUpdated?.call();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildParentRow(context),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded ? _buildChildrenSection(context) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildParentRow(BuildContext context) {
    final cat = widget.parent;
    final catColor = parseHexColor(cat.color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CircleIcon(color: catColor, icon: parseIcon(cat.icon), size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cat.name,
                      style: AppTextStyles.h600(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (_hasBudget && _budgetCurrency != null)
                      _BudgetSection(
                        spent: _spent ?? 0,
                        amount: _amount!,
                        currency: _budgetCurrency!,
                        progress: (_progress ?? 0).clamp(0.0, 1.0),
                        progressColor: _progressColor,
                      )
                    else
                      Text(
                        widget.children.isEmpty
                            ? 'Sin presupuesto'
                            : '${widget.children.length} subcategoría${widget.children.length > 1 ? "s" : ""}',
                        style: AppTextStyles.caption(context, color: AppColors.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _ParentMenu(
                context: context,
                onEdit: () => _goToEditCategory(cat),
                onBudget: _onSetBudget,
                onDelete: () => _deleteCategory(cat),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        ...widget.children.map(
          (child) => _ChildRow(
            child: child,
            onEdit: () => _goToEditCategory(child),
            onDelete: () => _deleteCategory(child),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _goToCreateSubcategory,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: const Icon(Icons.add, size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Agregar subcategoría',
                    style: AppTextStyles.body2(context, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Parent popup menu ──────────────────────────────────────────────────────

class _ParentMenu extends StatelessWidget {
  final BuildContext context;
  final VoidCallback onEdit;
  final VoidCallback onBudget;
  final VoidCallback onDelete;

  const _ParentMenu({
    required this.context,
    required this.onEdit,
    required this.onBudget,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext _) {
    return PopupMenuButton<String>(
      iconSize: 20,
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, color: AppColors.muted, size: 20),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 16, color: AppColors.complementary),
              const SizedBox(width: 10),
              Text('Editar', style: AppTextStyles.body2(context)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'budget',
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 10),
              Text('Presupuesto', style: AppTextStyles.body2(context)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
              const SizedBox(width: 10),
              Text('Eliminar', style: AppTextStyles.body2(context, color: AppColors.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'budget') onBudget();
        if (value == 'delete') onDelete();
      },
    );
  }
}

// ── Child row ─────────────────────────────────────────────────────────────

class _ChildRow extends StatelessWidget {
  final Category child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChildRow({
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = parseHexColor(child.color);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, thickness: 1, indent: 16, color: AppColors.border),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  _CircleIcon(
                    color: catColor.withAlpha(45),
                    icon: parseIcon(child.icon),
                    iconColor: catColor,
                    size: 34,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      child.name,
                      style: AppTextStyles.body1(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, color: AppColors.muted, size: 18),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 16, color: AppColors.complementary),
                            const SizedBox(width: 10),
                            Text('Editar', style: AppTextStyles.body2(context)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                            const SizedBox(width: 10),
                            Text('Eliminar', style: AppTextStyles.body2(context, color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Circle icon ───────────────────────────────────────────────────────────

class _CircleIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;
  final Color? iconColor;

  const _CircleIcon({
    required this.color,
    required this.icon,
    required this.size,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(
        icon,
        color: iconColor ?? getContrastColor(color),
        size: size * 0.48,
      ),
    );
  }
}

// ── Budget section ────────────────────────────────────────────────────────

class _BudgetSection extends StatelessWidget {
  final double spent;
  final double amount;
  final Currency currency;
  final double progress;
  final Color progressColor;

  const _BudgetSection({
    required this.spent,
    required this.amount,
    required this.currency,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                '${Money(amount: spent, currency: currency).format()} de ${Money(amount: amount, currency: currency).format()}',
                style: AppTextStyles.caption(context, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: progressColor.withAlpha(22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pct%',
                style: AppTextStyles.caption(context, color: progressColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
