// lib/features/credit_cards/presentation/form_credit_card_screen.dart

import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/currency_dropdown.dart';
import 'package:cashflowiq/features/credit_cards/presentation/controllers/form_credit_card_controller.dart';
import 'package:cashflowiq/features/credit_cards/data/credit_card_service.dart';
import 'package:cashflowiq/features/bank_entities/data/bank_entity_service.dart';
import 'package:cashflowiq/features/bank_entities/presentation/bank_entities_screen.dart';
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

    controller = FormCreditCardController(CreditCardService(), BankEntityService(), CurrencyService());
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? "Editar tarjeta" : "Nueva tarjeta", style: AppTextStyles.h400(context)),
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
                              _label("Nombre de la tarjeta"),
                              const SizedBox(height: 8),
                              _input("Ej: Visa Platinum", _nameController),

                              _label("Línea de crédito"),
                              const SizedBox(height: 8),
                              _input("Ej: 5000.00", _limitController, isNumber: true),

                              _label("Fechas de cierre y pago"),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: _input("Día de cierre", _closingController, isNumber: true)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _input("Día de pago", _dueController, isNumber: true)),
                                ],
                              ),

                              _label("Tasa de interés (%)"),
                              const SizedBox(height: 8),
                              _input("Ej: 18.5", _interestController, isNumber: true, required: false),

                              _label("Red de pago"),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<CreditCardBrand>(
                                initialValue: controller.selectedBrand,
                                items: CreditCardBrand.values.map((b) {
                                  return DropdownMenuItem(value: b, child: Text(b.name.toUpperCase()));
                                }).toList(),
                                onChanged: controller.setBrand,
                                decoration: inputDecoration("Selecciona una red de pago"),
                              ),

                              const SizedBox(height: 8),

                              _label("Moneda"),
                              const SizedBox(height: 8),
                              CurrencyDropdown(
                                currencies: controller.currencies,
                                value: controller.selectedCurrency,
                                onChanged: controller.setCurrency,
                              ),

                              const SizedBox(height: 8),

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
                                decoration: inputDecoration("Selecciona una entidad bancaria"),
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
                                      await controller.init(widget.card);
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
                                    _isEdit ? "Actualizar tarjeta" : "Crear tarjeta",
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

  Widget _input(String label, TextEditingController controller, {bool isNumber = false, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: inputDecoration(label),
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
