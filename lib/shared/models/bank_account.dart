// lib/shared/models/bank_account.dart

import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/money.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';

class BankAccount {
  final String id;
  final String name;
  final double initialAmount;
  final Currency currency;

  final BankEntity bankEntity;

  BankAccount({
    required this.id,
    required this.name,
    required this.initialAmount,
    required this.currency,
    required this.bankEntity,
  });

  /// 💰 Fuente única de verdad del balance
  Money get balance => Money(amount: initialAmount, currency: currency);

  /// 🧠 IDENTIDAD DE DOMINIO (CLAVE)
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BankAccount && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// 📦 SERIALIZACIÓN
  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'].toString(),
      name: json['name'],
      initialAmount: (json['initial_amount'] as num).toDouble(),
      currency: Currency.fromJson(json['currency']),
      bankEntity: BankEntity.fromJson(json['bank_entity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "initial_amount": initialAmount,
      "currency": currency.toJson(),
      "bank_entity_id": bankEntity.id,
    };
  }

  /// ✨ OPCIONAL PERO PRO
  BankAccount copyWith({String? name, double? initialAmount, Currency? currency, BankEntity? bankEntity}) {
    return BankAccount(
      id: id,
      name: name ?? this.name,
      initialAmount: initialAmount ?? this.initialAmount,
      currency: currency ?? this.currency,
      bankEntity: bankEntity ?? this.bankEntity,
    );
  }
}
