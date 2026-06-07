// lib\shared\models\transaction.dart

import 'package:cashflowiq/core/utils/format.dart';

enum TransactionType {
  income,
  expense,
  transfer;

  factory TransactionType.fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INCOME':
        return TransactionType.income;
      case 'EXPENSE':
        return TransactionType.expense;
      case 'TRANSFER':
        return TransactionType.transfer;
      default:
        throw Exception("Unknown transaction type: $value");
    }
  }

  String toApi() => name.toUpperCase();
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String? description;
  final DateTime date;

  final String? categoryId;
  final String? accountId;
  final String? creditCardId;
  final String? toAccountId;

  final bool isRecurring;
  final bool isFixed;

  final String currencyCode;
  final String currencySymbol;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    this.categoryId,
    this.accountId,
    this.creditCardId,
    this.toAccountId,
    this.isRecurring = false,
    this.isFixed = false,
    this.currencyCode = '',
    this.currencySymbol = '',
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      type: TransactionType.fromString(json['type']),
      amount: parseToDouble(json['amount']),
      description: json['description'],
      date: DateTime.parse(json['date']),
      categoryId: json['category_id']?.toString(),
      accountId: json['account_id']?.toString(),
      creditCardId: json['credit_card_id']?.toString(),
      toAccountId: json['to_account_id']?.toString(),
      isRecurring: json['is_recurring'] ?? false,
      isFixed: json['is_fixed'] ?? false,
      currencyCode: json['currency_code'] as String? ?? '',
      currencySymbol: json['currency_symbol'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "type": type.toApi(),
      "amount": amount,
      "description": description,
      "date": date.toIso8601String(),
      "category_id": categoryId,
      "account_id": accountId,
      "credit_card_id": creditCardId,
      "to_account_id": toAccountId,
      "is_recurring": isRecurring,
      "is_fixed": isFixed,
    };
  }
}
