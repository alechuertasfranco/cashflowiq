import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:flutter/material.dart';

class FormStepAmount extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final DateTime selectedDate;
  final String? amountError;
  final String? descriptionError;
  final String title;
  final Color? dateAccentColor;
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
    this.dateAccentColor,
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
    final resolvedDateAccentColor = dateAccentColor ?? context.colorError;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.heading4()),
          const SizedBox(height: 24),
          _datePicker(context, resolvedDateAccentColor),
          const SizedBox(height: 24),
          _amountField(context),
          const SizedBox(height: 24),
          _descriptionField(context),
        ],
      ),
    );
  }

  Widget _datePicker(BuildContext context, Color dateAccentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Fecha y hora",
            style: context.textSubtitle2(color: context.colorTextSecondary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onDateTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.colorSurface,
              borderRadius: context.radiusMdRadius,
              border: Border.all(color: context.colorBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: context.colorMuted),
                const SizedBox(width: 10),
                Text(_formatDate(selectedDate),
                    style: context.textSubtitle2()),
                const Spacer(),
                Text("Cambiar",
                    style: context.textBody2(color: dateAccentColor)),
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
            style: context.textSubtitle2(color: context.colorTextSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: context.heading3(),
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
    return AppTextField(
      label: label,
      controller: descriptionController,
      hintText: descriptionHint,
      errorText: descriptionError,
      maxLines: 2,
      onChanged: descriptionRequired || onDescriptionChanged != null
          ? (_) => onDescriptionChanged?.call()
          : null,
    );
  }
}
