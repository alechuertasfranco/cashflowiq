// lib/shared/models/investment_fund.dart

import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/money.dart';
import 'package:flutter/animation.dart';

enum InvestmentFundType {
  mutualFund,
  afp,
  insurance,
  etf,
  other;

  factory InvestmentFundType.fromString(String? value) {
    if (value == null) return InvestmentFundType.other;

    switch (value.toLowerCase()) {
      case 'mutual_fund':
        return InvestmentFundType.mutualFund;
      case 'afp':
        return InvestmentFundType.afp;
      case 'insurance':
        return InvestmentFundType.insurance;
      case 'etf':
        return InvestmentFundType.etf;
      default:
        return InvestmentFundType.other;
    }
  }

  String toApi() {
    switch (this) {
      case InvestmentFundType.mutualFund:
        return "mutual_fund";
      case InvestmentFundType.afp:
        return "afp";
      case InvestmentFundType.insurance:
        return "insurance";
      case InvestmentFundType.etf:
        return "etf";
      case InvestmentFundType.other:
        return "other";
    }
  }

  String toLabel() {
    switch (this) {
      case InvestmentFundType.mutualFund:
        return "Fondos Mutuos";
      case InvestmentFundType.afp:
        return "Fondo de Pensiones";
      case InvestmentFundType.insurance:
        return "Seguro con Devolución";
      case InvestmentFundType.etf:
        return "ETF";
      case InvestmentFundType.other:
        return "Otro";
    }
  }

  Color get color {
    switch (this) {
      case InvestmentFundType.mutualFund:
        return Color(0xFFC7E6FF); // Azul
      case InvestmentFundType.afp:
        return Color(0xFFCBFFCD); // Verde
      case InvestmentFundType.insurance:
        return Color(0xFFFFD493); // Naranja
      case InvestmentFundType.etf:
        return Color(0xFFFADCFF); // Púrpura
      case InvestmentFundType.other:
        return Color(0xFFE0E0E0); // Gris
    }
  }
}

class InvestmentFund {
  final String id;
  final String name;

  /// 💰 Capital invertido (NO es balance disponible)
  final double investedAmount;

  /// 📈 Valor actual del fondo (opcional, puede diferir del capital invertido)
  final double? currentValue;

  /// 🧠 Tipo → clave para insights futuros
  final InvestmentFundType fundType;

  final Currency currency;
  final BankEntity bankEntity;

  InvestmentFund({
    required this.id,
    required this.name,
    required this.investedAmount,
    this.currentValue,
    required this.fundType,
    required this.currency,
    required this.bankEntity,
  });

  /// 💰 Representación monetaria del capital invertido
  Money get investedMoney => Money(amount: investedAmount, currency: currency);

  /// 📈 Representación monetaria del valor actual (null si no definido)
  Money? get currentValueMoney => currentValue != null ? Money(amount: currentValue!, currency: currency) : null;

  /// 🧠 Identidad de dominio
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is InvestmentFund && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// 📥 FROM API
  factory InvestmentFund.fromJson(Map<String, dynamic> json) {
    return InvestmentFund(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      investedAmount: parseToDouble(json['invested_amount']),
      currentValue: json['current_value'] != null ? parseToDouble(json['current_value']) : null,
      fundType: InvestmentFundType.fromString(json['fund_type']),
      currency: Currency.fromMap(json['currency']),
      bankEntity: BankEntity.fromJson(json['bank_entity']),
    );
  }

  /// 📤 TO API
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "invested_amount": investedAmount,
      if (currentValue != null) "current_value": currentValue,
      "fund_type": fundType.toApi(),
      "currency_id": currency.id,
      "bank_entity_id": bankEntity.id,
    };
  }

  InvestmentFund copyWith({
    String? name,
    double? investedAmount,
    double? currentValue,
    InvestmentFundType? fundType,
    Currency? currency,
    BankEntity? bankEntity,
  }) {
    return InvestmentFund(
      id: id,
      name: name ?? this.name,
      investedAmount: investedAmount ?? this.investedAmount,
      currentValue: currentValue ?? this.currentValue,
      fundType: fundType ?? this.fundType,
      currency: currency ?? this.currency,
      bankEntity: bankEntity ?? this.bankEntity,
    );
  }
}
