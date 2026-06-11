// lib/features/transactions/presentation/expense_transaction/expense_screen.dart

import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_categories_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/expense_transaction/expense_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/shared/models/category.dart';

class ExpenseScreen extends StatefulWidget {
  final Transaction? prefill;

  const ExpenseScreen({super.key, this.prefill});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
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
      final data = await service.getCategoriesWithChildren(type: CategoryType.expense);
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
      MaterialPageRoute(builder: (_) => const FormCategoriesScreen(initialType: CategoryType.expense)),
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
        title: Text("Nuevo gasto", style: AppTextStyles.h400(context)),
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
      title: "No tienes categorías de gasto",
      description: "Clasificar tus gastos te permitirá entender en qué estás gastando tu dinero",
      actionText: "Crear categoría",
      onAction: _goToCategoryForm,
    );
  }

  Widget _form() {
    return ExpenseFormScreen(categories: categories, prefill: widget.prefill);
  }
}
