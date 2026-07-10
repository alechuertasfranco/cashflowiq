// lib/features/transactions/presentation/recurring/widgets/recurring_step_details.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

class RecurringStepDetails extends StatelessWidget {
  final String type; // 'INCOME' | 'EXPENSE'
  final bool isFixedAmount;
  final TextEditingController nameController;
  final TextEditingController amountController;
  final String? nameError;
  final String? amountError;
  final void Function(String) onTypeChanged;
  final void Function(bool) onAmountTypeChanged;
  final void Function() onNameChanged;
  final void Function() onAmountChanged;

  const RecurringStepDetails({
    super.key,
    required this.type,
    required this.isFixedAmount,
    required this.nameController,
    required this.amountController,
    this.nameError,
    this.amountError,
    required this.onTypeChanged,
    required this.onAmountTypeChanged,
    required this.onNameChanged,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type toggle
          _label(context, "Tipo"),
          const SizedBox(height: 8),
          _typeToggle(context),
          const SizedBox(height: 20),

          // Name
          AppTextField(
            label: "Nombre",
            controller: nameController,
            hintText: "Ej: Alquiler mensual",
            errorText: nameError,
            onChanged: (_) => onNameChanged(),
          ),
          const SizedBox(height: 20),

          // Amount type toggle
          _label(context, "Tipo de monto"),
          const SizedBox(height: 8),
          _amountTypeToggle(context),

          // Amount (only shown if fixed)
          if (isFixedAmount) ...[
            const SizedBox(height: 20),
            AppTextField(
              label: "Monto",
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hintText: "0.00",
              errorText: amountError,
              onChanged: (_) => onAmountChanged(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) =>
      Text(text, style: context.textSubtitle2(color: context.colorTextSecondary));

  Widget _typeToggle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onTypeChanged('INCOME'),
            child: AnimatedContainer(
              duration: context.motionFast,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: type == 'INCOME' ? context.colorSuccess : context.colorSurface,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(context.radiusMd)),
                border: Border.all(color: context.colorBorder),
              ),
              child: Center(
                child: Text(
                  "Ingreso",
                  style: context.textBody2(
                    color: type == 'INCOME' ? context.colorOnPrimary : context.colorTextSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onTypeChanged('EXPENSE'),
            child: AnimatedContainer(
              duration: context.motionFast,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: type == 'EXPENSE' ? context.colorError : context.colorSurface,
                borderRadius: BorderRadius.horizontal(right: Radius.circular(context.radiusMd)),
                border: Border.all(color: context.colorBorder),
              ),
              child: Center(
                child: Text(
                  "Gasto",
                  style: context.textBody2(
                    color: type == 'EXPENSE' ? context.colorOnPrimary : context.colorTextSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _amountTypeToggle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onAmountTypeChanged(true),
            child: AnimatedContainer(
              duration: context.motionFast,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isFixedAmount ? context.colorPrimary : context.colorSurface,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(context.radiusMd)),
                border: Border.all(color: context.colorBorder),
              ),
              child: Center(
                child: Text(
                  "Monto fijo",
                  style: context.textBody2(
                    color: isFixedAmount ? context.colorOnPrimary : context.colorTextSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onAmountTypeChanged(false),
            child: AnimatedContainer(
              duration: context.motionFast,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !isFixedAmount ? context.colorPrimary : context.colorSurface,
                borderRadius: BorderRadius.horizontal(right: Radius.circular(context.radiusMd)),
                border: Border.all(color: context.colorBorder),
              ),
              child: Center(
                child: Text(
                  "Monto variable",
                  style: context.textBody2(
                    color: !isFixedAmount ? context.colorOnPrimary : context.colorTextSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
