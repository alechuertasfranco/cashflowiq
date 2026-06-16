import 'package:cashflowiq/core/controllers/base_transaction_form_controller.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/widgets/base_transaction_form_screen.dart';
import 'package:cashflowiq/core/widgets/form_step_amount.dart';
import 'package:cashflowiq/core/widgets/form_step_category.dart';
import 'package:cashflowiq/core/widgets/form_step_payment_source.dart';
import 'package:cashflowiq/features/transactions/data/transaction_service.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:flutter/material.dart';

class IncomeFormScreen extends StatefulWidget {
  final List<Category> categories;
  final Transaction? prefill;
  final bool editMode;
  final VoidCallback? onCategoryAdded;

  const IncomeFormScreen({
    super.key,
    required this.categories,
    this.prefill,
    this.editMode = false,
    this.onCategoryAdded,
  });

  @override
  State<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends State<IncomeFormScreen> {
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
    controller.loadAccountsOnly().then((_) {
      if (widget.prefill != null && mounted) {
        controller.applyAccountPrefill(
          accounts: controller.accounts,
          creditCards: const [],
          accountId: widget.prefill!.accountId,
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
    if (controller.selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una cuenta")),
      );
      return;
    }

    controller.setSaving(true);

    final tx = Transaction(
      id: widget.editMode ? widget.prefill!.id : '',
      type: TransactionType.income,
      amount: double.parse(controller.amountController.text.trim()),
      date: controller.selectedDate,
      categoryId: controller.selectedCategory!.id,
      accountId: controller.selectedAccount!.id,
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
      debugPrint("incomeTransaction error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editMode
              ? "Error al actualizar el ingreso"
              : "Error al registrar el ingreso"),
        ),
      );
    } finally {
      controller.setSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => BaseTransactionFormScreen(
        controller: controller,
        totalSteps: 3,
        submitLabel: widget.editMode ? "Guardar cambios" : "Guardar ingreso",
        accentColor: AppColors.primary,
        onNextStep: _nextStep,
        onSubmit: _submit,
        steps: [
          FormStepAmount(
            title: '¿Cuánto recibiste?',
            dateAccentColor: AppColors.primary,
            descriptionHint: 'Ej: Pago de cliente',
            amountController: controller.amountController,
            descriptionController: controller.descriptionController,
            selectedDate: controller.selectedDate,
            amountError: controller.amountError,
            onDateTap: () => controller.pickDate(context),
            onAmountChanged: controller.clearAmountError,
          ),
          FormStepCategory(
            title: '¿De qué fue?',
            emptyMessage: 'Aún no tienes categorías de ingreso.',
            categories: widget.categories,
            selectedParentCategory: controller.selectedParentCategory,
            selectedCategory: controller.selectedCategory,
            viewKey: controller.categoryViewKey,
            goingForward: controller.categoryForward,
            onParentTap: controller.onParentCategoryTap,
            onChildTap: controller.onChildCategoryTap,
            onBack: controller.backFromCategoryChildren,
            onAddCategory: () => controller.navigateToCategoryForm(
              context,
              initialType: CategoryType.income,
              onCategoryAdded: widget.onCategoryAdded,
            ),
            onAddSubcategory: () => controller.navigateToCategoryForm(
              context,
              initialType: CategoryType.income,
              parent: controller.selectedParentCategory,
              onCategoryAdded: widget.onCategoryAdded,
            ),
          ),
          FormStepPaymentSource(
            title: '¿A qué cuenta?',
            entities: controller.uniqueEntities,
            selectedEntity: controller.selectedEntity,
            selectedAccount: controller.selectedAccount,
            viewKey: controller.entityViewKey,
            goingForward: controller.entityForward,
            accountsFor: controller.accountsFor,
            onEntityTap: controller.onEntityTap,
            onAccountTap: controller.onAccountTap,
            onBack: controller.backFromEntityAccounts,
            onAddAccount: () => controller.navigateToAccountForm(
              context,
              onReload: controller.loadAccountsOnly,
            ),
          ),
        ],
      ),
    );
  }
}
