import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:flutter/material.dart';

class FormStepAmount extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final DateTime selectedDate;
  final String? amountError;
  final String? descriptionError;
  final String title;
  final Color dateAccentColor;
  final String descriptionHint;
  final bool descriptionRequired;
  final VoidCallback onDateTap;
  final VoidCallback onAmountChanged;
  final VoidCallback? onDescriptionChanged;

  const FormStepAmount({
    super.key,
    required this.amountController,
    required this.descriptionController,
    required this.selectedDate,
    required this.onDateTap,
    required this.onAmountChanged,
    this.amountError,
    this.descriptionError,
    this.title = '¿Cuánto fue?',
    this.dateAccentColor = AppColors.error,
    this.descriptionHint = '',
    this.descriptionRequired = false,
    this.onDescriptionChanged,
  });

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return "$d/$m/${date.year}  $h:$min";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h400(context)),
          const SizedBox(height: 24),
          _datePicker(context),
          const SizedBox(height: 24),
          _amountField(context),
          const SizedBox(height: 24),
          _descriptionField(context),
        ],
      ),
    );
  }

  Widget _datePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Fecha y hora",
            style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary)),
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
                Text(_formatDate(selectedDate),
                    style: AppTextStyles.subtitle2(context)),
                const Spacer(),
                Text("Cambiar",
                    style: AppTextStyles.body2(context, color: dateAccentColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _amountField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Monto",
            style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.h300(context),
          decoration: inputDecoration(context, "0.00").copyWith(
            errorText: amountError,
          ),
          onChanged: (_) => onAmountChanged(),
        ),
      ],
    );
  }

  Widget _descriptionField(BuildContext context) {
    final label = descriptionRequired ? "Descripción" : "Descripción (opcional)";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: descriptionController,
          decoration: inputDecoration(context, descriptionHint).copyWith(
            errorText: descriptionError,
          ),
          maxLines: 2,
          onChanged: descriptionRequired || onDescriptionChanged != null
              ? (_) => onDescriptionChanged?.call()
              : null,
        ),
      ],
    );
  }
}
