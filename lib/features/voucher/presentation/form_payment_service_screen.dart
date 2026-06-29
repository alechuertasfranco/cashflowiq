// lib/features/voucher/presentation/form_payment_service_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/credit_card_service.dart';
import 'package:cashflowiq/features/voucher/data/payment_service_service.dart';
import 'package:cashflowiq/shared/models/payment_service.dart';
import 'package:flutter/material.dart';

class _LinkedItem {
  final String label;
  final int? accountId;
  final int? creditCardId;

  const _LinkedItem({required this.label, this.accountId, this.creditCardId});
}

class FormPaymentServiceScreen extends StatefulWidget {
  final PaymentService? service;

  const FormPaymentServiceScreen({super.key, this.service});

  @override
  State<FormPaymentServiceScreen> createState() => _FormPaymentServiceScreenState();
}

class _FormPaymentServiceScreenState extends State<FormPaymentServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final PaymentServiceService _service = PaymentServiceService();
  final BankAccountService _accountService = BankAccountService();
  final CreditCardService _cardService = CreditCardService();

  bool _isLoading = true;
  bool _isSaving = false;

  String _selectedType = 'generic';
  _LinkedItem? _selectedLinked;
  List<_LinkedItem> _linkedItems = [];

  bool get _isEdit => widget.service != null;

  static const _typeOptions = [
    {'value': 'yape', 'label': 'Yape'},
    {'value': 'plin', 'label': 'Plin'},
    {'value': 'generic', 'label': 'Genérico'},
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final accounts = await _accountService.getAccounts();
      final cards = await _cardService.getCreditCards();

      final items = <_LinkedItem>[
        const _LinkedItem(label: 'Ninguna'),
        ...accounts.map((a) => _LinkedItem(label: 'Cuenta: ${a.name}', accountId: int.tryParse(a.id))),
        ...cards.map((c) => _LinkedItem(label: 'Tarjeta: ${c.name}', creditCardId: int.tryParse(c.id))),
      ];

      if (!mounted) return;
      setState(() {
        _linkedItems = items;
        _isLoading = false;
      });

      if (_isEdit) {
        final s = widget.service!;
        _nameController.text = s.name;
        _selectedType = s.serviceType;

        if (s.accountId != null) {
          _selectedLinked = items.firstWhere(
            (i) => i.accountId == s.accountId,
            orElse: () => items.first,
          );
        } else if (s.creditCardId != null) {
          _selectedLinked = items.firstWhere(
            (i) => i.creditCardId == s.creditCardId,
            orElse: () => items.first,
          );
        } else {
          _selectedLinked = items.first;
        }
        setState(() {});
      } else {
        _selectedLinked = items.first;
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error cargando datos")),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final accountId = _selectedLinked?.accountId;
      final creditCardId = _selectedLinked?.creditCardId;

      if (_isEdit) {
        await _service.updatePaymentService(
          widget.service!.id,
          name: name,
          serviceType: _selectedType,
          accountId: accountId,
          creditCardId: creditCardId,
        );
      } else {
        await _service.createPaymentService(
          name: name,
          serviceType: _selectedType,
          accountId: accountId,
          creditCardId: creditCardId,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error guardando servicio")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEdit ? "Editar servicio" : "Nuevo servicio",
          style: AppTextStyles.h400(context),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("Nombre"),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                decoration: inputDecoration(context, "Ej: Mi Yape personal"),
                                validator: (v) => v == null || v.isEmpty ? "Ingresa un nombre" : null,
                              ),

                              const SizedBox(height: 12),

                              _label("Tipo"),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedType,
                                items: _typeOptions.map((opt) {
                                  return DropdownMenuItem(
                                    value: opt['value'],
                                    child: Text(opt['label']!, style: AppTextStyles.body1(context)),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedType = v ?? 'generic'),
                                decoration: inputDecoration(context, "Selecciona el tipo"),
                              ),

                              const SizedBox(height: 12),

                              _label("Cuenta vinculada"),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<_LinkedItem>(
                                initialValue: _selectedLinked,
                                items: _linkedItems.map((item) {
                                  return DropdownMenuItem(
                                    value: item,
                                    child: Text(item.label, style: AppTextStyles.body1(context)),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedLinked = v),
                                decoration: inputDecoration(context, "Ninguna"),
                              ),
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
                                    "Guardar",
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
              ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary));
}
