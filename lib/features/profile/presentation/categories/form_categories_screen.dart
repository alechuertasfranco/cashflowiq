// lib/features/profile/presentation/categories/form_categories_screen.dart

import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:cashflowiq/core/widgets/icon_selector.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/color_selector.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/shared/models/category.dart';

class FormCategoriesScreen extends StatefulWidget {
  final CategoryType? initialType;
  final Category? parent;
  final Category? category;

  const FormCategoriesScreen({super.key, this.initialType, this.parent, this.category});

  @override
  State<FormCategoriesScreen> createState() => _FormCategoriesScreenState();
}

class _FormCategoriesScreenState extends State<FormCategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final service = CategoryService();

  CategoryType? type;
  String? selectedIcon;
  Color? selectedColor;
  Category? parent;

  bool isSaving = false;

  bool get isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();

    parent = widget.parent;
    if (isEdit) {
      final c = widget.category!;
      _nameController.text = c.name;
      type = c.type;
      selectedIcon = c.icon;
      selectedColor = parseHexColor(c.color);
    } else {
      type = widget.initialType;
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (type == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona el tipo")));
      return;
    }

    setState(() => isSaving = true);

    try {
      final category = Category(
        id: isEdit ? widget.category!.id : '',
        name: _nameController.text,
        type: type!,
        icon: selectedIcon,
        color: selectedColor?.toARGB32().toRadixString(16).substring(2),
        parentId: parent?.id,
      );

      if (isEdit) {
        await service.updateCategory(category);
      } else {
        await service.createCategory(category);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isEdit ? "Editar categoría" : "Nueva categoría";
    final buttonText = isEdit ? "Guardar cambios" : "Crear categoría";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (parent?.id != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(parseIcon(parent?.icon), size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            "Subcategoría de ${parent?.name ?? 'categoría padre'}",
                            style: AppTextStyles.body2(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],

                /// TYPE
                Text("Tipo", style: AppTextStyles.subtitle2(context)),
                const SizedBox(height: 8),

                DropdownButtonFormField<CategoryType>(
                  initialValue: type,
                  style: AppTextStyles.body1(context),
                  decoration: inputDecoration(context, "Selecciona tipo"),
                  items: CategoryType.values.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e.toLabel()));
                  }).toList(),
                  onChanged: (v) => setState(() => type = v),
                ),

                const SizedBox(height: 16),

                /// NAME
                Text("Nombre", style: AppTextStyles.subtitle2(context)),
                const SizedBox(height: 8),

                TextFormField(
                  style: AppTextStyles.body1(context),
                  controller: _nameController,
                  decoration: inputDecoration(context, "Ej: Salario"),
                  validator: (v) => v == null || v.isEmpty ? "Requerido" : null,
                ),

                const SizedBox(height: 16),

                /// ICON
                Text("Icono", style: AppTextStyles.subtitle2(context)),
                const SizedBox(height: 8),

                IconSelector(
                  initialIcon: selectedIcon != null ? parseIcon(selectedIcon) : null,
                  onSelected: (icon) => selectedIcon = icon?.codePoint.toString(),
                ),

                const SizedBox(height: 16),

                /// COLOR
                Text("Color", style: AppTextStyles.subtitle2(context)),
                const SizedBox(height: 8),

                ColorSelector(initialColor: selectedColor, onSelected: (color) => selectedColor = color),

                const Spacer(),

                /// SUBMIT
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: isSaving ? null : submit,
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(buttonText, style: AppTextStyles.subtitle2(context, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
