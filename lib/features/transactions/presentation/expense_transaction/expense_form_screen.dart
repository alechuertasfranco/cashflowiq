import 'package:cashflowiq/core/controllers/base_transaction_form_controller.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/widgets/base_transaction_form_screen.dart';
import 'package:cashflowiq/core/widgets/form_step_amount.dart';
import 'package:cashflowiq/core/widgets/form_step_category.dart';
import 'package:cashflowiq/core/widgets/form_step_payment_source.dart';
import 'package:cashflowiq/features/profile/presentation/bank_accounts/form_account_screen.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_categories_screen.dart';
import 'package:cashflowiq/features/profile/presentation/credit_cards/form_credit_card_screen.dart';
import 'package:cashflowiq/features/transactions/data/transaction_service.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:flutter/material.dart';

class ExpenseFormScreen extends StatefulWidget {
  final List<Category> categories;
  final Transaction? prefill;
  final bool editMode;
  final VoidCallback? onCategoryAdded;

  const ExpenseFormScreen({
    super.key,
    required this.categories,
    this.prefill,
    this.editMode = false,
    this.onCategoryAdded,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final controller = BaseTransactionFormController();
  final _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      final p = widget.prefill!;
      controller.applyPrefill(
        amount: p.amount,
        description: p.description,
        date: p.date,
        categories: widget.categories,
        categoryId: p.categoryId,
      );
    }
    controller.loadSources().then((_) {
      if (widget.prefill != null && mounted) {
        controller.applyAccountPrefill(
          accounts: controller.accounts,
          creditCards: controller.creditCards,
          accountId: widget.prefill!.accountId,
          creditCardId: widget.prefill!.creditCardId,
        );
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (controller.currentStep == 0) {
      if (!controller.validateAmount()) return;
      controller.goToStep(1);
    } else if (controller.currentStep == 1) {
      if (controller.selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona una categoría")),
        );
        return;
      }
      controller.goToStep(2);
    }
  }

  Future<void> _submit() async {
    final usingCard = controller.selectedCreditCard != null;
    if (!usingCard && controller.selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una cuenta o tarjeta")),
      );
      return;
    }

    controller.setSaving(true);

    final tx = Transaction(
      id: widget.editMode ? widget.prefill!.id : '',
      type: TransactionType.expense,
      amount: double.parse(controller.amountController.text.trim()),
      date: controller.selectedDate,
      categoryId: controller.selectedCategory!.id,
      accountId: usingCard ? null : controller.selectedAccount!.id,
      creditCardId: usingCard ? controller.selectedCreditCard!.id : null,
      description: controller.descriptionController.text.trim().isNotEmpty
          ? controller.descriptionController.text.trim()
          : null,
    );

    try {
      if (widget.editMode) {
        await _transactionService.updateTransaction(widget.prefill!.id, tx);
      } else {
        await _transactionService.createTransaction(tx);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("expenseTransaction error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.editMode ? "Error al actualizar el gasto" : "Error al registrar el gasto",
          ),
        ),
      );
    } finally {
      controller.setSaving(false);
    }
  }

  void _onAmountChanged() {
    if (controller.amountError != null) controller.clearAmountError();
  }

  Future<void> _navigateToCategoryForm({Category? parent}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormCategoriesScreen(
          initialType: CategoryType.expense,
          parent: parent,
        ),
      ),
    );
    if (result == true) widget.onCategoryAdded?.call();
  }

  Future<void> _navigateToAccountForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FormAccountScreen()),
    );
    if (result == true && mounted) await controller.loadSources();
  }

  Future<void> _navigateToCreditCardForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FormCreditCardScreen()),
    );
    if (result == true && mounted) await controller.loadSources();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => BaseTransactionFormScreen(
        controller: controller,
        totalSteps: 3,
        submitLabel: widget.editMode ? "Guardar cambios" : "Guardar gasto",
        accentColor: AppColors.error,
        onNextStep: _nextStep,
        onSubmit: _submit,
        steps: [
          FormStepAmount(
            title: '¿Cuánto gastaste?',
            dateAccentColor: AppColors.error,
            descriptionHint: 'Ej: Supermercado',
            amountController: controller.amountController,
            descriptionController: controller.descriptionController,
            selectedDate: controller.selectedDate,
            amountError: controller.amountError,
            onDateTap: () => controller.pickDate(context),
            onAmountChanged: _onAmountChanged,
          ),
          FormStepCategory(
            title: '¿En qué gastaste?',
            emptyMessage: 'Aún no tienes categorías de gasto.',
            accentColor: AppColors.error,
            categories: widget.categories,
            selectedParentCategory: controller.selectedParentCategory,
            selectedCategory: controller.selectedCategory,
            viewKey: controller.categoryViewKey,
            goingForward: controller.categoryForward,
            onParentTap: controller.onParentCategoryTap,
            onChildTap: controller.onChildCategoryTap,
            onBack: controller.backFromCategoryChildren,
            onAddCategory: () => _navigateToCategoryForm(),
            onAddSubcategory: () =>
                _navigateToCategoryForm(parent: controller.selectedParentCategory),
          ),
          FormStepPaymentSource(
            title: '¿Con qué pagaste?',
            accentColor: AppColors.error,
            entities: controller.uniqueEntities,
            selectedEntity: controller.selectedEntity,
            selectedAccount: controller.selectedAccount,
            selectedCreditCard: controller.selectedCreditCard,
            viewKey: controller.entityViewKey,
            goingForward: controller.entityForward,
            accountsFor: controller.accountsFor,
            cardsFor: controller.cardsFor,
            onEntityTap: controller.onEntityTap,
            onAccountTap: controller.onAccountTap,
            onCardTap: controller.onCardTap,
            onBack: controller.backFromEntityAccounts,
            onAddAccount: _navigateToAccountForm,
            onAddCreditCard: _navigateToCreditCardForm,
            mostUsedItems: controller.mostUsedItems,
          ),
        ],
      ),
    );
  }
}
