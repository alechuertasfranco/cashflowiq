// lib\core\widgets\currency_dropdown.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
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
      dropdownColor: context.colorSurface,
      items: currencies.map((currency) {
        return DropdownMenuItem(
          value: currency,
          child: Text("${currency.flag} ${currency.code}", style: context.textBody1()),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Selecciona moneda",
        filled: true,
        fillColor: context.colorSurface,
        border: OutlineInputBorder(
          borderRadius: context.radiusMdRadius,
          borderSide: BorderSide(color: context.colorBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: context.radiusMdRadius,
          borderSide: BorderSide(color: context.colorBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: context.radiusMdRadius,
          borderSide: BorderSide(color: context.colorPrimary, width: 1.5),
        ),
      ),
    );
  }
}
