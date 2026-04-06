// lib/features/bank_accounts/presentation/form_account_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/currency_dropdown.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/presentation/controllers/form_account_controller.dart';
import 'package:cashflowiq/features/profile/data/bank_entity_service.dart';
import 'package:cashflowiq/features/profile/presentation/bank_entities/bank_entities_screen.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';
import 'package:flutter/material.dart';

class FormAccountScreen extends StatefulWidget {
  final BankAccount? account;

  const FormAccountScreen({super.key, this.account});

  @override
  State<FormAccountScreen> createState() => _FormAccountScreenState();
}

class _FormAccountScreenState extends State<FormAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  late final FormAccountController controller;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();

    controller = FormAccountController(BankAccountService(), BankEntityService(), CurrencyService());
    controller.addListener(() => setState(() {}));
    controller.init(widget.account);

    if (_isEdit) {
      final acc = widget.account!;
      _nameController.text = acc.name;
      _amountController.text = acc.balance.amount.toString();
    }
  }

  @override
  void dispose() {
    controller.removeListener(() => setState(() {}));
    controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (controller.selectedCurrency == null || controller.selectedEntity == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa todos los campos")));
      return;
    }

    try {
      await controller.submit(
        name: _nameController.text.trim(),
        amount: _amountController.text,

        original: widget.account,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error guardando cuenta: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error guardando cuenta")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? "Editar cuenta" : "Nueva cuenta", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: controller.isLoading
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
                              _label("Nombre de la cuenta"),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                decoration: inputDecoration(context, "Ej: BCP Ahorros"),
                                validator: (value) => value == null || value.isEmpty ? "Ingresa un nombre" : null,
                              ),
                              const SizedBox(height: 12),

                              _label("Balance inicial"),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: inputDecoration(context, "0.00"),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Ingresa un monto";
                                  }
                                  if (double.tryParse(value) == null) {
                                    return "Monto inválido";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              _label("Moneda"),
                              const SizedBox(height: 8),
                              CurrencyDropdown(
                                currencies: controller.currencies,
                                value: controller.selectedCurrency,
                                onChanged: controller.setCurrency,
                              ),
                              const SizedBox(height: 12),

                              _label("Entidad bancaria"),
                              const SizedBox(height: 8),
                              DropdownButtonFormField(
                                initialValue: controller.selectedEntity,
                                items: controller.entities.map((e) {
                                  return DropdownMenuItem(
                                    value: e,
                                    child: Text(e.name, style: AppTextStyles.body1(context)),
                                  );
                                }).toList(),
                                onChanged: controller.setEntity,
                                decoration: inputDecoration(context, "Selecciona una entidad bancaria"),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () async {
                                    final created = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const BankEntitiesScreen()),
                                    );

                                    if (created == true) {
                                      await controller.init(widget.account);
                                    }
                                  },
                                  child: Text(
                                    "Crear nueva entidad",
                                    style: AppTextStyles.caption(context, color: AppColors.primary),
                                  ),
                                ),
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
                            onPressed: controller.isSaving ? null : _submit,
                            child: controller.isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    _isEdit ? "Actualizar cuenta" : "Crear cuenta",
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
                            child: Text("Cancelar", style: AppTextStyles.subtitle2(context, color: AppColors.primary)),
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

  Widget _label(String text) => Text(text, style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary));
}
