// lib/features/dashboard/presentation/dashboard_screen.dart

import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/features/transactions/presentation/transactions_screen.dart';
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
          onRefresh: () async {
            DataCache.instance.invalidate('dashboard_summary');
            await _loadSummary();
          },
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Header(),
        const SizedBox(height: 20),
        _BalanceCard(
          accounts: summary.accounts,
          netBalance: summary.netBalance,
          totalIncome: summary.totalIncome,
          totalExpense: summary.totalExpense,
        ),
        const SizedBox(height: 20),
        _InsightCard(
          mostActiveAccountName: summary.mostActiveAccountName,
          mostActiveAccountTxCount: summary.mostActiveAccountTxCount,
        ),
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
  final double netBalance;
  final double totalIncome;
  final double totalExpense;

  const _BalanceCard({
    required this.accounts,
    required this.netBalance,
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
    final singleCode = byCurrency.length == 1 ? byCurrency.keys.first : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Flujo del mes', style: AppTextStyles.caption(context)),
                const Spacer(),
                if (singleCode != null) CurrencyBadge(code: singleCode),
              ],
            ),
            const SizedBox(height: 8),

            // Net = income − expense (month-to-date)
            if (byCurrency.isEmpty)
              Text(
                'Sin cuentas registradas',
                style: AppTextStyles.body1(context, color: AppColors.muted),
              )
            else
              AmountText(
                symbol: singleCode != null ? _symbol(singleCode) : '',
                amount: netBalance,
                style: AppTextStyles.h100(context),
                color: netBalance >= 0 ? AppColors.textPrimary : AppColors.error,
              ),

            if (byCurrency.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'Ingresos',
                      symbol: singleCode != null ? _symbol(singleCode) : '',
                      amount: totalIncome,
                      sign: '+',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      label: 'Gastos',
                      symbol: singleCode != null ? _symbol(singleCode) : '',
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
// Insight card — account with most transactions this month
// ---------------------------------------------------------------------------

class _InsightCard extends StatelessWidget {
  final String? mostActiveAccountName;
  final int mostActiveAccountTxCount;

  const _InsightCard({
    required this.mostActiveAccountName,
    required this.mostActiveAccountTxCount,
  });

  @override
  Widget build(BuildContext context) {
    if (mostActiveAccountName == null) {
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
            const Icon(Icons.bolt_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cuenta más activa este mes', style: AppTextStyles.caption(context)),
                  const SizedBox(height: 2),
                  Text(
                    mostActiveAccountName!,
                    style: AppTextStyles.subtitle1(context),
                  ),
                  Text(
                    '$mostActiveAccountTxCount movimiento${mostActiveAccountTxCount == 1 ? '' : 's'}',
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

class _AccountsList extends StatefulWidget {
  final List<AccountBalance> accounts;

  const _AccountsList({required this.accounts});

  @override
  State<_AccountsList> createState() => _AccountsListState();
}

class _AccountsListState extends State<_AccountsList> {
  String? _entityFilter;
  bool _showAll = false;

  static const _previewCount = 5;

  void _setEntityFilter(String? code) {
    setState(() {
      _entityFilter = code;
      _showAll = false;
    });
  }

  List<String> get _uniqueEntityCodes {
    final seen = <String>{};
    return [
      for (final a in widget.accounts)
        if (seen.add(a.bankEntityCode)) a.bankEntityCode,
    ];
  }

  List<AccountBalance> get _filtered => _entityFilter == null
      ? widget.accounts
      : widget.accounts.where((a) => a.bankEntityCode == _entityFilter).toList();

  @override
  Widget build(BuildContext context) {
    final entities = _uniqueEntityCodes;
    final filtered = _filtered;
    final hasMore = !_showAll && filtered.length > _previewCount;
    final visible = _showAll ? filtered : filtered.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mis cuentas', style: AppTextStyles.h500(context)),
        const SizedBox(height: 12),
        if (widget.accounts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('Sin cuentas', style: AppTextStyles.body1(context, color: AppColors.muted)),
              ),
            ),
          )
        else ...[
          if (entities.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _EntityChip(
                    label: 'Todas',
                    selected: _entityFilter == null,
                    onTap: () => _setEntityFilter(null),
                  ),
                  ...entities.map((code) => _EntityChip(
                        label: code,
                        selected: _entityFilter == code,
                        onTap: () => _setEntityFilter(_entityFilter == code ? null : code),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...visible.map((account) => _AccountRow(
                account: account,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionsScreen(initialAccountId: account.id.toString()),
                  ),
                ),
              )),
          if (hasMore)
            GestureDetector(
              onTap: () => setState(() => _showAll = true),
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ver todas las cuentas (${filtered.length})',
                      style: AppTextStyles.body2(context, color: AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _EntityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EntityChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption(
              context,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final AccountBalance account;
  final VoidCallback onTap;

  const _AccountRow({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
                    Text(account.bankEntityCode, style: AppTextStyles.caption(context)),
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
      ),
    );
  }
}
