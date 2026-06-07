// lib/features/transactions/presentation/transfer_transaction/transfer_form_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:cashflowiq/features/transactions/data/transaction_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:flutter/material.dart';

class TransferFormScreen extends StatefulWidget {
  final List<BankAccount> accounts;

  const TransferFormScreen({super.key, required this.accounts});

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _transactionService = TransactionService();

  BankAccount? _fromAccount;
  BankAccount? _toAccount;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

    if (_fromAccount == null || _toAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona las cuentas de origen y destino")),
      );
      return;
    }
    if (_fromAccount!.id == _toAccount!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las cuentas de origen y destino deben ser diferentes")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _transactionService.createTransaction(
        Transaction(
          id: '',
          type: TransactionType.transfer,
          amount: double.parse(_amountController.text.trim()),
          date: _selectedDate,
          accountId: _fromAccount!.id,
          toAccountId: _toAccount!.id,
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
        const SnackBar(content: Text("Error al registrar la transferencia")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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

                    _label("Cuenta origen"),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BankAccount>(
                      initialValue: _fromAccount,
                      items: widget.accounts.map((acc) {
                        return DropdownMenuItem<BankAccount>(
                          value: acc,
                          child: Text(acc.name, style: AppTextStyles.body1(context)),
                        );
                      }).toList(),
                      onChanged: (acc) => setState(() => _fromAccount = acc),
                      decoration: inputDecoration(context, "Selecciona la cuenta de origen"),
                      validator: (v) => v == null ? "Selecciona la cuenta de origen" : null,
                    ),
                    const SizedBox(height: 16),

                    _label("Cuenta destino"),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BankAccount>(
                      initialValue: _toAccount,
                      items: widget.accounts.map((acc) {
                        return DropdownMenuItem<BankAccount>(
                          value: acc,
                          child: Text(acc.name, style: AppTextStyles.body1(context)),
                        );
                      }).toList(),
                      onChanged: (acc) => setState(() => _toAccount = acc),
                      decoration: inputDecoration(context, "Selecciona la cuenta de destino"),
                      validator: (v) => v == null ? "Selecciona la cuenta de destino" : null,
                    ),
                    const SizedBox(height: 16),

                    _label("Descripción (opcional)"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: inputDecoration(context, "Ej: Ahorro mensual"),
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
                          "Registrar transferencia",
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
}
