// lib/features/transactions/presentation/recurring/recurring_transaction_form_screen.dart

import 'package:cashflowiq/core/services/notification_service.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/step_indicator.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/features/profile/data/credit_card_service.dart';
import 'package:cashflowiq/features/profile/presentation/bank_accounts/form_account_screen.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_categories_screen.dart';
import 'package:cashflowiq/features/profile/presentation/credit_cards/form_credit_card_screen.dart';
import 'package:cashflowiq/features/transactions/data/recurring_transaction_service.dart';
import 'package:cashflowiq/features/transactions/presentation/recurring/widgets/recurring_step_account.dart';
import 'package:cashflowiq/features/transactions/presentation/recurring/widgets/recurring_step_category.dart';
import 'package:cashflowiq/features/transactions/presentation/recurring/widgets/recurring_step_details.dart';
import 'package:cashflowiq/features/transactions/presentation/recurring/widgets/recurring_step_schedule.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/recurring_transaction.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';
import 'package:flutter/material.dart';

class RecurringTransactionFormScreen extends StatefulWidget {
  /// If non-null, the form is in edit mode.
  final RecurringTransaction? existing;

  const RecurringTransactionFormScreen({super.key, this.existing});

  @override
  State<RecurringTransactionFormScreen> createState() =>
      _RecurringTransactionFormScreenState();
}

class _RecurringTransactionFormScreenState
    extends State<RecurringTransactionFormScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _pageController = PageController();

  final _categoryService = CategoryService();
  final _accountService = BankAccountService();
  final _creditCardService = CreditCardService();
  final _currencyService = CurrencyService();
  final _recurringService = RecurringTransactionService();

  // ── Loading / saving ──────────────────────────────────────────────────────
  List<Category> _categories = [];
  List<BankAccount> _accounts = [];
  List<CreditCard> _creditCards = [];
  List<Currency> _currencies = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // ── Step 1: details ───────────────────────────────────────────────────────
  String _type = 'INCOME'; // INCOME | EXPENSE
  bool _isFixedAmount = true;
  String? _nameError;
  String? _amountError;

  // ── Step 2: category ──────────────────────────────────────────────────────
  Category? _selectedCategory;
  Category? _selectedParentCategory;
  String _categoryViewKey = 'parents';
  bool _categoryForward = true;

  // ── Step 3: account ───────────────────────────────────────────────────────
  String _paymentSourceStr = 'account'; // 'account' | 'card'
  BankEntity? _selectedEntity;
  BankAccount? _selectedAccount;
  CreditCard? _selectedCreditCard;
  String _entityViewKey = 'entities';
  bool _entityForward = true;
  Currency? _selectedCurrency;

  // ── Step 4: schedule ──────────────────────────────────────────────────────
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  int? _notificationDaysBefore;
  DateTime _nextExecutionDate = DateTime.now();
  DateTime? _endDate;

  // ── Wizard ────────────────────────────────────────────────────────────────
  int _currentStep = 0;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _categoryService.getCategoriesWithChildren(),
        _accountService.getAccounts(),
        _currencyService.getCurrencies(),
        _creditCardService.getCreditCards(),
      ]);
      final categories = results[0] as List<Category>;
      final accounts = results[1] as List<BankAccount>;
      final currencies = results[2] as List<Currency>;
      final creditCards = results[3] as List<CreditCard>;

      setState(() {
        _categories = categories;
        _accounts = accounts;
        _currencies = currencies;
        _creditCards = creditCards;
        _isLoading = false;
      });

      // Pre-populate from existing rule
      if (_isEditing) {
        final e = widget.existing!;
        _nameController.text = e.name;
        _isFixedAmount = e.amount != null;
        if (_isFixedAmount && e.amount != null) {
          _amountController.text = e.amount.toString();
        }
        _type = e.type;
        _frequency = e.frequency;
        _nextExecutionDate = e.nextExecutionDate;
        _endDate = e.endDate;
        _notificationDaysBefore = e.notificationDaysBefore;

        if (e.categoryId != null) {
          final targetId = e.categoryId.toString();
          for (final cat in _categories) {
            if (cat.id == targetId) {
              _selectedParentCategory = cat;
              _selectedCategory = cat;
              break;
            }
            final child =
                cat.children.where((c) => c.id == targetId).firstOrNull;
            if (child != null) {
              _selectedParentCategory = cat;
              _selectedCategory = child;
              _categoryViewKey = 'children_${cat.id}';
              break;
            }
          }
        }

        if (e.creditCardId != null) {
          _paymentSourceStr = 'card';
          try {
            _selectedCreditCard = _creditCards
                .firstWhere((c) => c.id == e.creditCardId.toString());
            _selectedEntity = _selectedCreditCard?.bankEntity;
            if (_selectedEntity != null) {
              _entityViewKey = 'accounts_${_selectedEntity!.id}';
            }
          } catch (_) {}
        } else if (e.accountId != null) {
          try {
            _selectedAccount = _accounts
                .firstWhere((a) => a.id == e.accountId.toString());
            _selectedEntity = _selectedAccount?.bankEntity;
            if (_selectedEntity != null) {
              _entityViewKey = 'accounts_${_selectedEntity!.id}';
            }
          } catch (_) {}
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error loading form data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Computed getters ──────────────────────────────────────────────────────

  List<Category> get _filteredCategories {
    final wanted = _type == 'INCOME' ? CategoryType.income : CategoryType.expense;
    return _categories.where((c) => c.type == wanted).toList();
  }

  List<BankEntity> get _accountEntities {
    final seen = <String>{};
    return [
      for (final a in _accounts)
        if (seen.add(a.bankEntity.id)) a.bankEntity,
    ];
  }

  List<BankEntity> get _cardEntities {
    final seen = <String>{};
    return [
      for (final c in _creditCards)
        if (seen.add(c.bankEntity.id)) c.bankEntity,
    ];
  }

  List<BankAccount> _accountsFor(BankEntity entity) =>
      _accounts.where((a) => a.bankEntity.id == entity.id).toList();

  List<CreditCard> _cardsFor(BankEntity entity) =>
      _creditCards.where((c) => c.bankEntity.id == entity.id).toList();

  // ── Date pickers ──────────────────────────────────────────────────────────

  Future<void> _pickNextExecutionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextExecutionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _nextExecutionDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _nextExecutionDate.add(const Duration(days: 30)),
      firstDate: _nextExecutionDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  // ── Wizard navigation ─────────────────────────────────────────────────────

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateStep1() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = "Ingresa un nombre");
      return false;
    }
    setState(() => _nameError = null);

    if (_isFixedAmount) {
      final text = _amountController.text.trim();
      if (text.isEmpty) {
        setState(() => _amountError = "Ingresa un monto");
        return false;
      }
      final parsed = double.tryParse(text);
      if (parsed == null) {
        setState(() => _amountError = "Monto inválido");
        return false;
      }
      if (parsed <= 0) {
        setState(() => _amountError = "El monto debe ser mayor a 0");
        return false;
      }
    }
    setState(() => _amountError = null);
    return true;
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_validateStep1()) _goToStep(1);
    } else if (_currentStep < 3) {
      _goToStep(_currentStep + 1);
    }
  }

  void _prevStep() {
    if (_currentStep == 1 &&
        _selectedParentCategory != null &&
        _selectedParentCategory!.children.isNotEmpty) {
      _backFromCategoryChildren();
      return;
    }
    if (_currentStep == 2 && _selectedEntity != null) {
      _backFromEntityAccounts();
      return;
    }
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  // ── Step 1 callbacks ──────────────────────────────────────────────────────

  void _onTypeChanged(String type) {
    setState(() {
      _type = type;
      _selectedCategory = null;
      _selectedParentCategory = null;
      _categoryViewKey = 'parents';
      // Income always uses bank account
      if (type == 'INCOME') {
        _paymentSourceStr = 'account';
        _selectedCreditCard = null;
      }
    });
  }

  // ── Step 2 callbacks ──────────────────────────────────────────────────────

  void _onParentCategoryTap(Category category) {
    if (category.children.isNotEmpty) {
      setState(() {
        _selectedParentCategory = category;
        _selectedCategory = null;
        _categoryForward = true;
        _categoryViewKey = 'children_${category.id}';
      });
    } else {
      setState(() {
        _selectedParentCategory = category;
        _selectedCategory = category;
      });
    }
  }

  void _onChildCategoryTap(Category category) {
    setState(() => _selectedCategory = category);
  }

  void _backFromCategoryChildren() {
    setState(() {
      _selectedParentCategory = null;
      _selectedCategory = null;
      _categoryForward = false;
      _categoryViewKey = 'parents';
    });
  }

  // ── Step 3 callbacks ──────────────────────────────────────────────────────

  void _onPaymentSourceChanged(String src) {
    setState(() {
      _paymentSourceStr = src;
      _selectedEntity = null;
      _selectedAccount = null;
      _selectedCreditCard = null;
      _selectedCurrency = null;
      _entityViewKey = 'entities';
    });
  }

  void _onEntityTap(BankEntity entity) {
    setState(() {
      if (_selectedEntity?.id != entity.id) {
        _selectedAccount = null;
        _selectedCreditCard = null;
      }
      _selectedEntity = entity;
      _entityForward = true;
      _entityViewKey = 'accounts_${entity.id}';
    });
  }

  void _onAccountTap(BankAccount account) {
    setState(() {
      _selectedAccount = account;
      _selectedCreditCard = null;
      _selectedCurrency = null;
    });
  }

  void _onCardTap(CreditCard card) {
    setState(() {
      _selectedCreditCard = card;
      _selectedAccount = null;
      _selectedCurrency = null;
    });
  }

  void _backFromEntityAccounts() {
    setState(() {
      _selectedEntity = null;
      _entityForward = false;
      _entityViewKey = 'entities';
    });
  }

  // ── Navigation to creation forms ──────────────────────────────────────────

  Future<void> _navigateToCategoryForm({Category? parent}) async {
    final categoryType =
        _type == 'INCOME' ? CategoryType.income : CategoryType.expense;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormCategoriesScreen(
          initialType: categoryType,
          parent: parent,
        ),
      ),
    );
    if (result == true && mounted) await _loadData();
  }

  Future<void> _navigateToAccountForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FormAccountScreen()),
    );
    if (result == true && mounted) await _loadData();
  }

  Future<void> _navigateToCreditCardForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FormCreditCardScreen()),
    );
    if (result == true && mounted) await _loadData();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final usingCard = _type == 'EXPENSE' && _paymentSourceStr == 'card';

    if (usingCard && _selectedCreditCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona una tarjeta de crédito")));
      return;
    }

    setState(() => _isSaving = true);

    // Cancel the old notification when editing before saving
    if (_isEditing) {
      NotificationService.instance
          .cancelRecurringNotification(widget.existing!.id);
    }

    final accountId =
        usingCard || _selectedAccount == null ? null : int.tryParse(_selectedAccount!.id);
    final creditCardId =
        usingCard && _selectedCreditCard != null ? int.tryParse(_selectedCreditCard!.id) : null;
    // Currency is derived server-side from the linked account/card; only send
    // an explicit currency when neither is selected.
    final currencyId =
        (accountId == null && creditCardId == null) ? _selectedCurrency?.id : null;

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'amount': _isFixedAmount ? double.parse(_amountController.text.trim()) : null,
      'type': _type,
      'frequency': _frequency.toApi(),
      'next_execution_date': _nextExecutionDate.toIso8601String(),
      if (_endDate != null) 'end_date': _endDate!.toIso8601String().split('T').first,
      if (_selectedCategory != null) 'category_id': int.tryParse(_selectedCategory!.id),
      'account_id': accountId,
      'credit_card_id': creditCardId,
      'currency_id': currencyId,
      'notification_days_before': _notificationDaysBefore,
    };

    try {
      RecurringTransaction result;
      if (_isEditing) {
        result = await _recurringService.update(widget.existing!.id, payload);
      } else {
        result = await _recurringService.create(payload);
      }

      // Schedule the notification for the saved rule
      await NotificationService.instance.scheduleRecurringNotification(result);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("recurring form submit error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al guardar la regla recurrente")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PopScope(
                canPop: _currentStep == 0,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) _prevStep();
                },
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          RecurringStepDetails(
                            type: _type,
                            isFixedAmount: _isFixedAmount,
                            nameController: _nameController,
                            amountController: _amountController,
                            nameError: _nameError,
                            amountError: _amountError,
                            onTypeChanged: _onTypeChanged,
                            onAmountTypeChanged: (fixed) {
                              setState(() {
                                _isFixedAmount = fixed;
                                if (!fixed) _amountController.clear();
                              });
                            },
                            onNameChanged: () {
                              if (_nameError != null) {
                                setState(() => _nameError = null);
                              }
                            },
                            onAmountChanged: () {
                              if (_amountError != null) {
                                setState(() => _amountError = null);
                              }
                            },
                          ),
                          RecurringStepCategory(
                            categories: _filteredCategories,
                            selectedParentCategory: _selectedParentCategory,
                            selectedCategory: _selectedCategory,
                            viewKey: _categoryViewKey,
                            goingForward: _categoryForward,
                            onParentTap: _onParentCategoryTap,
                            onChildTap: _onChildCategoryTap,
                            onBack: _backFromCategoryChildren,
                            onAddCategory: () =>
                                _navigateToCategoryForm(),
                            onAddSubcategory: () =>
                                _navigateToCategoryForm(parent: _selectedParentCategory),
                          ),
                          RecurringStepAccount(
                            type: _type,
                            paymentSource: _paymentSourceStr,
                            accountEntities: _accountEntities,
                            cardEntities: _cardEntities,
                            selectedEntity: _selectedEntity,
                            selectedAccount: _selectedAccount,
                            selectedCreditCard: _selectedCreditCard,
                            viewKey: _entityViewKey,
                            goingForward: _entityForward,
                            accountsFor: _accountsFor,
                            cardsFor: _cardsFor,
                            currencies: _currencies,
                            selectedCurrency: _selectedCurrency,
                            onPaymentSourceChanged: _onPaymentSourceChanged,
                            onEntityTap: _onEntityTap,
                            onAccountTap: _onAccountTap,
                            onCardTap: _onCardTap,
                            onBack: _backFromEntityAccounts,
                            onAddAccount: _navigateToAccountForm,
                            onAddCreditCard: _navigateToCreditCardForm,
                            onCurrencyChanged: (c) =>
                                setState(() => _selectedCurrency = c),
                          ),
                          RecurringStepSchedule(
                            frequency: _frequency,
                            notificationDaysBefore: _notificationDaysBefore,
                            nextExecutionDate: _nextExecutionDate,
                            endDate: _endDate,
                            isFixedAmount: _isFixedAmount,
                            onFrequencyChanged: (f) =>
                                setState(() => _frequency = f),
                            onNotificationChanged: (v) =>
                                setState(() => _notificationDaysBefore = v),
                            onPickNextDate: _pickNextExecutionDate,
                            onPickEndDate: _pickEndDate,
                            onClearEndDate: () =>
                                setState(() => _endDate = null),
                          ),
                        ],
                      ),
                    ),
                    StepIndicator(
                      currentStep: _currentStep,
                      totalSteps: 4,
                      activeColor: AppColors.primary,
                    ),
                    _bottomBar(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _bottomBar() {
    final isLastStep = _currentStep == 3;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _prevStep,
              child: Text("Atrás",
                  style: AppTextStyles.subtitle2(context,
                      color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : (isLastStep ? _submit : _nextStep),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isLastStep
                          ? (_isEditing ? "Guardar cambios" : "Crear regla")
                          : "Siguiente",
                      style: AppTextStyles.subtitle2(context,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
