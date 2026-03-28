// lib\shared\models\money.dart

import 'currency.dart';

class Money {
  final double amount;
  final Currency currency;

  const Money({required this.amount, required this.currency});

  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(amount: (json['amount'] as num).toDouble(), currency: json['currency']);
  }

  Map<String, dynamic> toJson() {
    return {"amount": amount, "currency": currency};
  }

  /// ✅ Formateo centralizado
  String format() {
    return "${currency.symbol} ${amount.toStringAsFixed(currency.decimals)}";
  }

  /// ✅ Suma segura
  Money add(Money other) {
    if (currency.code != other.currency.code) {
      throw Exception("Cannot add different currencies");
    }

    return Money(amount: amount + other.amount, currency: currency);
  }

  /// ✅ Resta segura
  Money subtract(Money other) {
    if (currency.code != other.currency.code) {
      throw Exception("Cannot subtract different currencies");
    }

    return Money(amount: amount - other.amount, currency: currency);
  }
}
