import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/bank_entity_service.dart';
import 'package:cashflowiq/features/profile/data/credit_card_service.dart';
import 'package:cashflowiq/features/profile/data/payment_source_service.dart';
import 'package:cashflowiq/features/profile/presentation/bank_accounts/form_account_screen.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_categories_screen.dart';
import 'package:cashflowiq/features/profile/presentation/credit_cards/form_credit_card_screen.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/payment_source_item.dart';
import 'package:flutter/material.dart';

/// Controller that holds the common state and logic shared across all
/// transaction form screens (income, expense, transfer, recurring, split).
///
/// Instantiate inside the form's StatefulWidget State, then wire the step
/// widgets and bottom bar to the controller's fields and callbacks.
class BaseTransactionFormController extends ChangeNotifier {
  // ── Services ────────────────────────────────────────────────────────────────
  final BankAccountService accountService = BankAccountService();
  final CreditCardService creditCardService = CreditCardService();
  final PaymentSourceService paymentSourceService = PaymentSourceService();
  final BankEntityService entityService = BankEntityService();

  // ── Text controllers ────────────────────────────────────────────────────────
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final PageController pageController = PageController();

  // ── Loading state ───────────────────────────────────────────────────────────
  List<BankAccount> accounts = [];
  List<CreditCard> creditCards = [];
  List<PaymentSourceItem> mostUsedItems = [];
  bool isLoadingSources = true;
  bool isSaving = false;
  int currentStep = 0;
  String? amountError;

  // ── Date ────────────────────────────────────────────────────────────────────
  DateTime selectedDate = DateTime.now();

  // ── Category selection (two-level) ──────────────────────────────────────────
  Category? selectedParentCategory;
  Category? selectedCategory;
  String categoryViewKey = 'parents';
  bool categoryForward = true;

  // ── Payment source selection (two-level: entity → account / card) ───────────
  BankEntity? selectedEntity;
  BankAccount? selectedAccount;
  CreditCard? selectedCreditCard;
  String entityViewKey = 'entities';
  bool entityForward = true;

  // ── Getters ─────────────────────────────────────────────────────────────────

  List<BankEntity> get uniqueEntities {
    final seen = <String>{};
    final result = <BankEntity>[];
    for (final a in accounts) {
      if (seen.add(a.bankEntity.id)) result.add(a.bankEntity);
    }
    for (final c in creditCards) {
      if (seen.add(c.bankEntity.id)) result.add(c.bankEntity);
    }
    return result;
  }

  List<BankAccount> accountsFor(BankEntity entity) =>
      accounts.where((a) => a.bankEntity.id == entity.id).toList();

  List<CreditCard> cardsFor(BankEntity entity) =>
      creditCards.where((c) => c.bankEntity.id == entity.id).toList();

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> loadSources() async {
    try {
      final results = await Future.wait([
        accountService.getAccounts(),
        creditCardService.getCreditCards(),
        paymentSourceService.getMostUsedSources(),
      ]);
      final rawAccounts = results[0] as List<BankAccount>;
      final rawCards = results[1] as List<CreditCard>;
      final rawSources = results[2] as List<Map<String, dynamic>>;

      final items = <PaymentSourceItem>[];
      for (final src in rawSources) {
        final type = src['type'] as String;
        final id = src['id'].toString();
        final name = src['name'] as String;
        final entityCode = src['bank_entity']['code'] as String;

        if (type == 'account') {
          final match = rawAccounts.where((a) => a.id == id);
          if (match.isNotEmpty) {
            final account = match.first;
            items.add(PaymentSourceItem(
              icon: Icons.account_balance,
              id: id,
              name: name,
              entityCode: entityCode,
              isAccount: true,
              onTap: () => onAccountTap(account),
            ));
          }
        } else {
          final match = rawCards.where((c) => c.id == id);
          if (match.isNotEmpty) {
            final card = match.first;
            items.add(PaymentSourceItem(
              icon: Icons.credit_card,
              id: id,
              name: name,
              entityCode: entityCode,
              isAccount: false,
              onTap: () => onCardTap(card),
            ));
          }
        }
      }

      accounts = rawAccounts;
      creditCards = rawCards;
      mostUsedItems = items;
      isLoadingSources = false;
      notifyListeners();
    } catch (_) {
      isLoadingSources = false;
      notifyListeners();
    }
  }

  /// Single-service variant for forms that only need accounts (income, transfer).
  Future<void> loadAccountsOnly() async {
    try {
      final rawAccounts = await accountService.getAccounts();
      accounts = rawAccounts;
      isLoadingSources = false;
      notifyListeners();
    } catch (_) {
      isLoadingSources = false;
      notifyListeners();
    }
  }

  // ── Saving state ────────────────────────────────────────────────────────────

  void setSaving(bool value) {
    isSaving = value;
    notifyListeners();
  }

  // ── Step validation ─────────────────────────────────────────────────────────

  bool validateAmount() {
    final text = amountController.text.trim();
    if (text.isEmpty) {
      amountError = 'Ingresa un monto';
      notifyListeners();
      return false;
    }
    final parsed = double.tryParse(text);
    if (parsed == null) {
      amountError = 'Monto inválido';
      notifyListeners();
      return false;
    }
    if (parsed <= 0) {
      amountError = 'El monto debe ser mayor a 0';
      notifyListeners();
      return false;
    }
    amountError = null;
    notifyListeners();
    return true;
  }

  void clearAmountError() {
    if (amountError != null) {
      amountError = null;
      notifyListeners();
    }
  }

  // ── Step navigation ─────────────────────────────────────────────────────────

  void goToStep(int step) {
    currentStep = step;
    notifyListeners();
    pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void prevStep(BuildContext context) {
    if (currentStep == 1 &&
        selectedParentCategory != null &&
        selectedParentCategory!.children.isNotEmpty) {
      backFromCategoryChildren();
      return;
    }
    if (currentStep >= 2 && selectedEntity != null) {
      backFromEntityAccounts();
      return;
    }
    if (currentStep > 0) {
      goToStep(currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  // ── Date picker ─────────────────────────────────────────────────────────────

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      selectedDate = picked;
      notifyListeners();
    }
  }

  // ── Category navigation ─────────────────────────────────────────────────────

  void onParentCategoryTap(Category category) {
    if (category.children.isNotEmpty) {
      selectedParentCategory = category;
      selectedCategory = null;
      categoryForward = true;
      categoryViewKey = 'children_${category.id}';
      notifyListeners();
    } else {
      selectedParentCategory = category;
      selectedCategory = category;
      notifyListeners();
    }
  }

  void onChildCategoryTap(Category category) {
    selectedCategory = category;
    notifyListeners();
  }

  void backFromCategoryChildren() {
    selectedParentCategory = null;
    selectedCategory = null;
    categoryForward = false;
    categoryViewKey = 'parents';
    notifyListeners();
  }

  // ── Payment source navigation ───────────────────────────────────────────────

  void onEntityTap(BankEntity entity) {
    if (selectedEntity?.id != entity.id) {
      selectedAccount = null;
      selectedCreditCard = null;
    }
    selectedEntity = entity;
    entityForward = true;
    entityViewKey = 'accounts_${entity.id}';
    notifyListeners();
  }

  void onAccountTap(BankAccount account) {
    selectedAccount = account;
    selectedCreditCard = null;
    notifyListeners();
  }

  void onCardTap(CreditCard card) {
    selectedCreditCard = card;
    selectedAccount = null;
    notifyListeners();
  }

  void backFromEntityAccounts() {
    selectedEntity = null;
    entityForward = false;
    entityViewKey = 'entities';
    notifyListeners();
  }

  // ── Navigation to creation forms ────────────────────────────────────────────

  Future<void> navigateToCategoryForm(
    BuildContext context, {
    CategoryType initialType = CategoryType.expense,
    Category? parent,
    VoidCallback? onCategoryAdded,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormCategoriesScreen(
          initialType: initialType,
          parent: parent,
        ),
      ),
    );
    if (result == true) onCategoryAdded?.call();
  }

  Future<void> navigateToAccountForm(
    BuildContext context, {
    VoidCallback? onReload,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FormAccountScreen()),
    );
    if (result == true) {
      if (onReload != null) {
        onReload();
      } else {
        await loadSources();
      }
    }
  }

  Future<void> navigateToCreditCardForm(
    BuildContext context, {
    VoidCallback? onReload,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FormCreditCardScreen()),
    );
    if (result == true) {
      if (onReload != null) {
        onReload();
      } else {
        await loadSources();
      }
    }
  }

  // ── Prefill helpers ─────────────────────────────────────────────────────────

  void applyPrefill({
    required double amount,
    String? description,
    DateTime? date,
    List<Category> categories = const [],
    String? categoryId,
  }) {
    final a = amount;
    amountController.text = a % 1 == 0 ? a.toInt().toString() : a.toString();
    descriptionController.text = description ?? '';
    selectedDate = date ?? DateTime.now();

    for (final cat in categories) {
      if (cat.id == categoryId) {
        selectedParentCategory = cat;
        selectedCategory = cat;
        break;
      }
      for (final child in cat.children) {
        if (child.id == categoryId) {
          selectedParentCategory = cat;
          selectedCategory = child;
          categoryViewKey = 'children_${cat.id}';
          break;
        }
      }
      if (selectedCategory != null) break;
    }
  }

  void applyAccountPrefill({
    required List<BankAccount> accounts,
    required List<CreditCard> creditCards,
    String? accountId,
    String? creditCardId,
  }) {
    if (creditCardId != null) {
      selectedCreditCard = creditCards.where((c) => c.id == creditCardId).firstOrNull;
      selectedEntity = selectedCreditCard?.bankEntity;
      if (selectedEntity != null) entityViewKey = 'accounts_${selectedEntity!.id}';
    } else if (accountId != null) {
      selectedAccount = accounts.where((a) => a.id == accountId).firstOrNull;
      selectedEntity = selectedAccount?.bankEntity;
      if (selectedEntity != null) entityViewKey = 'accounts_${selectedEntity!.id}';
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    pageController.dispose();
    super.dispose();
  }
}
