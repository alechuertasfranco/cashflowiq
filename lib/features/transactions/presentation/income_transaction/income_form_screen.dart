// lib/features/transactions/presentation/income_transaction/income_form_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/transactions/data/transaction_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:flutter/material.dart';

class IncomeFormScreen extends StatefulWidget {
  final List<Category> categories;

  const IncomeFormScreen({super.key, required this.categories});

  @override
  State<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends State<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _accountService = BankAccountService();
  final _transactionService = TransactionService();

  List<BankAccount> _accounts = [];
  bool _isLoadingAccounts = true;

  Category? _selectedCategory;
  BankAccount? _selectedAccount;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  bool _isFixed = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountService.getAccounts();
      setState(() {
        _accounts = accounts;
        _isLoadingAccounts = false;
      });
    } catch (_) {
      setState(() => _isLoadingAccounts = false);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una cuenta destino")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _transactionService.createTransaction(
        Transaction(
          id: '',
          type: TransactionType.income,
          amount: double.parse(_amountController.text.trim()),
          date: _selectedDate,
          categoryId: _selectedCategory!.id,
          accountId: _selectedAccount!.id,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          isRecurring: _isRecurring,
          isFixed: _isFixed,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("createTransaction error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al registrar el ingreso")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<Category> get _flatCategories {
    final result = <Category>[];
    for (final cat in widget.categories) {
      result.add(cat);
      result.addAll(cat.children);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAccounts) {
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
                            Text(
                              "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}",
                              style: AppTextStyles.subtitle2(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _label("Categoría"),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Category>(
                      initialValue: _selectedCategory,
                      items: _flatCategories.map((cat) {
                        return DropdownMenuItem<Category>(
                          value: cat,
                          child: Text(cat.name, style: AppTextStyles.body1(context)),
                        );
                      }).toList(),
                      onChanged: (cat) => setState(() => _selectedCategory = cat),
                      decoration: inputDecoration(context, "Selecciona una categoría"),
                      validator: (v) => v == null ? "Selecciona una categoría" : null,
                    ),
                    const SizedBox(height: 16),

                    _label("Cuenta destino"),
                    const SizedBox(height: 8),
                    _accounts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              "No tienes cuentas bancarias registradas",
                              style: AppTextStyles.body2(context, color: AppColors.muted),
                            ),
                          )
                        : DropdownButtonFormField<BankAccount>(
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
                          ),
                    const SizedBox(height: 16),

                    _label("Descripción (opcional)"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: inputDecoration(context, "Ej: Pago de cliente"),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    _toggleRow(
                      "¿Es recurrente?",
                      _isRecurring,
                      (v) => setState(() => _isRecurring = v),
                    ),
                    const SizedBox(height: 4),
                    _toggleRow(
                      "¿Es fijo?",
                      _isFixed,
                      (v) => setState(() => _isFixed = v),
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
                    backgroundColor: AppColors.primary,
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
                          "Registrar ingreso",
                          style: AppTextStyles.subtitle2(context, color: Colors.white),
                        ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancelar",
                    style: AppTextStyles.subtitle2(context, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String text) =>
      Text(text, style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary));

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body1(context)),
        Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
      ],
    );
  }
}
