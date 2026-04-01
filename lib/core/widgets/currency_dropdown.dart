// lib\core\widgets\currency_dropdown.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:flutter/material.dart';

class CurrencyDropdown extends StatelessWidget {
  final List<Currency> currencies;
  final Currency? value;
  final Function(Currency?) onChanged;

  const CurrencyDropdown({super.key, required this.currencies, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Currency>(
      initialValue: value,
      dropdownColor: AppColors.surface,
      items: currencies.map((currency) {
        return DropdownMenuItem(
          value: currency,
          child: Text("${currency.flag} ${currency.code}", style: AppTextStyles.body1(context)),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Selecciona moneda",
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
