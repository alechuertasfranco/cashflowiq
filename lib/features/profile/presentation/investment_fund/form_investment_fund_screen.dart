// lib/features/investment_fund/presentation/form_investment_fund_screen.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/app_dropdown_field.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:cashflowiq/core/widgets/currency_dropdown.dart';

import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/presentation/controllers/form_investment_fund_controller.dart';
import 'package:cashflowiq/features/profile/data/investment_fund_service.dart';

import 'package:cashflowiq/features/profile/data/bank_entity_service.dart';
import 'package:cashflowiq/features/profile/presentation/bank_entities/bank_entities_screen.dart';

import 'package:cashflowiq/shared/models/investment_fund.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';

class FormInvestmentFundScreen extends StatefulWidget {
  final InvestmentFund? fund;

  const FormInvestmentFundScreen({super.key, this.fund});

  @override
  State<FormInvestmentFundScreen> createState() => _FormInvestmentFundScreenState();
}

class _FormInvestmentFundScreenState extends State<FormInvestmentFundScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _currentValueController = TextEditingController();

  late final FormInvestmentFundController controller;

  bool get _isEdit => widget.fund != null;

  @override
  void initState() {
    super.initState();

    controller = FormInvestmentFundController(
      InvestmentFundService(),
      BankEntityService(),
      CurrencyService(),
      BankAccountService(),
    );
    controller.addListener(() => setState(() {}));
    controller.init(widget.fund);

    if (_isEdit) {
      final f = widget.fund!;
      _nameController.text = f.name;
      _amountController.text = f.investedAmount.toString();
      _currentValueController.text = f.currentValue?.toString() ?? '';
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
        name: _nameController.text,
        investedAmount: _amountController.text,
        currentValue: _currentValueController.text,
        original: widget.fund,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error guardando fondo: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error guardando fondo")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppHeaderBar(title: _isEdit ? "Editar inversión" : "Nueva inversión"),
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
                              _input("Nombre del fondo", "Ej: Vanguard S&P 500", _nameController),

                              _input("Capital invertido", "Ej: 10000.00", _amountController, isNumber: true),

                              _input(
                                "Valor actual (opcional)",
                                "Ej: 11500.00",
                                _currentValueController,
                                isNumber: true,
                                required: false,
                              ),

                              AppDropdownField<InvestmentFundType>(
                                label: "Tipo de fondo",
                                value: controller.selectedType,
                                items: InvestmentFundType.values.map((t) {
                                  return DropdownMenuItem(value: t, child: Text(t.toLabel()));
                                }).toList(),
                                onChanged: controller.setType,
                                hintText: "Selecciona tipo",
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
                                    if (created == true) await controller.init(widget.fund);
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
