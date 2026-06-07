// lib/features/dashboard/presentation/dashboard_screen.dart

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
    final currencyCode = summary.accounts.isNotEmpty
        ? summary.accounts.first.currencyCode
        : 'USD';

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
          currencyCode: currencyCode,
          netBalance: summary.netBalance,
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
  final String currencyCode;
  final double netBalance;
  final double totalIncome;
  final double totalExpense;

  const _BalanceCard({
    required this.currencyCode,
    required this.netBalance,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance actual', style: AppTextStyles.caption(context)),
            const SizedBox(height: 8),
            Text(
              '$currencyCode ${netBalance.toStringAsFixed(2)}',
              style: AppTextStyles.h100(context),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '+ Ingresos: $currencyCode ${totalIncome.toStringAsFixed(2)}',
                  style: AppTextStyles.body2(context, color: AppColors.success),
                ),
                Text(
                  '- Gastos: $currencyCode ${totalExpense.toStringAsFixed(2)}',
                  style: AppTextStyles.body2(context, color: AppColors.error),
                ),
              ],
            ),
          ],
        ),
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
                  Text(
                    '${topAccount!.currencyCode} ${topAccount!.balance.toStringAsFixed(2)}',
                    style: AppTextStyles.body2(context, color: AppColors.primary),
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
            Text(
              account.balance.toStringAsFixed(2),
              style: AppTextStyles.h600(context, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
