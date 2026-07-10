// lib\features\transactions\presentation\income_transaction\income_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/skeleton_loader.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_categories_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/income_transaction/income_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/shared/models/category.dart';

class IncomeScreen extends StatefulWidget {
  final Transaction? prefill;
  final bool editMode;

  const IncomeScreen({super.key, this.prefill, this.editMode = false});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final service = CategoryService();

  bool isLoading = true;
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await service.getCategoriesWithChildren(type: CategoryType.income);
      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _goToCategoryForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormCategoriesScreen(initialType: CategoryType.income)),
    );

    if (result == true) {
      setState(() => isLoading = true);
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppHeaderBar(title: widget.editMode ? "Editar ingreso" : "Nuevo ingreso"),
      body: SafeArea(
        child: isLoading
            ? const SkeletonListLoader()
            : categories.isEmpty
            ? _emptyState()
            : _form(),
      ),
    );
  }

  Widget _emptyState() {
    return InsightEmptyState(
      icon: Icons.category,
      title: "No tienes categorías de ingreso",
      description: "Clasificar tus ingresos te permitirá entender de dónde viene tu dinero",
      actionText: "Crear categoría",
      onAction: _goToCategoryForm,
    );
  }

  Widget _form() {
    return IncomeFormScreen(
      categories: categories,
      prefill: widget.prefill,
      editMode: widget.editMode,
      onCategoryAdded: () {
        setState(() => isLoading = true);
        load();
      },
    );
  }
}
