// lib/features/dashboard/data/dashboard_summary.dart

class AccountBalance {
  final int id;
  final String name;
  final String currencyCode;
  final String bankEntityCode;
  final double balance;

  const AccountBalance({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.bankEntityCode,
    required this.balance,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    return AccountBalance(
      id: json['id'] as int,
      name: json['name'] as String,
      currencyCode: json['currency_code'] as String,
      bankEntityCode: json['bank_entity_code'] as String,
      balance: double.parse(json['balance'].toString()),
    );
  }
}

class DashboardSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final List<AccountBalance> accounts;
  final int? mostActiveAccountId;
  final String? mostActiveAccountName;
  final int mostActiveAccountTxCount;

  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.accounts,
    this.mostActiveAccountId,
    this.mostActiveAccountName,
    this.mostActiveAccountTxCount = 0,
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
      mostActiveAccountId: json['most_active_account_id'] as int?,
      mostActiveAccountName: json['most_active_account_name'] as String?,
      mostActiveAccountTxCount: (json['most_active_account_tx_count'] as int?) ?? 0,
    );
  }
}
