// lib/features/credit_cards/presentation/form_credit_card_screen.dart

import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/app_dropdown_field.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/currency_dropdown.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/presentation/controllers/form_credit_card_controller.dart';
import 'package:cashflowiq/features/profile/data/credit_card_service.dart';
import 'package:cashflowiq/features/profile/data/bank_entity_service.dart';
import 'package:cashflowiq/features/profile/presentation/bank_entities/bank_entities_screen.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';

class FormCreditCardScreen extends StatefulWidget {
  final CreditCard? card;

  const FormCreditCardScreen({super.key, this.card});

  @override
  State<FormCreditCardScreen> createState() => _FormCreditCardScreenState();
}

class _FormCreditCardScreenState extends State<FormCreditCardScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  final _closingController = TextEditingController();
  final _dueController = TextEditingController();
  final _interestController = TextEditingController();

  late final FormCreditCardController controller;

  bool get _isEdit => widget.card != null;

  @override
  void initState() {
    super.initState();

    controller = FormCreditCardController(
      CreditCardService(),
      BankEntityService(),
      CurrencyService(),
      BankAccountService(),
    );
    controller.addListener(() => setState(() {}));
    controller.init(widget.card);

    if (_isEdit) {
      final c = widget.card!;
      _nameController.text = c.name;
      _limitController.text = c.creditLimit.toString();
      _closingController.text = c.closingDay.toString();
      _dueController.text = c.dueDay.toString();
      _interestController.text = c.interestRate?.toString() ?? '';
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

    if (controller.selectedCurrency == null || controller.selectedEntity == null || controller.selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa todos los campos")));
      return;
    }

    try {
      await controller.submit(
        name: _nameController.text,
        creditLimit: _limitController.text,
        closingDay: int.parse(_closingController.text),
        dueDay: int.parse(_dueController.text),
        interestRate: _interestController.text,
        original: widget.card,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error guardando tarjeta: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error guardando tarjeta")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppHeaderBar(title: _isEdit ? "Editar tarjeta" : "Nueva tarjeta"),
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
                              _input("Nombre de la tarjeta", "Ej: Visa Platinum", _nameController),

                              _input("Línea de crédito", "Ej: 5000.00", _limitController, isNumber: true),

                              _label("Fechas de cierre y pago"),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _closingController,
                                      hintText: "Día de cierre",
                                      keyboardType: TextInputType.number,
                                      validator: (v) => _numberValidator(v, required: true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppTextField(
                                      controller: _dueController,
                                      hintText: "Día de pago",
                                      keyboardType: TextInputType.number,
                                      validator: (v) => _numberValidator(v, required: true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _input(
                                "Tasa de interés (%)",
                                "Ej: 18.5",
                                _interestController,
                                isNumber: true,
                                required: false,
                              ),

                              AppDropdownField<CreditCardBrand>(
                                label: "Red de pago",
                                value: controller.selectedBrand,
                                items: CreditCardBrand.values.map((b) {
                                  return DropdownMenuItem(value: b, child: Text(b.name.toUpperCase()));
                                }).toList(),
                                onChanged: controller.setBrand,
                                hintText: "Selecciona una red de pago",
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
                                    if (created == true) await controller.init(widget.card);
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

                  _actions(),
                ],
              ),
      ),
    );
  }

  Widget _actions() {
    return Container(
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
            label: _isEdit ? "Actualizar inversión" : "Crear inversión",
            isLoading: controller.isSaving,
            onPressed: _submit,
          ),
          SecondaryButton(
            label: "Cancelar",
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: context.textSubtitle2(color: context.colorTextSecondary));

  String? _numberValidator(String? v, {required bool required}) {
    if (!required && (v == null || v.isEmpty)) return null;
    if (v == null || v.isEmpty) return "Requerido";
    if (double.tryParse(v) == null) return "Número inválido";
    return null;
  }

  Widget _input(String label, String hint, TextEditingController controller, {bool isNumber = false, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppTextField(
        label: label,
        controller: controller,
        hintText: hint,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (v) {
          if (!required) return null;
          if (v == null || v.isEmpty) return "Requerido";
          if (isNumber && double.tryParse(v) == null) return "Número inválido";
          return null;
        },
      ),
    );
  }
}
