import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FormStepAmount extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final DateTime selectedDate;
  final String? amountError;
  final String? descriptionError;
  final String title;
  final Color? accentColor;
  final String currencySymbol;
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
    this.accentColor,
    this.currencySymbol = 'S/',
    this.descriptionHint = '',
    this.descriptionRequired = false,
    this.onDescriptionChanged,
  });

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic', //
  ];

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    final day = isToday ? 'Hoy' : '${date.day} ${_months[date.month - 1]}';
    return '$day · $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAccentColor = accentColor ?? context.colorPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.heading4()),
          const SizedBox(height: 28),
          _amountHero(context, resolvedAccentColor),
          const SizedBox(height: 28),
          _DateChip(
            label: _formatDate(selectedDate),
            accentColor: resolvedAccentColor,
            onTap: onDateTap,
          ),
          const SizedBox(height: 20),
          _descriptionField(context),
        ],
      ),
    );
  }

  Widget _amountHero(BuildContext context, Color accentColor) {
    final hasError = amountError != null;
    final borderColor = hasError ? context.colorError : context.colorBorder;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: context.colorSurface,
            borderRadius: context.radiusXlRadius,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  currencySymbol,
                  style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: context.colorMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IntrinsicWidth(
                child: TextField(
                  controller: amountController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: accentColor,
                  style: GoogleFonts.sora(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: context.colorTextPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0',
                    hintStyle: GoogleFonts.sora(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: context.colorMuted.withAlpha(120),
                    ),
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (_) => onAmountChanged(),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 14, color: context.colorError),
              const SizedBox(width: 4),
              Text(amountError!, style: context.textCaption(color: context.colorError)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _descriptionField(BuildContext context) {
    final label = descriptionRequired ? 'Descripción' : 'Descripción (opcional)';
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

class _DateChip extends StatelessWidget {
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _DateChip({required this.label, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: context.radiusLgRadius,
          border: Border.all(color: context.colorBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: accentColor.withAlpha(22), shape: BoxShape.circle),
              child: Icon(Icons.event_rounded, size: 16, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: context.textSubtitle1().copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colorMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
