// lib/features/transactions/presentation/transfer_transaction/transfer_form_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/step_indicator.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/credit_card_service.dart';
import 'package:cashflowiq/features/profile/presentation/bank_accounts/form_account_screen.dart';
import 'package:cashflowiq/features/profile/presentation/credit_cards/form_credit_card_screen.dart';
import 'package:cashflowiq/features/transactions/data/transaction_service.dart';
import 'package:cashflowiq/features/transactions/presentation/transfer_transaction/widgets/transfer_step_amount.dart';
import 'package:cashflowiq/features/transactions/presentation/transfer_transaction/widgets/transfer_step_from.dart';
import 'package:cashflowiq/features/transactions/presentation/transfer_transaction/widgets/transfer_step_to.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:flutter/material.dart';

class TransferFormScreen extends StatefulWidget {
  final Transaction? prefill;
  final bool editMode;

  const TransferFormScreen({super.key, this.prefill, this.editMode = false});

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pageController = PageController();

  final _accountService = BankAccountService();
  final _creditCardService = CreditCardService();
  final _transactionService = TransactionService();

  List<BankAccount> _accounts = [];
  List<CreditCard> _creditCards = [];
  bool _isLoadingSources = true;

  // ── Step 2: from (entity → bank account) ─────────────────────────────────
  BankEntity? _fromEntity;
  BankAccount? _fromAccount;
  String _fromViewKey = 'entities';
  bool _fromForward = true;

  // ── Step 3: to (toggle + entity → account or card) ───────────────────────
  String _destinationType = 'account'; // 'account' | 'card'
  BankEntity? _toEntity;
  BankAccount? _toAccount;
  CreditCard? _toCreditCard;
  String _toViewKey = 'entities';
  bool _toForward = true;

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
      final accounts = results[0] as List<BankAccount>;
      final creditCards = results[1] as List<CreditCard>;

      setState(() {
        _accounts = accounts;
        _creditCards = creditCards;
        _isLoadingSources = false;

        if (widget.prefill != null) {
          final p = widget.prefill!;
          // Restore from-account
          if (p.accountId != null) {
            _fromAccount = accounts
                .where((a) => a.id == p.accountId)
                .firstOrNull;
            _fromEntity = _fromAccount?.bankEntity;
            if (_fromEntity != null) _fromViewKey = 'accounts_${_fromEntity!.id}';
          }
          // Restore to-account or to-card
          if (p.toAccountId != null) {
            _toAccount = accounts
                .where((a) => a.id == p.toAccountId)
                .firstOrNull;
            _toEntity = _toAccount?.bankEntity;
            _destinationType = 'account';
            if (_toEntity != null) _toViewKey = 'accounts_${_toEntity!.id}';
          } else if (p.toCreditCardId != null) {
            _toCreditCard = creditCards
                .where((c) => c.id == p.toCreditCardId)
                .firstOrNull;
            _toEntity = _toCreditCard?.bankEntity;
            _destinationType = 'card';
            if (_toEntity != null) _toViewKey = 'accounts_${_toEntity!.id}';
          }
        }
      });
    } catch (_) {
      setState(() => _isLoadingSources = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<BankEntity> get _fromEntities {
    final seen = <String>{};
    final result = <BankEntity>[];
    for (final a in _accounts) {
      if (seen.add(a.bankEntity.id)) result.add(a.bankEntity);
    }
    return result;
  }

  List<BankEntity> get _accountEntities {
    final seen = <String>{};
    final result = <BankEntity>[];
    for (final a in _accounts) {
      if (seen.add(a.bankEntity.id)) result.add(a.bankEntity);
    }
    return result;
  }

  List<BankEntity> get _cardEntities {
    final seen = <String>{};
    final result = <BankEntity>[];
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

  // ── Navigation ────────────────────────────────────────────────────────────

  bool _validateStep1() {
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
      if (_fromAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona la cuenta de origen")),
        );
        return;
      }
      _goToStep(2);
    }
  }

  void _prevStep() {
    if (_currentStep == 1 && _fromEntity != null) {
      _backFromFrom();
      return;
    }
    if (_currentStep == 2 && _toEntity != null) {
      _backFromTo();
      return;
    }
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  void _backFromFrom() {
    setState(() {
      _fromEntity = null;
      _fromForward = false;
      _fromViewKey = 'entities';
    });
  }

  void _backFromTo() {
    setState(() {
      _toEntity = null;
      _toForward = false;
      _toViewKey = 'entities';
    });
  }

  // ── Step 2 callbacks ──────────────────────────────────────────────────────

  void _onFromEntityTap(BankEntity entity) {
    setState(() {
      if (_fromEntity?.id != entity.id) _fromAccount = null;
      _fromEntity = entity;
      _fromForward = true;
      _fromViewKey = 'accounts_${entity.id}';
    });
  }

  void _onFromAccountTap(BankAccount account) {
    setState(() => _fromAccount = account);
  }

  // ── Step 3 callbacks ──────────────────────────────────────────────────────

  void _onDestinationTypeChanged(String type) {
    setState(() {
      _destinationType = type;
      _toEntity = null;
      _toAccount = null;
      _toCreditCard = null;
      _toViewKey = 'entities';
    });
  }

  void _onToEntityTap(BankEntity entity) {
    setState(() {
      if (_toEntity?.id != entity.id) {
        _toAccount = null;
        _toCreditCard = null;
      }
      _toEntity = entity;
      _toForward = true;
      _toViewKey = 'accounts_${entity.id}';
    });
  }

  void _onToAccountTap(BankAccount account) {
    setState(() {
      _toAccount = account;
      _toCreditCard = null;
    });
  }

  void _onToCardTap(CreditCard card) {
    setState(() {
      _toCreditCard = card;
      _toAccount = null;
    });
  }

  // ── Navigation to creation forms ──────────────────────────────────────────

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
    if (_fromAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona la cuenta de origen")),
      );
      return;
    }

    if (_destinationType == 'account') {
      if (_toAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona la cuenta de destino")),
        );
        return;
      }
      if (_fromAccount!.id == _toAccount!.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Las cuentas de origen y destino deben ser diferentes")),
        );
        return;
      }
    } else {
      if (_toCreditCard == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona una tarjeta de crédito de destino")),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final tx = Transaction(
      id: widget.editMode ? widget.prefill!.id : '',
      type: TransactionType.transfer,
      amount: double.parse(_amountController.text.trim()),
      date: _selectedDate,
      accountId: _fromAccount!.id,
      toAccountId: _destinationType == 'account' ? _toAccount!.id : null,
      toCreditCardId: _destinationType == 'card' ? _toCreditCard!.id : null,
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
      debugPrint("transferTransaction error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editMode
              ? "Error al actualizar la transferencia"
              : "Error al registrar la transferencia"),
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
                TransferStepAmount(
                  amountController: _amountController,
                  descriptionController: _descriptionController,
                  selectedDate: _selectedDate,
                  amountError: _amountError,
                  onDateTap: _pickDate,
                  onAmountChanged: () {
                    if (_amountError != null) setState(() => _amountError = null);
                  },
                ),
                TransferStepFrom(
                  entities: _fromEntities,
                  selectedEntity: _fromEntity,
                  selectedAccount: _fromAccount,
                  viewKey: _fromViewKey,
                  goingForward: _fromForward,
                  accountsFor: _accountsFor,
                  onEntityTap: _onFromEntityTap,
                  onAccountTap: _onFromAccountTap,
                  onBack: _backFromFrom,
                  onAddAccount: _navigateToAccountForm,
                ),
                TransferStepTo(
                  destinationType: _destinationType,
                  accountEntities: _accountEntities,
                  cardEntities: _cardEntities,
                  selectedEntity: _toEntity,
                  selectedAccount: _toAccount,
                  selectedCreditCard: _toCreditCard,
                  viewKey: _toViewKey,
                  goingForward: _toForward,
                  accountsFor: _accountsFor,
                  cardsFor: _cardsFor,
                  onTypeChanged: _onDestinationTypeChanged,
                  onEntityTap: _onToEntityTap,
                  onAccountTap: _onToAccountTap,
                  onCardTap: _onToCardTap,
                  onBack: _backFromTo,
                  onAddAccount: _navigateToAccountForm,
                  onAddCreditCard: _navigateToCreditCardForm,
                ),
              ],
            ),
          ),
          StepIndicator(
            currentStep: _currentStep,
            totalSteps: 3,
            activeColor: AppColors.primary,
          ),
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
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _prevStep,
              child: Text("Atrás", style: AppTextStyles.subtitle2(context, color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
                          ? (widget.editMode ? "Guardar cambios" : "Guardar transferencia")
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
