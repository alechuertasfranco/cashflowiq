// lib/shared/models/credit_card.dart

import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/money.dart';

enum CreditCardBrand {
  visa,
  mastercard,
  amex,
  discover,
  diners;

  factory CreditCardBrand.fromString(String value) {
    switch (value.toUpperCase()) {
      case 'VISA':
        return CreditCardBrand.visa;
      case 'MASTERCARD':
        return CreditCardBrand.mastercard;
      case 'AMEX':
        return CreditCardBrand.amex;
      case 'DISCOVER':
        return CreditCardBrand.discover;
      case 'DINERS':
        return CreditCardBrand.diners;
      default:
        throw Exception('Unknown card brand: $value');
    }
  }

  String toApi() => name.toUpperCase();
}

class CreditCard {
  final String id;
  final String name;

  // 💳 Dominio real
  final double creditLimit;
  final CreditCardBrand brand;
  final int closingDay;
  final int dueDay;
  final double? interestRate;

  final Currency currency;
  final BankEntity bankEntity;

  CreditCard({
    required this.id,
    required this.name,
    required this.creditLimit,
    required this.brand,
    required this.closingDay,
    required this.dueDay,
    this.interestRate,
    required this.currency,
    required this.bankEntity,
  });

  /// 💰 Línea de crédito como Money (no es balance)
  Money get creditLimitMoney => Money(amount: creditLimit, currency: currency);

  /// 🧠 IDENTIDAD DE DOMINIO
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CreditCard && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// 📦 SERIALIZACIÓN (FROM API)
  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      creditLimit: parseToDouble(json['credit_limit']),
      brand: CreditCardBrand.fromString(json['brand']),
      closingDay: parseToInt(json['closing_day']),
      dueDay: parseToInt(json['due_day']),
      interestRate: json['interest_rate'] != null ? parseToDouble(json['interest_rate']) : null,
      currency: Currency.fromMap(json['currency']),
      bankEntity: BankEntity.fromJson(json['bank_entity']),
    );
  }

  /// 📤 SERIALIZACIÓN (TO API)
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "credit_limit": creditLimit,
      "brand": brand.toApi(),
      "closing_day": closingDay,
      "due_day": dueDay,
      "interest_rate": interestRate,
      "currency_id": currency.id,
      "bank_entity_id": bankEntity.id,
    };
  }

  CreditCard copyWith({
    String? name,
    double? creditLimit,
    CreditCardBrand? brand,
    int? closingDay,
    int? dueDay,
    double? interestRate,
    Currency? currency,
    BankEntity? bankEntity,
  }) {
    return CreditCard(
      id: id,
      name: name ?? this.name,
      creditLimit: creditLimit ?? this.creditLimit,
      brand: brand ?? this.brand,
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
      interestRate: interestRate ?? this.interestRate,
      currency: currency ?? this.currency,
      bankEntity: bankEntity ?? this.bankEntity,
    );
  }
}
