import 'package:cashflowiq/core/widgets/currency_dropdown.dart';
import 'package:cashflowiq/features/profile/presentation/controllers/form_budget_controller.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';

import 'package:cashflowiq/shared/models/category.dart';

import 'package:cashflowiq/shared/services/currency_service.dart';
import 'package:cashflowiq/features/profile/data/budget_service.dart';

class FormBudgetScreen extends StatefulWidget {
  final Category category;

  const FormBudgetScreen({super.key, required this.category});

  @override
  State<FormBudgetScreen> createState() => _FormBudgetScreenState();
}

class _FormBudgetScreenState extends State<FormBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();

  late FormBudgetController controller;

  @override
  void initState() {
    super.initState();

    controller = FormBudgetController(BudgetService(), CurrencyService());

    controller.init(widget.category.budget);

    if (widget.category.budget != null) {
      amountController.text = widget.category.budget!.amount.toString();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final value = double.tryParse(amountController.text);
    if (value == null) return;

    await controller.submit(amount: value, categoryId: widget.category.id, original: widget.category.budget);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Definir presupuesto", style: AppTextStyles.subtitle1(context)),

                  const SizedBox(height: 16),

                  /// 💰 MONTO
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: inputDecoration(context, "Ej: 500"),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Ingrese un monto";
                      if (double.tryParse(value) == null) return "Monto inválido";
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  /// 💱 MONEDA
                  CurrencyDropdown(
                    currencies: controller.currencies,
                    value: controller.selectedCurrency,
                    onChanged: controller.setCurrency,
                  ),

                  const SizedBox(height: 20),

                  /// 🚀 BOTÓN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: controller.isSaving ? null : _submit,
                      child: controller.isSaving
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : Text("Guardar", style: AppTextStyles.subtitle2(context, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
