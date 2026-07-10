// lib/features/profile/presentation/categories/categories_screen.dar

import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/skeleton_loader.dart';
import 'package:cashflowiq/core/widgets/staggered_fade_in.dart';
import 'package:cashflowiq/features/profile/presentation/categories/widgets/category_group_card.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
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
      backgroundColor: context.colorBackground,
      appBar: AppHeaderBar(title: isIncome ? "Categorías de ingresos" : "Categorías de gastos"),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colorComplementary,
        onPressed: _goToCreateCategory,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: isLoading
            ? const SkeletonListLoader()
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

                  return StaggeredFadeIn(
                    index: i,
                    child: CategoryGroupCard(parent: parent, children: children, onUpdated: load),
                  );
                },
              ),
      ),
    );
  }
}
