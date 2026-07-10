// lib/features/transactions/presentation/recurring/recurring_execution_form_screen.dart
// Screen shown when a variable-amount recurring notification is tapped.
// User enters the amount and confirms to register the transaction.

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/services/notification_service.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:cashflowiq/features/transactions/data/recurring_transaction_service.dart';
import 'package:cashflowiq/shared/models/recurring_transaction.dart';
import 'package:flutter/material.dart';

class RecurringExecutionFormScreen extends StatefulWidget {
  final RecurringTransaction rule;
  const RecurringExecutionFormScreen({super.key, required this.rule});

  @override
  State<RecurringExecutionFormScreen> createState() =>
      _RecurringExecutionFormScreenState();
}

class _RecurringExecutionFormScreenState
    extends State<RecurringExecutionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  final _service = RecurringTransactionService();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final rule = widget.rule;
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final payload = <String, dynamic>{
        'type': rule.type,
        'amount': amount,
        'description': rule.name,
        'date': rule.nextExecutionDate.toIso8601String(),
        'category_id': rule.categoryId,
        'currency_id': rule.currencyId,
        'is_recurring': true,
        'is_fixed': false,
        'recurring_transaction_id': rule.id,
        if (rule.type == 'INCOME') 'to_account_id': rule.accountId,
        if (rule.type == 'EXPENSE' && rule.creditCardId != null)
          'credit_card_id': rule.creditCardId,
        if (rule.type == 'EXPENSE' && rule.creditCardId == null)
          'account_id': rule.accountId,
      };
      await ApiClient.post('/transactions', body: payload);
      final updated = await _service.advance(rule.id);
      await NotificationService.instance.scheduleRecurringNotification(updated);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error registering recurring transaction: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar la transacción')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    final isIncome = rule.type == 'INCOME';
    final typeColor = isIncome ? context.colorSuccess : context.colorError;

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: const AppHeaderBar(title: 'Registrar transacción'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rule info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colorSurface,
                    borderRadius: context.radiusLgRadius,
                    border: Border.all(color: context.colorBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withAlpha(25),
                          borderRadius: context.radiusMdRadius,
                        ),
                        child: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: typeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rule.name, style: context.heading6()),
                            if (rule.categoryName != null)
                              Text(
                                rule.categoryName!,
                                style: context.textCaption(
                                  color: context.colorTextSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Monto',
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  hintText: '0.00',
                  prefixText:
                      rule.currencySymbol != null ? '${rule.currencySymbol} ' : null,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa el monto';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) {
                      return 'Monto inválido';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Registrar',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
