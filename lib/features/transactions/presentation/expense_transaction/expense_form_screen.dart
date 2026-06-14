// lib/features/transactions/presentation/expense_transaction/expense_form_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/credit_card_service.dart';
import 'package:cashflowiq/features/profile/presentation/bank_accounts/form_account_screen.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_categories_screen.dart';
import 'package:cashflowiq/features/profile/presentation/credit_cards/form_credit_card_screen.dart';
import 'package:cashflowiq/features/transactions/data/transaction_service.dart';
import 'package:cashflowiq/features/transactions/presentation/expense_transaction/widgets/expense_step_amount.dart';
import 'package:cashflowiq/features/transactions/presentation/expense_transaction/widgets/expense_step_categories.dart';
import 'package:cashflowiq/core/widgets/step_indicator.dart';
import 'package:cashflowiq/features/transactions/presentation/expense_transaction/widgets/expense_step_payment.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:flutter/material.dart';

class ExpenseFormScreen extends StatefulWidget {
  final List<Category> categories;
  final Transaction? prefill;
  final bool editMode;
  /// Called after a new category is created so the parent can reload the list.
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
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pageController = PageController();

  final _accountService = BankAccountService();
  final _creditCardService = CreditCardService();
  final _transactionService = TransactionService();

  List<BankAccount> _accounts = [];
  List<CreditCard> _creditCards = [];
  bool _isLoadingSources = true;

  // ── Step 2: category (two-level) ─────────────────────────────────────────
  Category? _selectedParentCategory;
  Category? _selectedCategory;
  String _categoryViewKey = 'parents';
  bool _categoryForward = true;

  // ── Step 3: payment source (two-level) ───────────────────────────────────
  BankEntity? _selectedEntity;
  BankAccount? _selectedAccount;
  CreditCard? _selectedCreditCard;
  String _entityViewKey = 'entities';
  bool _entityForward = true;

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  int _currentStep = 0;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      final p = widget.prefill!;
      final a = p.amount;
      _amountController.text = a % 1 == 0 ? a.toInt().toString() : a.toString();
      _descriptionController.text = p.description ?? '';
      _selectedDate = p.date;
      for (final cat in widget.categories) {
        if (cat.id == p.categoryId) {
          _selectedParentCategory = cat;
          _selectedCategory = cat;
          break;
        }
        for (final child in cat.children) {
          if (child.id == p.categoryId) {
            _selectedParentCategory = cat;
            _selectedCategory = child;
            _categoryViewKey = 'children_${cat.id}';
            break;
          }
        }
        if (_selectedCategory != null) break;
      }
    }
    _loadSources();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadSources() async {
    try {
      final results = await Future.wait([
        _accountService.getAccounts(),
        _creditCardService.getCreditCards(),
      ]);
      setState(() {
        _accounts = results[0] as List<BankAccount>;
        _creditCards = results[1] as List<CreditCard>;
        _isLoadingSources = false;
        if (widget.prefill != null) {
          final p = widget.prefill!;
          if (p.creditCardId != null) {
            _selectedCreditCard = _creditCards.where((c) => c.id == p.creditCardId).firstOrNull;
            _selectedEntity = _selectedCreditCard?.bankEntity;
            if (_selectedEntity != null) _entityViewKey = 'accounts_${_selectedEntity!.id}';
          } else if (p.accountId != null) {
            _selectedAccount = _accounts.where((a) => a.id == p.accountId).firstOrNull;
            _selectedEntity = _selectedAccount?.bankEntity;
            if (_selectedEntity != null) _entityViewKey = 'accounts_${_selectedEntity!.id}';
          }
        }
      });
    } catch (_) {
      setState(() => _isLoadingSources = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<BankEntity> get _entities {
    final seen = <String>{};
    final result = <BankEntity>[];
    for (final a in _accounts) {
      if (seen.add(a.bankEntity.id)) result.add(a.bankEntity);
    }
    for (final c in _creditCards) {
      if (seen.add(c.bankEntity.id)) result.add(c.bankEntity);
    }
    return result;
  }

  List<BankAccount> _accountsFor(BankEntity entity) =>
      _accounts.where((a) => a.bankEntity.id == entity.id).toList();

  List<CreditCard> _cardsFor(BankEntity entity) =>
      _creditCards.where((c) => c.bankEntity.id == entity.id).toList();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  bool _validateStep1() {
    final text = _amountController.text.trim();
    if (text.isEmpty) { setState(() => _amountError = "Ingresa un monto"); return false; }
    final parsed = double.tryParse(text);
    if (parsed == null) { setState(() => _amountError = "Monto inválido"); return false; }
    if (parsed <= 0) { setState(() => _amountError = "El monto debe ser mayor a 0"); return false; }
    setState(() => _amountError = null);
    return true;
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_validateStep1()) _goToStep(1);
    } else if (_currentStep == 1) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona una categoría")),
        );
        return;
      }
      _goToStep(2);
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

  void _backFromCategoryChildren() {
    setState(() {
      _selectedParentCategory = null;
      _selectedCategory = null;
      _categoryForward = false;
      _categoryViewKey = 'parents';
    });
  }

  void _backFromEntityAccounts() {
    setState(() {
      _selectedEntity = null;
      _entityForward = false;
      _entityViewKey = 'entities';
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

  // ── Step 3 callbacks ──────────────────────────────────────────────────────

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
    });
  }

  void _onCardTap(CreditCard card) {
    setState(() {
      _selectedCreditCard = card;
      _selectedAccount = null;
    });
  }

  // ── Navigation to creation forms ──────────────────────────────────────────

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
    if (result == true && mounted) await _loadSources();
  }

  Future<void> _navigateToCreditCardForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FormCreditCardScreen()),
    );
    if (result == true && mounted) await _loadSources();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final usingCard = _selectedCreditCard != null;
    if (!usingCard && _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una cuenta o tarjeta")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final tx = Transaction(
      id: widget.editMode ? widget.prefill!.id : '',
      type: TransactionType.expense,
      amount: double.parse(_amountController.text.trim()),
      date: _selectedDate,
      categoryId: _selectedCategory!.id,
      accountId: usingCard ? null : _selectedAccount!.id,
      creditCardId: usingCard ? _selectedCreditCard!.id : null,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
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
          content: Text(widget.editMode
              ? "Error al actualizar el gasto"
              : "Error al registrar el gasto"),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSources) return const Center(child: CircularProgressIndicator());

    return PopScope(
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
                ExpenseStepAmount(
                  amountController: _amountController,
                  descriptionController: _descriptionController,
                  selectedDate: _selectedDate,
                  amountError: _amountError,
                  onDateTap: _pickDate,
                  onAmountChanged: () {
                    if (_amountError != null) setState(() => _amountError = null);
                  },
                ),
                ExpenseStepCategories(
                  categories: widget.categories,
                  selectedParentCategory: _selectedParentCategory,
                  selectedCategory: _selectedCategory,
                  viewKey: _categoryViewKey,
                  goingForward: _categoryForward,
                  onParentTap: _onParentCategoryTap,
                  onChildTap: _onChildCategoryTap,
                  onBack: _backFromCategoryChildren,
                  onAddCategory: () => _navigateToCategoryForm(),
                  onAddSubcategory: () => _navigateToCategoryForm(
                    parent: _selectedParentCategory,
                  ),
                ),
                ExpenseStepPayment(
                  entities: _entities,
                  selectedEntity: _selectedEntity,
                  selectedAccount: _selectedAccount,
                  selectedCreditCard: _selectedCreditCard,
                  viewKey: _entityViewKey,
                  goingForward: _entityForward,
                  accountsFor: _accountsFor,
                  cardsFor: _cardsFor,
                  onEntityTap: _onEntityTap,
                  onAccountTap: _onAccountTap,
                  onCardTap: _onCardTap,
                  onBack: _backFromEntityAccounts,
                  onAddAccount: _navigateToAccountForm,
                  onAddCreditCard: _navigateToCreditCardForm,
                ),
              ],
            ),
          ),
          StepIndicator(currentStep: _currentStep, totalSteps: 3),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final isLastStep = _currentStep == 2;
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
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _prevStep,
              child: Text("Atrás", style: AppTextStyles.subtitle2(context, color: AppColors.error)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : (isLastStep ? _submit : _nextStep),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isLastStep
                          ? (widget.editMode ? "Guardar cambios" : "Guardar gasto")
                          : "Siguiente",
                      style: AppTextStyles.subtitle2(context, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
