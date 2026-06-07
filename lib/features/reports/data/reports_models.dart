// lib/features/reports/data/reports_models.dart

class CashflowReport {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double fixedExpense;
  final double variableExpense;
  final double savingsRate;

  const CashflowReport({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.fixedExpense,
    required this.variableExpense,
    required this.savingsRate,
  });

  factory CashflowReport.fromJson(Map<String, dynamic> json) {
    return CashflowReport(
      year: json['year'] as int,
      month: json['month'] as int,
      totalIncome: double.parse(json['total_income'].toString()),
      totalExpense: double.parse(json['total_expense'].toString()),
      fixedExpense: double.parse(json['fixed_expense'].toString()),
      variableExpense: double.parse(json['variable_expense'].toString()),
      savingsRate: double.parse(json['savings_rate'].toString()),
    );
  }
}

class CategoryReport {
  final int categoryId;
  final String categoryName;
  final double total;
  final double percentage;

  const CategoryReport({
    required this.categoryId,
    required this.categoryName,
    required this.total,
    required this.percentage,
  });

  factory CategoryReport.fromJson(Map<String, dynamic> json) {
    return CategoryReport(
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String,
      total: double.parse(json['total'].toString()),
      percentage: double.parse(json['percentage'].toString()),
    );
  }
}

class EntityReport {
  final int entityId;
  final String entityName;
  final double totalIncome;
  final double totalExpense;
  final double net;

  const EntityReport({
    required this.entityId,
    required this.entityName,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
  });

  factory EntityReport.fromJson(Map<String, dynamic> json) {
    return EntityReport(
      entityId: json['entity_id'] as int,
      entityName: json['entity_name'] as String,
      totalIncome: double.parse(json['total_income'].toString()),
      totalExpense: double.parse(json['total_expense'].toString()),
      net: double.parse(json['net'].toString()),
    );
  }
}
