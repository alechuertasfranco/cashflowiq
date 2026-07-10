// lib/features/bank_accounts/presentation/form_account_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/app_dropdown_field.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:cashflowiq/core/widgets/currency_dropdown.dart';
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
      backgroundColor: context.colorBackground,
      appBar: AppHeaderBar(title: _isEdit ? "Editar cuenta" : "Nueva cuenta"),
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
                              AppTextField(
                                label: "Nombre de la cuenta",
                                controller: _nameController,
                                hintText: "Ej: BCP Ahorros",
                                validator: (value) => value == null || value.isEmpty ? "Ingresa un nombre" : null,
                              ),
                              const SizedBox(height: 12),

                              AppTextField(
                                label: "Balance inicial",
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                hintText: "0.00",
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

                              AppDropdownField(
                                label: "Entidad bancaria",
                                value: controller.selectedEntity,
                                items: controller.entities.map((e) {
                                  return DropdownMenuItem(
                                    value: e,
                                    child: Text(e.name, style: context.textBody1()),
                                  );
                                }).toList(),
                                onChanged: controller.setEntity,
                                hintText: "Selecciona una entidad bancaria",
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
                                    style: context.textCaption(color: context.colorPrimary),
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
                      color: context.colorBackground,
                      boxShadow: context.shadowCard,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PrimaryButton(
                          label: _isEdit ? "Actualizar cuenta" : "Crear cuenta",
                          isLoading: controller.isSaving,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 10),
                        SecondaryButton(
                          label: "Cancelar",
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: context.textSubtitle2(color: context.colorTextSecondary));
}
