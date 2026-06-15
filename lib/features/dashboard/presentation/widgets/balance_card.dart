import 'package:cashflowiq/features/dashboard/data/dashboard_summary.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/balance_card/balance_total_page.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/balance_card/currency_utils.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/balance_card/monthly_flow_page.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/balance_card/page_dots.dart';
import 'package:flutter/material.dart';

class DashboardBalanceCard extends StatefulWidget {
  final List<AccountBalance> accounts;
  final double netBalance;
  final double totalIncome;
  final double totalExpense;
  final double allTimeIncome;
  final double allTimeExpense;

  const DashboardBalanceCard({
    super.key,
    required this.accounts,
    required this.netBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.allTimeIncome,
    required this.allTimeExpense,
  });

  @override
  State<DashboardBalanceCard> createState() => _DashboardBalanceCardState();
}

class _DashboardBalanceCardState extends State<DashboardBalanceCard> {
  final _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  Map<String, double> _balancesByCurrency() {
    final map = <String, double>{};
    for (final a in widget.accounts) {
      map[a.currencyCode] = (map[a.currencyCode] ?? 0) + a.balance;
    }
    return map;
  }

  String? get _dominantCurrency {
    final byCurrency = _balancesByCurrency();
    if (byCurrency.isEmpty) return null;
    return byCurrency.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  double get _totalBalance {
    final byCurrency = _balancesByCurrency();
    if (byCurrency.isEmpty) return 0;
    return byCurrency.entries.reduce((a, b) => a.value >= b.value ? a : b).value;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayCode = _dominantCurrency;
    final symbol = displayCode != null ? dashboardCurrencySymbol(displayCode) : '';
    final hasAccounts = widget.accounts.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 148,
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  MonthlyFlowPage(
                    symbol: symbol,
                    displayCode: displayCode,
                    hasAccounts: hasAccounts,
                    netBalance: widget.netBalance,
                    totalIncome: widget.totalIncome,
                    totalExpense: widget.totalExpense,
                  ),
                  BalanceTotalPage(
                    symbol: symbol,
                    displayCode: displayCode,
                    hasAccounts: hasAccounts,
                    totalBalance: _totalBalance,
                    allTimeIncome: widget.allTimeIncome,
                    allTimeExpense: widget.allTimeExpense,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            PageDots(count: 2, current: _currentPage),
          ],
        ),
      ),
    );
  }
}
