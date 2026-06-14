// lib/features/splits/screens/widgets/split_step_amount.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:flutter/material.dart';

class SplitStepAmount extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final DateTime selectedDate;
  final String? amountError;
  final String? descriptionError;
  final VoidCallback onDateTap;
  final VoidCallback onAmountChanged;
  final VoidCallback onDescriptionChanged;

  const SplitStepAmount({
    super.key,
    required this.amountController,
    required this.descriptionController,
    required this.selectedDate,
    required this.onDateTap,
    required this.onAmountChanged,
    required this.onDescriptionChanged,
    this.amountError,
    this.descriptionError,
  });

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("¿Cuánto fue en total?", style: AppTextStyles.h400(context)),
          const SizedBox(height: 24),
          TextField(
            controller: amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.h300(context),
            decoration: inputDecoration(context, "0.00").copyWith(errorText: amountError),
            onChanged: (_) => onAmountChanged(),
          ),
          const SizedBox(height: 24),
          Text(
            "Fecha",
            style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.muted),
                  const SizedBox(width: 10),
                  Text(_formatDate(selectedDate), style: AppTextStyles.subtitle2(context)),
                  const Spacer(),
                  Text("Cambiar", style: AppTextStyles.body2(context, color: AppColors.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Descripción",
            style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: descriptionController,
            decoration: inputDecoration(context, "Ej: Cena de cumpleaños").copyWith(
              errorText: descriptionError,
            ),
            maxLines: 2,
            onChanged: (_) => onDescriptionChanged(),
          ),
        ],
      ),
    );
  }
}
