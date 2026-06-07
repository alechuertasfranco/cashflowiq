// lib/features/dashboard/data/dashboard_summary.dart

class AccountBalance {
  final int id;
  final String name;
  final String currencyCode;
  final double balance;

  const AccountBalance({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.balance,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    return AccountBalance(
      id: json['id'] as int,
      name: json['name'] as String,
      currencyCode: json['currency_code'] as String,
      balance: double.parse(json['balance'].toString()),
    );
  }
}

class DashboardSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final List<AccountBalance> accounts;

  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.accounts,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final rawAccounts = json['accounts'] as List<dynamic>? ?? [];
    return DashboardSummary(
      totalIncome: double.parse(json['total_income'].toString()),
      totalExpense: double.parse(json['total_expense'].toString()),
      netBalance: double.parse(json['net_balance'].toString()),
      accounts: rawAccounts
          .map((a) => AccountBalance.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
