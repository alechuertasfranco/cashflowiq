// lib/features/profile/presentation/categories/categories_screen.dar

import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/features/profile/presentation/categories/widgets/category_group_card.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_categories_screen.dart';
import 'package:cashflowiq/shared/models/category.dart';

class CategoriesScreen extends StatefulWidget {
  final CategoryType type;

  const CategoriesScreen({super.key, required this.type});

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
    final data = await service.getCategoriesWithChildren(type: widget.type);

    setState(() {
      categories = data;
      isLoading = false;
    });
  }

  void _goToCreateCategory() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormCategoriesScreen(initialType: widget.type)),
    );

    if (created == true) load();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == CategoryType.income;
    final roots = categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isIncome ? "Categorías de ingresos" : "Categorías de gastos", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.complementary,
        onPressed: _goToCreateCategory,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : roots.isEmpty
            ? InsightEmptyState(
                icon: Icons.category_outlined,
                title: "No tienes categorías",
                description: isIncome
                    ? "Agrega categorías para entender de dónde viene tu dinero"
                    : "Agrega categorías para entender en qué gastas",
                actionText: "Crear categoría",
                onAction: _goToCreateCategory,
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: roots.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final parent = roots[i];
                  final children = parent.children;

                  return CategoryGroupCard(parent: parent, children: children, onUpdated: load);
                },
              ),
      ),
    );
  }
}
