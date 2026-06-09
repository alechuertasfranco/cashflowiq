// lib/features/transactions/presentation/expense_transaction/expense_form_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/credit_card_service.dart';
import 'package:cashflowiq/features/transactions/data/transaction_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:flutter/material.dart';

enum _PaymentSource { bankAccount, creditCard }

class ExpenseFormScreen extends StatefulWidget {
  final List<Category> categories;

  const ExpenseFormScreen({super.key, required this.categories});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _accountService = BankAccountService();
  final _creditCardService = CreditCardService();
  final _transactionService = TransactionService();

  List<BankAccount> _accounts = [];
  List<CreditCard> _creditCards = [];
  bool _isLoadingSources = true;

  Category? _selectedCategory;
  BankAccount? _selectedAccount;
  CreditCard? _selectedCreditCard;
  _PaymentSource _paymentSource = _PaymentSource.bankAccount;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
      });
    } catch (_) {
      setState(() => _isLoadingSources = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final usingCard = _paymentSource == _PaymentSource.creditCard;
    if (usingCard && _selectedCreditCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una tarjeta de crédito")),
      );
      return;
    }
    if (!usingCard && _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una cuenta de origen")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _transactionService.createTransaction(
        Transaction(
          id: '',
          type: TransactionType.expense,
          amount: double.parse(_amountController.text.trim()),
          date: _selectedDate,
          categoryId: _selectedCategory!.id,
          accountId: usingCard ? null : _selectedAccount!.id,
          creditCardId: usingCard ? _selectedCreditCard!.id : null,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("createTransaction error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al registrar el gasto")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<(Category, String)> get _selectableCategories {
    final result = <(Category, String)>[];
    for (final cat in widget.categories) {
      if (cat.children.isEmpty) {
        result.add((cat, cat.name));
      } else {
        for (final child in cat.children) {
          result.add((child, '${cat.name} › ${child.name}'));
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSources) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _label("Monto"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: inputDecoration(context, "0.00"),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Ingresa un monto";
                        final parsed = double.tryParse(v);
                        if (parsed == null) return "Monto inválido";
                        if (parsed <= 0) return "El monto debe ser mayor a 0";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label("Fecha"),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: AppColors.muted),
                            const SizedBox(width: 8),
                            Text(_formatDate(_selectedDate), style: AppTextStyles.subtitle2(context)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _label("Categoría"),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Category>(
                      initialValue: _selectedCategory,
                      items: _selectableCategories.map((entry) {
                        return DropdownMenuItem<Category>(
                          value: entry.$1,
                          child: Text(entry.$2, style: AppTextStyles.body1(context)),
                        );
                      }).toList(),
                      onChanged: (cat) => setState(() => _selectedCategory = cat),
                      decoration: inputDecoration(context, "Selecciona una categoría"),
                      validator: (v) => v == null ? "Selecciona una categoría" : null,
                    ),
                    const SizedBox(height: 16),

                    _label("Fuente de pago"),
                    const SizedBox(height: 8),
                    _paymentSourceToggle(),
                    const SizedBox(height: 12),
                    _paymentSourceDropdown(),
                    const SizedBox(height: 16),

                    _label("Descripción (opcional)"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: inputDecoration(context, "Ej: Supermercado"),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),

        Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          "Registrar gasto",
                          style: AppTextStyles.subtitle2(context, color: Colors.white),
                        ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancelar",
                    style: AppTextStyles.subtitle2(context, color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentSourceToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _paymentSource = _PaymentSource.bankAccount;
              _selectedCreditCard = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _paymentSource == _PaymentSource.bankAccount
                    ? AppColors.error
                    : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Cuenta bancaria",
                  style: AppTextStyles.body2(
                    context,
                    color: _paymentSource == _PaymentSource.bankAccount
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _paymentSource = _PaymentSource.creditCard;
              _selectedAccount = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _paymentSource == _PaymentSource.creditCard
                    ? AppColors.error
                    : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Tarjeta de crédito",
                  style: AppTextStyles.body2(
                    context,
                    color: _paymentSource == _PaymentSource.creditCard
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentSourceDropdown() {
    if (_paymentSource == _PaymentSource.bankAccount) {
      if (_accounts.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            "No tienes cuentas bancarias registradas",
            style: AppTextStyles.body2(context, color: AppColors.muted),
          ),
        );
      }
      return DropdownButtonFormField<BankAccount>(
        initialValue: _selectedAccount,
        items: _accounts.map((acc) {
          return DropdownMenuItem<BankAccount>(
            value: acc,
            child: Text(acc.name, style: AppTextStyles.body1(context)),
          );
        }).toList(),
        onChanged: (acc) => setState(() => _selectedAccount = acc),
        decoration: inputDecoration(context, "Selecciona una cuenta"),
        validator: (v) => v == null ? "Selecciona una cuenta" : null,
      );
    }

    if (_creditCards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          "No tienes tarjetas de crédito registradas",
          style: AppTextStyles.body2(context, color: AppColors.muted),
        ),
      );
    }
    return DropdownButtonFormField<CreditCard>(
      initialValue: _selectedCreditCard,
      items: _creditCards.map((card) {
        return DropdownMenuItem<CreditCard>(
          value: card,
          child: Text(card.name, style: AppTextStyles.body1(context)),
        );
      }).toList(),
      onChanged: (card) => setState(() => _selectedCreditCard = card),
      decoration: inputDecoration(context, "Selecciona una tarjeta"),
      validator: (v) => v == null ? "Selecciona una tarjeta" : null,
    );
  }

  Widget _label(String text) =>
      Text(text, style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary));
}
