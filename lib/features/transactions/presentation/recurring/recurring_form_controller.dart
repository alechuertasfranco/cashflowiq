import 'package:cashflowiq/core/controllers/base_transaction_form_controller.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/recurring_transaction.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';
import 'package:flutter/material.dart';

/// Extends [BaseTransactionFormController] with recurring-transaction-specific state.
///
/// Step layout:
///   0 — RecurringStepDetails  (type, name, fixed/variable, amount)
///   1 — RecurringStepCategory (filtered by type)
///   2 — RecurringStepAccount  (payment source + optional currency)
///   3 — RecurringStepSchedule (frequency, dates, notification)
class RecurringFormController extends BaseTransactionFormController {
  final _categoryService = CategoryService();
  final _currencyService = CurrencyService();

  // ── Step 1 fields ────────────────────────────────────────────────────────────
  final TextEditingController nameController = TextEditingController();
  String type = 'INCOME'; // 'INCOME' | 'EXPENSE'
  bool isFixedAmount = true;
  String? nameError;

  // ── Step 2 fields ────────────────────────────────────────────────────────────
  List<Category> allCategories = [];

  List<Category> get filteredCategories {
    final wanted = type == 'INCOME' ? CategoryType.income : CategoryType.expense;
    return allCategories.where((c) => c.type == wanted).toList();
  }

  // ── Step 3 fields ────────────────────────────────────────────────────────────
  String paymentSourceStr = 'account'; // 'account' | 'card'
  List<Currency> currencies = [];
  Currency? selectedCurrency;

  // ── Step 4 fields ────────────────────────────────────────────────────────────
  RecurringFrequency frequency = RecurringFrequency.monthly;
  int? notificationDaysBefore;
  DateTime nextExecutionDate = DateTime.now();
  DateTime? endDate;

  // ── Derived getters ──────────────────────────────────────────────────────────

  List<BankEntity> get accountOnlyEntities {
    final seen = <String>{};
    final result = <BankEntity>[];
    for (final a in accounts) {
      if (seen.add(a.bankEntity.id)) result.add(a.bankEntity);
    }
    return result;
  }

  List<BankEntity> get cardOnlyEntities {
    final seen = <String>{};
    final result = <BankEntity>[];
    for (final c in creditCards) {
      if (seen.add(c.bankEntity.id)) result.add(c.bankEntity);
    }
    return result;
  }

  // ── Data loading override ────────────────────────────────────────────────────

  @override
  Future<void> loadSources() async {
    try {
      final results = await Future.wait([
        accountService.getAccounts(),
        creditCardService.getCreditCards(),
        _categoryService.getCategoriesWithChildren(),
        _currencyService.getCurrencies(),
      ]);
      accounts = results[0] as List<BankAccount>;
      creditCards = results[1] as List<CreditCard>;
      allCategories = results[2] as List<Category>;
      currencies = results[3] as List<Currency>;
      isLoadingSources = false;
      notifyListeners();
    } catch (_) {
      isLoadingSources = false;
      notifyListeners();
    }
  }

  // ── Step 0: type + name + amount ─────────────────────────────────────────────

  void onTypeChanged(String newType) {
    type = newType;
    selectedParentCategory = null;
    selectedCategory = null;
    categoryViewKey = 'parents';
    if (newType == 'INCOME') {
      paymentSourceStr = 'account';
      selectedCreditCard = null;
    }
    notifyListeners();
  }

  void onAmountTypeChanged(bool fixed) {
    isFixedAmount = fixed;
    if (!fixed) amountController.clear();
    notifyListeners();
  }

  void clearNameError() {
    if (nameError != null) {
      nameError = null;
      notifyListeners();
    }
  }

  bool validateStep0() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      nameError = "Ingresa un nombre";
      notifyListeners();
      return false;
    }
    nameError = null;

    if (isFixedAmount) {
      final text = amountController.text.trim();
      if (text.isEmpty) {
        amountError = "Ingresa un monto";
        notifyListeners();
        return false;
      }
      final parsed = double.tryParse(text);
      if (parsed == null) {
        amountError = "Monto inválido";
        notifyListeners();
        return false;
      }
      if (parsed <= 0) {
        amountError = "El monto debe ser mayor a 0";
        notifyListeners();
        return false;
      }
    }
    amountError = null;
    notifyListeners();
    return true;
  }

  // ── Step 2: payment source ───────────────────────────────────────────────────

  void onPaymentSourceChanged(String src) {
    paymentSourceStr = src;
    selectedEntity = null;
    selectedAccount = null;
    selectedCreditCard = null;
    selectedCurrency = null;
    entityViewKey = 'entities';
    notifyListeners();
  }

  @override
  void onAccountTap(BankAccount account) {
    selectedAccount = account;
    selectedCreditCard = null;
    selectedCurrency = null;
    notifyListeners();
  }

  @override
  void onCardTap(CreditCard card) {
    selectedCreditCard = card;
    selectedAccount = null;
    selectedCurrency = null;
    notifyListeners();
  }

  void onCurrencyChanged(Currency? currency) {
    selectedCurrency = currency;
    notifyListeners();
  }

  // ── Step 3: schedule ─────────────────────────────────────────────────────────

  void onFrequencyChanged(RecurringFrequency f) {
    frequency = f;
    notifyListeners();
  }

  void onNotificationChanged(int? v) {
    notificationDaysBefore = v;
    notifyListeners();
  }

  Future<void> pickNextExecutionDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: nextExecutionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      nextExecutionDate = picked;
      notifyListeners();
    }
  }

  Future<void> pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? nextExecutionDate.add(const Duration(days: 30)),
      firstDate: nextExecutionDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      endDate = picked;
      notifyListeners();
    }
  }

  void clearEndDate() {
    endDate = null;
    notifyListeners();
  }

  // ── prevStep override ────────────────────────────────────────────────────────

  @override
  void prevStep(BuildContext context) {
    if (currentStep == 1 &&
        selectedParentCategory != null &&
        selectedParentCategory!.children.isNotEmpty) {
      backFromCategoryChildren();
      return;
    }
    // Use == 2 (not >= 2) so step 3 back goes to step 2, not entity list
    if (currentStep == 2 && selectedEntity != null) {
      backFromEntityAccounts();
      return;
    }
    if (currentStep > 0) {
      goToStep(currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  // ── Prefill from existing rule ───────────────────────────────────────────────

  void applyRecurringPrefill(RecurringTransaction existing) {
    nameController.text = existing.name;
    isFixedAmount = existing.amount != null;
    if (isFixedAmount && existing.amount != null) {
      amountController.text = existing.amount.toString();
    }
    type = existing.type;
    frequency = existing.frequency;
    nextExecutionDate = existing.nextExecutionDate;
    endDate = existing.endDate;
    notificationDaysBefore = existing.notificationDaysBefore;
  }

  void applyRecurringCategoryPrefill(String? categoryId) {
    if (categoryId == null) return;
    for (final cat in allCategories) {
      if (cat.id == categoryId) {
        selectedParentCategory = cat;
        selectedCategory = cat;
        break;
      }
      final child = cat.children.where((c) => c.id == categoryId).firstOrNull;
      if (child != null) {
        selectedParentCategory = cat;
        selectedCategory = child;
        categoryViewKey = 'children_${cat.id}';
        break;
      }
    }
  }

  void applyRecurringAccountPrefill({
    String? accountId,
    String? creditCardId,
  }) {
    if (creditCardId != null) {
      paymentSourceStr = 'card';
      try {
        selectedCreditCard = creditCards.firstWhere((c) => c.id == creditCardId);
        selectedEntity = selectedCreditCard?.bankEntity;
        if (selectedEntity != null) entityViewKey = 'accounts_${selectedEntity!.id}';
      } catch (_) {}
    } else if (accountId != null) {
      try {
        selectedAccount = accounts.firstWhere((a) => a.id == accountId);
        selectedEntity = selectedAccount?.bankEntity;
        if (selectedEntity != null) entityViewKey = 'accounts_${selectedEntity!.id}';
      } catch (_) {}
    }
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}
