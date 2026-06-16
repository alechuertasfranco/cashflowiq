import 'package:cashflowiq/core/services/notification_service.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/base_transaction_form_screen.dart';
import 'package:cashflowiq/core/widgets/currency_dropdown.dart';
import 'package:cashflowiq/core/widgets/form_step_category.dart';
import 'package:cashflowiq/core/widgets/form_step_payment_source.dart';
import 'package:cashflowiq/features/transactions/data/recurring_transaction_service.dart';
import 'package:cashflowiq/features/transactions/presentation/recurring/recurring_form_controller.dart';
import 'package:cashflowiq/features/transactions/presentation/recurring/widgets/recurring_step_details.dart';
import 'package:cashflowiq/features/transactions/presentation/recurring/widgets/recurring_step_schedule.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/recurring_transaction.dart';
import 'package:flutter/material.dart';

class RecurringTransactionFormScreen extends StatefulWidget {
  final RecurringTransaction? existing;

  const RecurringTransactionFormScreen({super.key, this.existing});

  @override
  State<RecurringTransactionFormScreen> createState() =>
      _RecurringTransactionFormScreenState();
}

class _RecurringTransactionFormScreenState
    extends State<RecurringTransactionFormScreen> {
  final controller = RecurringFormController();
  final _recurringService = RecurringTransactionService();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) controller.applyRecurringPrefill(widget.existing!);
    controller.loadSources().then((_) {
      if (_isEditing && mounted) {
        final e = widget.existing!;
        controller.applyRecurringCategoryPrefill(e.categoryId?.toString());
        controller.applyRecurringAccountPrefill(
          accountId: e.accountId?.toString(),
          creditCardId: e.creditCardId?.toString(),
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
      if (!controller.validateStep0()) return;
      controller.goToStep(1);
    } else if (controller.currentStep < 3) {
      controller.goToStep(controller.currentStep + 1);
    }
  }

  Future<void> _submit() async {
    final usingCard =
        controller.type == 'EXPENSE' && controller.paymentSourceStr == 'card';

    if (usingCard && controller.selectedCreditCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una tarjeta de crédito")),
      );
      return;
    }

    controller.setSaving(true);

    if (_isEditing) {
      NotificationService.instance
          .cancelRecurringNotification(widget.existing!.id);
    }

    final accountId = usingCard || controller.selectedAccount == null
        ? null
        : int.tryParse(controller.selectedAccount!.id);
    final creditCardId = usingCard && controller.selectedCreditCard != null
        ? int.tryParse(controller.selectedCreditCard!.id)
        : null;
    final currencyId =
        (accountId == null && creditCardId == null) ? controller.selectedCurrency?.id : null;

    final payload = <String, dynamic>{
      'name': controller.nameController.text.trim(),
      'amount': controller.isFixedAmount
          ? double.parse(controller.amountController.text.trim())
          : null,
      'type': controller.type,
      'frequency': controller.frequency.toApi(),
      'next_execution_date': controller.nextExecutionDate.toIso8601String(),
      if (controller.endDate != null)
        'end_date': controller.endDate!.toIso8601String().split('T').first,
      if (controller.selectedCategory != null)
        'category_id': int.tryParse(controller.selectedCategory!.id),
      'account_id': accountId,
      'credit_card_id': creditCardId,
      'currency_id': currencyId,
      'notification_days_before': controller.notificationDaysBefore,
    };

    try {
      final RecurringTransaction result;
      if (_isEditing) {
        result = await _recurringService.update(widget.existing!.id, payload);
      } else {
        result = await _recurringService.create(payload);
      }
      await NotificationService.instance.scheduleRecurringNotification(result);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("recurring form submit error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar la regla recurrente")),
      );
    } finally {
      controller.setSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? "Editar recurrente" : "Nueva regla recurrente",
          style: AppTextStyles.h400(context),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => BaseTransactionFormScreen(
            controller: controller,
            totalSteps: 4,
            submitLabel: _isEditing ? "Guardar cambios" : "Crear regla",
            accentColor: AppColors.primary,
            onNextStep: _nextStep,
            onSubmit: _submit,
            steps: [
              RecurringStepDetails(
                type: controller.type,
                isFixedAmount: controller.isFixedAmount,
                nameController: controller.nameController,
                amountController: controller.amountController,
                nameError: controller.nameError,
                amountError: controller.amountError,
                onTypeChanged: controller.onTypeChanged,
                onAmountTypeChanged: controller.onAmountTypeChanged,
                onNameChanged: controller.clearNameError,
                onAmountChanged: controller.clearAmountError,
              ),
              FormStepCategory(
                categories: controller.filteredCategories,
                selectedParentCategory: controller.selectedParentCategory,
                selectedCategory: controller.selectedCategory,
                viewKey: controller.categoryViewKey,
                goingForward: controller.categoryForward,
                onParentTap: controller.onParentCategoryTap,
                onChildTap: controller.onChildCategoryTap,
                onBack: controller.backFromCategoryChildren,
                onAddCategory: () => controller.navigateToCategoryForm(
                  context,
                  initialType: controller.type == 'INCOME'
                      ? CategoryType.income
                      : CategoryType.expense,
                ),
                onAddSubcategory: () => controller.navigateToCategoryForm(
                  context,
                  initialType: controller.type == 'INCOME'
                      ? CategoryType.income
                      : CategoryType.expense,
                  parent: controller.selectedParentCategory,
                ),
              ),
              FormStepPaymentSource(
                title: controller.type == 'INCOME' ? '¿A qué cuenta?' : '¿Con qué pagas?',
                entities: controller.type == 'INCOME' || controller.paymentSourceStr == 'account'
                    ? controller.accountOnlyEntities
                    : controller.cardOnlyEntities,
                selectedEntity: controller.selectedEntity,
                selectedAccount: controller.selectedAccount,
                selectedCreditCard: controller.selectedCreditCard,
                viewKey: controller.entityViewKey,
                goingForward: controller.entityForward,
                accountsFor: controller.accountsFor,
                cardsFor: controller.type == 'EXPENSE' ? controller.cardsFor : null,
                onEntityTap: controller.onEntityTap,
                onAccountTap: controller.onAccountTap,
                onCardTap: controller.type == 'EXPENSE' ? controller.onCardTap : null,
                onBack: controller.backFromEntityAccounts,
                onAddAccount: () => controller.navigateToAccountForm(
                  context,
                  onReload: controller.loadSources,
                ),
                onAddCreditCard: controller.type == 'EXPENSE'
                    ? () => controller.navigateToCreditCardForm(
                          context,
                          onReload: controller.loadSources,
                        )
                    : null,
                sourceType: controller.type == 'EXPENSE' ? controller.paymentSourceStr : null,
                onSourceTypeChanged:
                    controller.type == 'EXPENSE' ? controller.onPaymentSourceChanged : null,
                bottomSlot: _CurrencySection(
                  selectedAccount: controller.selectedAccount,
                  selectedCreditCard: controller.selectedCreditCard,
                  currencies: controller.currencies,
                  selectedCurrency: controller.selectedCurrency,
                  onCurrencyChanged: controller.onCurrencyChanged,
                ),
              ),
              RecurringStepSchedule(
                frequency: controller.frequency,
                notificationDaysBefore: controller.notificationDaysBefore,
                nextExecutionDate: controller.nextExecutionDate,
                endDate: controller.endDate,
                isFixedAmount: controller.isFixedAmount,
                onFrequencyChanged: controller.onFrequencyChanged,
                onNotificationChanged: controller.onNotificationChanged,
                onPickNextDate: () => controller.pickNextExecutionDate(context),
                onPickEndDate: () => controller.pickEndDate(context),
                onClearEndDate: controller.clearEndDate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencySection extends StatelessWidget {
  final BankAccount? selectedAccount;
  final CreditCard? selectedCreditCard;
  final List<Currency> currencies;
  final Currency? selectedCurrency;
  final void Function(Currency?) onCurrencyChanged;

  const _CurrencySection({
    required this.selectedAccount,
    required this.selectedCreditCard,
    required this.currencies,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Currency? derived = selectedCreditCard != null
        ? selectedCreditCard!.currency
        : selectedAccount?.currency;
    final String? fromLabel = selectedCreditCard != null
        ? "(desde la tarjeta)"
        : selectedAccount != null
            ? "(desde la cuenta)"
            : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Moneda",
              style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          if (derived != null && fromLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text("${derived.flag} ${derived.code}",
                      style: AppTextStyles.body1(context)),
                  const SizedBox(width: 8),
                  Text(fromLabel,
                      style: AppTextStyles.caption(context, color: AppColors.muted)),
                ],
              ),
            )
          else
            CurrencyDropdown(
              currencies: currencies,
              value: selectedCurrency,
              onChanged: onCurrencyChanged,
            ),
        ],
      ),
    );
  }
}
