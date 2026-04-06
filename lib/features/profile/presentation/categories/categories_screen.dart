// lib\features\profile\presentation\categories\categories_screen.dart

import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_categories_screen.dart';
import 'package:cashflowiq/shared/models/category.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final service = CategoryService();

  List<Category> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await service.getCategories();
    setState(() {
      categories = data;
      isLoading = false;
    });
  }

  void _goToCreateCategory() async {
    final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormCategoriesScreen()));
    if (created == true) load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Categorías", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.complementary,
        onPressed: _goToCreateCategory,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
          ? Expanded(
              child: InsightEmptyState(
                icon: Icons.category_outlined,
                title: "No tienes categorías",
                description: "Agrega una categoría para empezar a entender tu dinero",
                actionText: "Crear categoría",
                onAction: _goToCreateCategory,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final c = categories[i];

                return Card(
                  color: AppColors.surface,
                  child: ListTile(
                    title: Text(c.name, style: AppTextStyles.body1(context)),
                    subtitle: Text(c.type.name.toUpperCase()),
                  ),
                );
              },
            ),
    );
  }
}
