// lib/features/transactions/presentation/recurring/widgets/recurring_step_details.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
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
          _label(context, "Nombre"),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            onChanged: (_) => onNameChanged(),
            decoration: inputDecoration(context, "Ej: Alquiler mensual").copyWith(
              errorText: nameError,
            ),
          ),
          const SizedBox(height: 20),

          // Amount type toggle
          _label(context, "Tipo de monto"),
          const SizedBox(height: 8),
          _amountTypeToggle(context),

          // Amount (only shown if fixed)
          if (isFixedAmount) ...[
            const SizedBox(height: 20),
            _label(context, "Monto"),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => onAmountChanged(),
              decoration: inputDecoration(context, "0.00").copyWith(
                errorText: amountError,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) =>
      Text(text, style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary));

  Widget _typeToggle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onTypeChanged('INCOME'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: type == 'INCOME' ? AppColors.success : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Ingreso",
                  style: AppTextStyles.body2(
                    context,
                    color: type == 'INCOME' ? Colors.white : AppColors.textSecondary,
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
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: type == 'EXPENSE' ? AppColors.error : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Gasto",
                  style: AppTextStyles.body2(
                    context,
                    color: type == 'EXPENSE' ? Colors.white : AppColors.textSecondary,
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
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isFixedAmount ? AppColors.primary : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Monto fijo",
                  style: AppTextStyles.body2(
                    context,
                    color: isFixedAmount ? Colors.white : AppColors.textSecondary,
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
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !isFixedAmount ? AppColors.primary : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Monto variable",
                  style: AppTextStyles.body2(
                    context,
                    color: !isFixedAmount ? Colors.white : AppColors.textSecondary,
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
