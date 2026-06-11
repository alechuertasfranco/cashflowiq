// lib/shared/models/recurring_transaction.dart

import 'package:cashflowiq/core/utils/format.dart';

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  factory RecurringFrequency.fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DAILY':
        return RecurringFrequency.daily;
      case 'WEEKLY':
        return RecurringFrequency.weekly;
      case 'MONTHLY':
        return RecurringFrequency.monthly;
      case 'YEARLY':
        return RecurringFrequency.yearly;
      default:
        throw Exception("Unknown frequency: $value");
    }
  }

  String toApi() => name.toUpperCase();

  String toLabel() {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Diaria';
      case RecurringFrequency.weekly:
        return 'Semanal';
      case RecurringFrequency.monthly:
        return 'Mensual';
      case RecurringFrequency.yearly:
        return 'Anual';
    }
  }
}

class RecurringTransaction {
  final int id;
  final String name;
  final double? amount;
  final String type; // INCOME | EXPENSE
  final RecurringFrequency frequency;
  final DateTime nextExecutionDate;
  final DateTime? endDate;
  final bool isActive;
  final int? categoryId;
  final String? categoryName;
  final int? accountId;
  final int? creditCardId;
  final int? currencyId;
  final String? currencyCode;
  final String? currencySymbol;
  final int? notificationDaysBefore;

  /// True only when an actual transaction backs the current period
  /// (computed server-side; not inferred from the next execution date).
  final bool currentPeriodRegistered;

  RecurringTransaction({
    required this.id,
    required this.name,
    this.amount,
    required this.type,
    required this.frequency,
    required this.nextExecutionDate,
    this.endDate,
    this.isActive = true,
    this.categoryId,
    this.categoryName,
    this.accountId,
    this.creditCardId,
    this.currencyId,
    this.currencyCode,
    this.currencySymbol,
    this.notificationDaysBefore,
    this.currentPeriodRegistered = false,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: parseToInt(json['id']),
      name: json['name'] ?? '',
      amount: json['amount'] != null ? parseToDouble(json['amount']) : null,
      type: json['type'] ?? 'INCOME',
      frequency: RecurringFrequency.fromString(json['frequency'] ?? 'MONTHLY'),
      nextExecutionDate: DateTime.parse(json['next_execution_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      categoryId: json['category_id'] != null ? parseToInt(json['category_id']) : null,
      categoryName: json['category'] != null ? (json['category']['name'] as String?) : null,
      accountId: json['account_id'] != null ? parseToInt(json['account_id']) : null,
      creditCardId: json['credit_card_id'] != null ? parseToInt(json['credit_card_id']) : null,
      currencyId: json['currency_id'] != null ? parseToInt(json['currency_id']) : null,
      currencyCode: json['currency_code'] as String?,
      currencySymbol: json['currency_symbol'] as String?,
      notificationDaysBefore: json['notification_days_before'] as int?,
      currentPeriodRegistered: json['current_period_registered'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (amount != null) 'amount': amount,
      'type': type,
      'frequency': frequency.toApi(),
      'next_execution_date': nextExecutionDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String().split('T').first,
      'is_active': isActive,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (creditCardId != null) 'credit_card_id': creditCardId,
      if (currencyId != null) 'currency_id': currencyId,
      if (notificationDaysBefore != null)
        'notification_days_before': notificationDaysBefore,
    };
  }
}
