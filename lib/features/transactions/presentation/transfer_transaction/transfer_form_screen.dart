// lib/features/transactions/presentation/transfer_transaction/transfer_form_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:cashflowiq/features/profile/data/credit_card_service.dart';
import 'package:cashflowiq/features/transactions/data/transaction_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:flutter/material.dart';

class TransferFormScreen extends StatefulWidget {
  final List<BankAccount> accounts;
  final Transaction? prefill;
  final bool editMode;

  const TransferFormScreen({super.key, required this.accounts, this.prefill, this.editMode = false});

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _transactionService = TransactionService();
  final _creditCardService = CreditCardService();

  BankAccount? _fromAccount;
  BankAccount? _toAccount;
  bool _toCard = false;
  String? _toCreditCardId;
  List<CreditCard> _creditCards = [];
  bool _isLoadingCards = true;

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      final p = widget.prefill!;
      final a = p.amount;
      _amountController.text = a % 1 == 0 ? a.toInt().toString() : a.toString();
      _descriptionController.text = p.description ?? '';
      _selectedDate = p.date;
      _fromAccount = widget.accounts.where((a) => a.id == p.accountId).firstOrNull;
      if (p.toCreditCardId != null) {
        _toCard = true;
        // _toCreditCardId is set after credit cards load in _load()
      } else if (p.toAccountId != null) {
        _toAccount = widget.accounts.where((a) => a.id == p.toAccountId).firstOrNull;
      }
    }
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cards = await _creditCardService.getCreditCards();
      setState(() {
        _creditCards = cards;
        _isLoadingCards = false;
        if (widget.prefill?.toCreditCardId != null) {
          _toCreditCardId = widget.prefill!.toCreditCardId;
        }
      });
    } catch (_) {
      setState(() => _isLoadingCards = false);
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

    if (_fromAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona la cuenta de origen")),
      );
      return;
    }

    if (_toCard) {
      if (_toCreditCardId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona una tarjeta de crédito de destino")),
        );
        return;
      }
    } else {
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
    }

    setState(() => _isSaving = true);

    final tx = Transaction(
      id: widget.editMode ? widget.prefill!.id : '',
      type: TransactionType.transfer,
      amount: double.parse(_amountController.text.trim()),
      date: _selectedDate,
      accountId: _fromAccount!.id,
      toAccountId: _toCard ? null : _toAccount!.id,
      toCreditCardId: _toCard ? _toCreditCardId : null,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCards) {
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

                    _label("Cuenta origen"),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BankAccount>(
                      initialValue: _fromAccount,
                      items: widget.accounts.map((acc) {
                        return DropdownMenuItem<BankAccount>(
                          value: acc,
                          child: Text("${acc.bankEntity.code} · ${acc.name}", style: AppTextStyles.body1(context)),
                        );
                      }).toList(),
                      onChanged: (acc) => setState(() => _fromAccount = acc),
                      decoration: inputDecoration(context, "Selecciona la cuenta de origen"),
                      validator: (v) => v == null ? "Selecciona la cuenta de origen" : null,
                    ),
                    const SizedBox(height: 16),

                    _label("Destino"),
                    const SizedBox(height: 8),
                    _destinationToggle(),
                    const SizedBox(height: 12),
                    _destinationDropdown(),
                    const SizedBox(height: 16),

                    _label("Descripción (opcional)"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: inputDecoration(context, "Ej: Pago de tarjeta"),
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
                          widget.editMode ? "Guardar cambios" : "Registrar transferencia",
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

  Widget _destinationToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _toCard = false;
              _toCreditCardId = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !_toCard ? AppColors.primary : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Cuenta bancaria",
                  style: AppTextStyles.body2(
                    context,
                    color: !_toCard ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _toCard = true;
              _toAccount = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _toCard ? AppColors.primary : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Tarjeta de crédito",
                  style: AppTextStyles.body2(
                    context,
                    color: _toCard ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _destinationDropdown() {
    if (!_toCard) {
      if (widget.accounts.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            "No tienes cuentas bancarias registradas",
            style: AppTextStyles.body2(context, color: AppColors.muted),
          ),
        );
      }
      return DropdownButtonFormField<BankAccount>(
        initialValue: _toAccount,
        items: widget.accounts.map((acc) {
          return DropdownMenuItem<BankAccount>(
            value: acc,
            child: Text("${acc.bankEntity.code} · ${acc.name}", style: AppTextStyles.body1(context)),
          );
        }).toList(),
        onChanged: (acc) => setState(() => _toAccount = acc),
        decoration: inputDecoration(context, "Selecciona la cuenta de destino"),
        validator: (v) => v == null ? "Selecciona la cuenta de destino" : null,
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
    return DropdownButtonFormField<String>(
      initialValue: _toCreditCardId,
      items: _creditCards.map((card) {
        return DropdownMenuItem<String>(
          value: card.id,
          child: Text("${card.bankEntity.code} · ${card.name}", style: AppTextStyles.body1(context)),
        );
      }).toList(),
      onChanged: (id) => setState(() => _toCreditCardId = id),
      decoration: inputDecoration(context, "Selecciona una tarjeta"),
      validator: (v) => v == null ? "Selecciona una tarjeta" : null,
    );
  }

  Widget _label(String text) =>
      Text(text, style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary));
}
