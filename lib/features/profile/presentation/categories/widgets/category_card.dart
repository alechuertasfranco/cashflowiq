// lib/features/profile/presentation/categories/widgets/category_card.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/shared/models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  final bool isExpanded;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    this.isExpanded = false,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  bool get _isParent => category.parentId == null;

  bool get _isIncome => category.type == CategoryType.income;

  Color get _accentColor {
    if (!_isParent) return AppColors.textSecondary;
    return _isIncome ? AppColors.accent : AppColors.error;
  }

  double get _iconSize => _isParent ? 36 : 24;
  double get _iconInnerSize => _isParent ? 22 : 14;
  double get _radius => _isParent ? 8 : 4;

  TextStyle _textStyle(BuildContext context) {
    return _isParent ? AppTextStyles.subtitle1(context) : AppTextStyles.subtitle2(context);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isParent ? onToggle : onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [_buildIcon(), const SizedBox(width: 16), _buildContent(context), _buildActions()]),
        ),
      ),
    );
  }

  /// ---------------- ICON ----------------
  Widget _buildIcon() {
    return Container(
      width: _iconSize,
      height: _iconSize,
      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(_radius)),
      child: Icon(parseIcon(category.icon), color: _accentColor, size: _iconInnerSize),
    );
  }

  /// ---------------- CONTENT ----------------
  Widget _buildContent(BuildContext context) {
    return Expanded(child: Text(category.name, style: _textStyle(context)));
  }

  /// ---------------- ACTIONS ----------------
  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(icon: Icons.edit, color: AppColors.complementary, size: _isParent ? 20 : 16, onPressed: onEdit),
        const SizedBox(width: 8),
        _ActionIcon(icon: Icons.delete_outline, color: AppColors.error, size: _isParent ? 20 : 16, onPressed: onDelete),
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
