// lib/shared/models/bank_account.dart

import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/money.dart';

class BankAccount {
  final String id;
  final String name;
  final double initialAmount;
  final Currency currency;

  BankAccount({required this.id, required this.name, required this.initialAmount, required this.currency});

  /// 💰 SIEMPRE consistente
  Money get balance => Money(amount: initialAmount, currency: currency);

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'].toString(),
      name: json['name'],
      initialAmount: (json['initial_amount'] as num).toDouble(),
      currency: Currency.fromJson(json['currency']),
    );
  }

  Map<String, dynamic> toJson() {
    return {"name": name, "initial_amount": initialAmount, "currency": currency.toJson()};
  }
}
