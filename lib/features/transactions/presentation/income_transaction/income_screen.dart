// lib\features\transactions\presentation\income_transaction\income_screen.dart

import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_categories_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/income_transaction/income_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/shared/models/category.dart';

class IncomeScreen extends StatefulWidget {
  final Transaction? prefill;

  const IncomeScreen({super.key, this.prefill});

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Nuevo ingreso", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
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
    return IncomeFormScreen(categories: categories, prefill: widget.prefill);
  }
}
