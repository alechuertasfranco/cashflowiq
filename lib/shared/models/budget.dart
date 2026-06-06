// lib/shared/models/budget.dart

import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/currency.dart';

class Budget {
  final String id;
  final double amount;
  final double spent;
  final String categoryId;
  final String currencyId;

  final Category? category;
  final Currency? currency;

  Budget({
    required this.id,
    required this.amount,
    required this.spent,
    required this.categoryId,
    required this.currencyId,
    this.category,
    this.currency,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'].toString(),
      amount: json['amount'] is num ? json['amount'].toDouble() : double.tryParse(json['amount'].toString()) ?? 0.0,
      spent: json['spent'] is num ? json['spent'].toDouble() : double.tryParse(json['spent'].toString()) ?? 0.0,
      categoryId: json['category_id'].toString(),
      currencyId: json['currency_id'].toString(),

      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      currency: json['currency'] != null ? Currency.fromMap(json['currency']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "amount": amount, "category_id": categoryId, "currency_id": currencyId};
  }

  /// ✅ POST /budgets
  Map<String, dynamic> toCreateJson() {
    return {"amount": amount, "category_id": int.parse(categoryId), "currency_id": int.parse(currencyId)};
  }
}
