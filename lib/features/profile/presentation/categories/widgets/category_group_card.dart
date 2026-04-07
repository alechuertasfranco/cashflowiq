// lib/features/profile/presentation/categories/widgets/category_group_card.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_categories_screen.dart';
import 'package:cashflowiq/features/profile/presentation/categories/widgets/category_card.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:flutter/material.dart';

class CategoryGroupCard extends StatefulWidget {
  final Category parent;
  final List<Category> children;
  final VoidCallback? onUpdated;

  const CategoryGroupCard({super.key, required this.parent, required this.children, this.onUpdated});

  @override
  State<CategoryGroupCard> createState() => _CategoryGroupCardState();
}

class _CategoryGroupCardState extends State<CategoryGroupCard> {
  bool expanded = false;

  final service = CategoryService();

  Future<void> _goToEditCategory() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormCategoriesScreen(category: widget.parent)),
    );

    if (updated == true) widget.onUpdated?.call();
  }

  Future<void> _goToCreateSubcategory() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormCategoriesScreen(initialType: widget.parent.type, parent: widget.parent),
      ),
    );

    if (created == true) widget.onUpdated?.call();
  }

  Future<void> _deleteCategory() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text("Eliminar categoría", style: AppTextStyles.subtitle1(context)),
        content: Text("¿Seguro que quieres eliminarla?", style: AppTextStyles.body2(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancelar", style: AppTextStyles.body2(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Eliminar", style: AppTextStyles.body2(context, color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await service.deleteCategory(widget.parent);
      widget.onUpdated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// PADRE
        CategoryCard(
          category: widget.parent,
          isExpanded: expanded,
          onToggle: () => setState(() => expanded = !expanded),
          onEdit: _goToEditCategory,
          onDelete: _deleteCategory,
        ),

        /// HIJOS
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            children: [
              ...widget.children.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: CategoryCard(category: c, onEdit: _goToEditCategory, onDelete: _deleteCategory),
                );
              }),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                child: InkWell(
                  onTap: _goToCreateSubcategory,
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text("Agregar subcategoría", style: AppTextStyles.body2(context, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
