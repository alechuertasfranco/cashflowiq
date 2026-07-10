import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/core/widgets/sub_step_switcher.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:flutter/material.dart';

class FormStepCategory extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedParentCategory;
  final Category? selectedCategory;
  final String viewKey;
  final bool goingForward;
  final void Function(Category) onParentTap;
  final void Function(Category) onChildTap;
  final VoidCallback onBack;
  final VoidCallback onAddCategory;
  final VoidCallback onAddSubcategory;

  final String title;
  final String emptyMessage;
  final Color? accentColor;

  const FormStepCategory({
    super.key,
    required this.categories,
    required this.selectedParentCategory,
    required this.selectedCategory,
    required this.viewKey,
    required this.goingForward,
    required this.onParentTap,
    required this.onChildTap,
    required this.onBack,
    required this.onAddCategory,
    required this.onAddSubcategory,
    this.title = '¿En qué categoría?',
    this.emptyMessage = 'Aún no tienes categorías.',
    this.accentColor,
  });

  bool get _showingChildren => selectedParentCategory != null && selectedParentCategory!.children.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final resolvedAccentColor = accentColor ?? context.colorPrimary;

    return SubStepSwitcher(
      viewKey: viewKey,
      goingForward: goingForward,
      child: _showingChildren
          ? _ChildCategoryView(
              parent: selectedParentCategory!,
              selectedCategory: selectedCategory,
              accentColor: resolvedAccentColor,
              onChildTap: onChildTap,
              onBack: onBack,
              onAddSubcategory: onAddSubcategory,
            )
          : _ParentCategoryView(
              categories: categories,
              selectedParentCategory: selectedParentCategory,
              selectedCategory: selectedCategory,
              title: title,
              emptyMessage: emptyMessage,
              accentColor: resolvedAccentColor,
              onParentTap: onParentTap,
              onAddCategory: onAddCategory,
            ),
    );
  }
}

// ── Parent grid ───────────────────────────────────────────────────────────────

class _ParentCategoryView extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedParentCategory;
  final Category? selectedCategory;
  final String title;
  final String emptyMessage;
  final Color accentColor;
  final void Function(Category) onParentTap;
  final VoidCallback onAddCategory;

  const _ParentCategoryView({
    required this.categories,
    required this.selectedParentCategory,
    required this.selectedCategory,
    required this.title,
    required this.emptyMessage,
    required this.accentColor,
    required this.onParentTap,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: context.heading4())),
              _AddButton(label: 'Nueva categoría', accentColor: accentColor, onTap: onAddCategory),
            ],
          ),
          const SizedBox(height: 20),
          if (categories.isEmpty)
            _EmptyHint(
              message: emptyMessage,
              buttonLabel: 'Crear categoría',
              accentColor: accentColor,
              onTap: onAddCategory,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: categories.length,
              itemBuilder: (_, i) => _ParentCategoryTile(
                category: categories[i],
                isHighlighted: categories[i].children.isNotEmpty
                    ? selectedParentCategory?.id == categories[i].id
                    : selectedCategory?.id == categories[i].id,
                onTap: () => onParentTap(categories[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _ParentCategoryTile extends StatelessWidget {
  final Category category;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _ParentCategoryTile({required this.category, required this.isHighlighted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasChildren = category.children.isNotEmpty;
    final color = parseHexColor(category.color);
    final icon = parseIcon(category.icon);
    final contentColor = isHighlighted ? getContrastColor(color) : context.colorTextPrimary;
    final iconColor = isHighlighted ? getContrastColor(color) : color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motionFast,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlighted ? color : context.colorSurface,
          borderRadius: context.radiusLgRadius,
          border: Border.all(color: isHighlighted ? color : context.colorBorder, width: isHighlighted ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: iconColor),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textCaption(color: contentColor),
                  ),
                ),
                if (hasChildren) ...[const SizedBox(width: 2), Icon(Icons.chevron_right, size: 12, color: iconColor)],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Children grid ─────────────────────────────────────────────────────────────

class _ChildCategoryView extends StatelessWidget {
  final Category parent;
  final Category? selectedCategory;
  final Color accentColor;
  final void Function(Category) onChildTap;
  final VoidCallback onBack;
  final VoidCallback onAddSubcategory;

  const _ChildCategoryView({
    required this.parent,
    required this.selectedCategory,
    required this.accentColor,
    required this.onChildTap,
    required this.onBack,
    required this.onAddSubcategory,
  });

  @override
  Widget build(BuildContext context) {
    final parentColor = parseHexColor(parent.color);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 13),
            label: const Text('Categorías'),
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(parseIcon(parent.icon), size: 20, color: parentColor),
              const SizedBox(width: 8),
              Expanded(child: Text(parent.name, style: context.heading4())),
              _AddButton(label: 'Nueva subcategoría', accentColor: accentColor, onTap: onAddSubcategory),
            ],
          ),
          const SizedBox(height: 4),
          Text('Selecciona una subcategoría', style: context.textBody2(color: context.colorTextSecondary)),
          const SizedBox(height: 20),
          if (parent.children.isEmpty)
            _EmptyHint(
              message: 'Esta categoría aún no tiene subcategorías.',
              buttonLabel: 'Crear subcategoría',
              accentColor: accentColor,
              onTap: onAddSubcategory,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: parent.children.length,
              itemBuilder: (_, i) => _LeafCategoryTile(
                category: parent.children[i],
                isSelected: selectedCategory?.id == parent.children[i].id,
                onTap: () => onChildTap(parent.children[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeafCategoryTile extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _LeafCategoryTile({required this.category, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(category.color);
    final icon = parseIcon(category.icon);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motionFast,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color : context.colorSurface,
          borderRadius: context.radiusLgRadius,
          border: Border.all(color: isSelected ? color : context.colorBorder, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: isSelected ? getContrastColor(color) : color),
            const SizedBox(height: 6),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textCaption(
                color: isSelected ? getContrastColor(color) : context.colorTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 15),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
        textStyle: context.textCaption(),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final Color accentColor;
  final VoidCallback onTap;

  const _EmptyHint({required this.message, required this.buttonLabel, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: context.textBody2(color: context.colorTextSecondary)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add, size: 16),
          label: Text(buttonLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor,
            side: BorderSide(color: accentColor),
            shape: RoundedRectangleBorder(borderRadius: context.radiusMdRadius),
          ),
        ),
      ],
    );
  }
}
