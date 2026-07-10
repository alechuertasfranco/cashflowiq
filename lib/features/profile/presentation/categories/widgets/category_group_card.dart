// lib/features/profile/presentation/categories/widgets/category_group_card.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/core/widgets/app_bottom_sheet.dart';
import 'package:cashflowiq/core/widgets/app_dialog.dart';
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

  Color _progressColor(BuildContext context) {
    final p = _progress ?? 0;
    if (p < 0.7) return context.colorAccent;
    if (p < 1.0) return context.colorComplementary;
    return context.colorError;
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
    final confirm = await showAppConfirmDialog(
      context,
      title: 'Eliminar categoría',
      message: '¿Seguro que quieres eliminarla?',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );
    if (confirm) {
      await _service.deleteCategory(cat.id);
      widget.onUpdated?.call();
    }
  }

  Future<void> _onSetBudget() async {
    final result = await showAppBottomSheet<bool>(
      context,
      builder: (_) => FormBudgetScreen(category: widget.parent),
    );
    if (result == true) widget.onUpdated?.call();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: context.radiusLgRadius,
        boxShadow: context.shadowCard,
        border: context.isDark ? Border.all(color: context.colorBorder) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildParentRow(context),
          AnimatedSize(
            duration: context.motionBase,
            curve: context.motionStandard,
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
                      style: context.heading6(),
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
                        progressColor: _progressColor(context),
                      )
                    else
                      Text(
                        widget.children.isEmpty
                            ? 'Sin presupuesto'
                            : '${widget.children.length} subcategoría${widget.children.length > 1 ? "s" : ""}',
                        style: context.textCaption(color: context.colorMuted),
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
                duration: context.motionFast,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: context.colorMuted,
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
        Divider(height: 1, thickness: 1, color: context.colorDivider),
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
                      border: Border.all(color: context.colorPrimary, width: 1.5),
                    ),
                    child: Icon(Icons.add, size: 14, color: context.colorPrimary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Agregar subcategoría',
                    style: context.textBody2(color: context.colorPrimary),
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
      icon: Icon(Icons.more_vert, color: context.colorMuted, size: 20),
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
          value: 'budget',
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 16, color: context.colorPrimary),
              const SizedBox(width: 10),
              Text('Presupuesto', style: context.textBody2()),
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
        Divider(height: 1, thickness: 1, indent: 16, color: context.colorDivider),
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
                      style: context.textBody1(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_vert, color: context.colorMuted, size: 18),
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
            backgroundColor: context.colorBorder,
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                '${Money(amount: spent, currency: currency).format()} de ${Money(amount: amount, currency: currency).format()}',
                style: context.textCaption(color: context.colorTextSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: progressColor.withAlpha(22),
                borderRadius: context.radiusPillRadius,
              ),
              child: Text(
                '$pct%',
                style: context.textCaption(color: progressColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
