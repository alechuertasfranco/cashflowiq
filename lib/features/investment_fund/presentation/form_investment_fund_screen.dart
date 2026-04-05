// lib/features/investment_fund/presentation/form_investment_fund_screen.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:cashflowiq/core/widgets/currency_dropdown.dart';

import 'package:cashflowiq/features/investment_fund/presentation/controllers/form_investment_fund_controller.dart';
import 'package:cashflowiq/features/investment_fund/data/investment_fund_service.dart';

import 'package:cashflowiq/features/bank_entities/data/bank_entity_service.dart';
import 'package:cashflowiq/features/bank_entities/presentation/bank_entities_screen.dart';

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

  late final FormInvestmentFundController controller;

  bool get _isEdit => widget.fund != null;

  @override
  void initState() {
    super.initState();

    controller = FormInvestmentFundController(InvestmentFundService(), BankEntityService(), CurrencyService());
    controller.addListener(() => setState(() {}));
    controller.init(widget.fund);

    if (_isEdit) {
      final f = widget.fund!;
      _nameController.text = f.name;
      _amountController.text = f.investedAmount.toString();
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? "Editar inversión" : "Nueva inversión", style: AppTextStyles.h400(context)),
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
                              _label("Nombre del fondo"),
                              const SizedBox(height: 8),
                              _input("Ej: Vanguard S&P 500", _nameController),

                              _label("Capital invertido"),
                              const SizedBox(height: 8),
                              _input("Ej: 10000.00", _amountController, isNumber: true),

                              _label("Tipo de fondo"),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<InvestmentFundType>(
                                initialValue: controller.selectedType,
                                items: InvestmentFundType.values.map((t) {
                                  return DropdownMenuItem(value: t, child: Text(t.toLabel()));
                                }).toList(),
                                onChanged: controller.setType,
                                decoration: inputDecoration("Selecciona tipo"),
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
                                    if (created == true) await controller.init(widget.fund);
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
                      _isEdit ? "Actualizar inversión" : "Crear inversión",
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
