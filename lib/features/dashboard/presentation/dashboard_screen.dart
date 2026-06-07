// lib/features/dashboard/presentation/dashboard_screen.dart

import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/dashboard_service.dart';
import '../data/dashboard_summary.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _service = DashboardService();

  DashboardSummary? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _service.getSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar el resumen';
      });
      debugPrint('Error cargando dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSummary,
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        children: [
          SizedBox(
            height: 300,
            child: Center(
              child: Text(
                _errorMessage!,
                style: AppTextStyles.body1(context, color: AppColors.error),
              ),
            ),
          ),
        ],
      );
    }

    final summary = _summary!;

    AccountBalance? topAccount;
    if (summary.accounts.isNotEmpty) {
      topAccount = summary.accounts.reduce(
        (a, b) => a.balance >= b.balance ? a : b,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Header(),
        const SizedBox(height: 20),
        _BalanceCard(
          accounts: summary.accounts,
          totalIncome: summary.totalIncome,
          totalExpense: summary.totalExpense,
        ),
        const SizedBox(height: 20),
        _InsightCard(topAccount: topAccount),
        const SizedBox(height: 20),
        _AccountsList(accounts: summary.accounts),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CashFlowIQ', style: AppTextStyles.caption(context)),
        const SizedBox(height: 4),
        Text('Tu dinero, en control', style: AppTextStyles.h300(context)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Balance card
// ---------------------------------------------------------------------------

class _BalanceCard extends StatelessWidget {
  final List<AccountBalance> accounts;
  final double totalIncome;
  final double totalExpense;

  const _BalanceCard({
    required this.accounts,
    required this.totalIncome,
    required this.totalExpense,
  });

  static String _symbol(String code) {
    const map = {
      'PEN': 'S/',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'CLP': '\$',
      'COP': '\$',
      'MXN': '\$',
      'BRL': 'R\$',
    };
    return map[code] ?? code;
  }

  /// Sum account balances grouped by currency code.
  Map<String, double> _balancesByCurrency() {
    final map = <String, double>{};
    for (final a in accounts) {
      map[a.currencyCode] = (map[a.currencyCode] ?? 0) + a.balance;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final byCurrency = _balancesByCurrency();
    final isSingleCurrency = byCurrency.length <= 1;
    final singleCode = isSingleCurrency && byCurrency.isNotEmpty
        ? byCurrency.keys.first
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance total', style: AppTextStyles.caption(context)),
            const SizedBox(height: 10),

            // Per-currency balance rows
            if (byCurrency.isEmpty)
              Text(
                'Sin cuentas registradas',
                style: AppTextStyles.body1(context, color: AppColors.muted),
              )
            else
              ...byCurrency.entries.map((e) {
                final isPositive = e.value >= 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      CurrencyBadge(code: e.key),
                      const SizedBox(width: 10),
                      AmountText(
                        symbol: _symbol(e.key),
                        amount: e.value,
                        style: AppTextStyles.h100(context),
                        color: isPositive ? AppColors.textPrimary : AppColors.error,
                      ),
                    ],
                  ),
                );
              }),

            // Income/expense stats only meaningful when single currency
            if (isSingleCurrency && singleCode != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'Ingresos',
                      symbol: _symbol(singleCode),
                      amount: totalIncome,
                      sign: '+',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      label: 'Gastos',
                      symbol: _symbol(singleCode),
                      amount: totalExpense,
                      sign: '-',
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String symbol;
  final double amount;
  final String sign;
  final Color color;

  const _StatChip({
    required this.label,
    required this.symbol,
    required this.amount,
    required this.sign,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption(context, color: color)),
          const SizedBox(height: 4),
          AmountText(
            symbol: symbol,
            amount: amount,
            sign: sign,
            style: AppTextStyles.body2(context),
            color: color,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Insight card
// ---------------------------------------------------------------------------

class _InsightCard extends StatelessWidget {
  final AccountBalance? topAccount;

  const _InsightCard({required this.topAccount});

  @override
  Widget build(BuildContext context) {
    if (topAccount == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.account_balance_outlined, color: AppColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Agrega cuentas bancarias para ver tus insights',
                  style: AppTextStyles.subtitle2(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cuenta con mayor saldo', style: AppTextStyles.caption(context)),
                  const SizedBox(height: 2),
                  Text(
                    topAccount!.name,
                    style: AppTextStyles.subtitle1(context),
                  ),
                  AmountText(
                    symbol: _BalanceCard._symbol(topAccount!.currencyCode),
                    amount: topAccount!.balance,
                    style: AppTextStyles.body2(context),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Accounts list
// ---------------------------------------------------------------------------

class _AccountsList extends StatelessWidget {
  final List<AccountBalance> accounts;

  const _AccountsList({required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mis cuentas', style: AppTextStyles.h500(context)),
        const SizedBox(height: 12),
        if (accounts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('Sin cuentas', style: AppTextStyles.body1(context, color: AppColors.muted)),
              ),
            ),
          )
        else
          ...accounts.map((account) => _AccountRow(account: account)),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  final AccountBalance account;

  const _AccountRow({required this.account});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, style: AppTextStyles.subtitle1(context)),
                  Text(account.currencyCode, style: AppTextStyles.caption(context)),
                ],
              ),
            ),
            AmountText(
              symbol: _BalanceCard._symbol(account.currencyCode),
              amount: account.balance,
              style: AppTextStyles.h600(context),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
