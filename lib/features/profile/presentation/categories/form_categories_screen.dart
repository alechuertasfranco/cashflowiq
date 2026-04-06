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
  final String? parentId;

  const FormCategoriesScreen({super.key, this.initialType, this.parentId});

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
  String? parentId;

  bool isSaving = false;

  /// Iconos disponibles (controlados)
  final List<IconData> icons = const [
    Icons.attach_money,
    Icons.work,
    Icons.trending_up,
    Icons.business,
    Icons.card_giftcard,
    Icons.savings,
  ];

  @override
  void initState() {
    super.initState();

    type = widget.initialType;
    parentId = widget.parentId;
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (type == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona el tipo")));
      return;
    }

    setState(() => isSaving = true);

    try {
      await service.createCategory(
        Category(
          id: '',
          name: _nameController.text,
          type: type!,
          icon: selectedIcon,
          color: selectedColor?.toARGB32().toRadixString(16).substring(2),
          parentId: parentId,
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Nueva categoría", style: AppTextStyles.h400(context)),
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
                /// TYPE
                Text("Tipo", style: AppTextStyles.subtitle2(context)),
                const SizedBox(height: 8),

                DropdownButtonFormField<CategoryType>(
                  initialValue: type,
                  style: AppTextStyles.subtitle2(context),
                  decoration: inputDecoration(context, "Selecciona tipo"),
                  items: CategoryType.values.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()));
                  }).toList(),
                  onChanged: (v) => setState(() => type = v),
                ),

                const SizedBox(height: 16),

                /// NAME
                Text("Nombre", style: AppTextStyles.subtitle2(context)),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _nameController,
                  decoration: inputDecoration(context, "Ej: Salario"),
                  validator: (v) => v == null || v.isEmpty ? "Requerido" : null,
                ),

                const SizedBox(height: 16),

                /// ICON SELECTOR
                Text("Icono", style: AppTextStyles.subtitle2(context)),
                const SizedBox(height: 8),

                IconSelector(onSelected: (icon) => selectedIcon = icon?.codePoint.toString()),

                const SizedBox(height: 16),

                /// COLOR SELECTOR (COLAPSABLE 🔥)
                Text("Color", style: AppTextStyles.subtitle2(context)),
                const SizedBox(height: 8),

                ColorSelector(onSelected: (color) => selectedColor = color),

                const Spacer(),

                /// SUBMIT
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: isSaving ? null : submit,
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("Crear categoría", style: AppTextStyles.subtitle2(context, color: Colors.white)),
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
