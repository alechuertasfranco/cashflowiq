// lib/features/reports/presentation/reports_screen.dart

import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amount_text.dart';
import '../data/reports_models.dart';
import '../data/reports_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _service = ReportsService();

  late int _year;
  late int _month;

  List<CashflowReport> _cashflows = [];
  List<CategoryReport> _categories = [];
  List<EntityReport> _entities = [];

  bool _isLoading = true;
  String? _errorMessage;

  static const List<String> _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getCashflow(year: _year, month: _month),
        _service.getByCategory(year: _year, month: _month, type: 'EXPENSE'),
        _service.getByEntity(year: _year, month: _month),
      ]);

      if (!mounted) return;
      setState(() {
        _cashflows = results[0] as List<CashflowReport>;
        _categories = results[1] as List<CategoryReport>;
        _entities = results[2] as List<EntityReport>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar los reportes';
      });
      debugPrint('Error cargando reportes: $e');
    }
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year -= 1;
      } else {
        _month -= 1;
      }
    });
    _loadAll();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final isCurrentOrFuture =
        _year > now.year || (_year == now.year && _month >= now.month);
    if (isCurrentOrFuture) return;
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year += 1;
      } else {
        _month += 1;
      }
    });
    _loadAll();
  }

  /// All distinct currency codes that appear in any of the three datasets.
  List<String> get _currencyCodes {
    final codes = <String>{
      for (final r in _cashflows) r.currencyCode,
      for (final r in _categories) r.currencyCode,
      for (final r in _entities) r.currencyCode,
    };
    final sorted = codes.toList()..sort();
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            DataCache.instance.invalidatePrefix('reports');
            await _loadAll();
          },
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reportes', style: AppTextStyles.h300(context)),
                const SizedBox(height: 16),
                _MonthSelector(
                  monthName: _monthNames[_month - 1],
                  year: _year,
                  onPrevious: _previousMonth,
                  onNext: _nextMonth,
                  canGoNext: () {
                    final now = DateTime.now();
                    return !(_year > now.year ||
                        (_year == now.year && _month >= now.month));
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage != null)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.body1(context, color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else if (_currencyCodes.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                'Sin movimientos este mes',
                style: AppTextStyles.body1(context, color: AppColors.muted),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _buildCurrencySections(context),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildCurrencySections(BuildContext context) {
    final widgets = <Widget>[];

    for (final code in _currencyCodes) {
      final cashflow = _cashflows.where((r) => r.currencyCode == code).firstOrNull;
      final categories = _categories.where((r) => r.currencyCode == code).toList();
      final entities = _entities.where((r) => r.currencyCode == code).toList();
      final symbol = cashflow?.currencySymbol ??
          categories.firstOrNull?.currencySymbol ??
          entities.firstOrNull?.currencySymbol ??
          code;

      // Currency section header
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Divider(color: AppColors.border, height: 1)),
            ],
          ),
        ),
      );

      if (cashflow != null) {
        widgets.add(_CashflowCard(report: cashflow, symbol: symbol));
        widgets.add(const SizedBox(height: 16));
      }

      if (categories.isNotEmpty) {
        widgets.add(_CategorySection(categories: categories, symbol: symbol));
        widgets.add(const SizedBox(height: 16));
      }

      if (entities.isNotEmpty) {
        widgets.add(_EntitySection(entities: entities, symbol: symbol));
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }
}

// ---------------------------------------------------------------------------
// Month selector
// ---------------------------------------------------------------------------

class _MonthSelector extends StatelessWidget {
  final String monthName;
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool Function() canGoNext;

  const _MonthSelector({
    required this.monthName,
    required this.year,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    final nextEnabled = canGoNext();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppColors.primary,
            onPressed: onPrevious,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$monthName $year',
                style: AppTextStyles.h500(context),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: nextEnabled ? AppColors.primary : AppColors.muted,
            onPressed: nextEnabled ? onNext : null,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cashflow card
// ---------------------------------------------------------------------------

class _CashflowCard extends StatelessWidget {
  final CashflowReport report;
  final String symbol;

  const _CashflowCard({required this.report, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final savingsProgress = (report.savingsRate / 100).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flujo de caja', style: AppTextStyles.h500(context)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'Ingresos',
                    amount: report.totalIncome,
                    symbol: symbol,
                    color: AppColors.success,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    label: 'Gastos',
                    amount: report.totalExpense,
                    symbol: symbol,
                    color: AppColors.error,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),

            _ExpenseRow(
              label: 'Gasto fijo',
              amount: report.fixedExpense,
              symbol: symbol,
            ),
            const SizedBox(height: 8),
            _ExpenseRow(
              label: 'Gasto variable',
              amount: report.variableExpense,
              symbol: symbol,
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tasa de ahorro', style: AppTextStyles.subtitle2(context)),
                Text(
                  '${report.savingsRate.toStringAsFixed(1)}%',
                  style: AppTextStyles.h600(context, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: savingsProgress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  savingsProgress >= 0.2 ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final String symbol;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.symbol,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyles.caption(context, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          AmountText(
            symbol: symbol,
            amount: amount,
            style: AppTextStyles.h500(context),
            color: color,
          ),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final String label;
  final double amount;
  final String symbol;

  const _ExpenseRow({
    required this.label,
    required this.amount,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body1(context, color: AppColors.textSecondary)),
        AmountText(
          symbol: symbol,
          amount: amount,
          style: AppTextStyles.body1(context),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// By-category section
// ---------------------------------------------------------------------------

class _CategorySection extends StatelessWidget {
  final List<CategoryReport> categories;
  final String symbol;

  const _CategorySection({required this.categories, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final displayed = categories.length > 5 ? categories.sublist(0, 5) : categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gastos por categoría', style: AppTextStyles.h500(context)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < displayed.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _CategoryRow(report: displayed[i], symbol: symbol),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryReport report;
  final String symbol;

  const _CategoryRow({required this.report, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final progress = (report.percentage / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                report.categoryName,
                style: AppTextStyles.subtitle2(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AmountText(
                  symbol: symbol,
                  amount: report.total,
                  style: AppTextStyles.caption(context),
                ),
                Text(
                  '  ${report.percentage.toStringAsFixed(1)}%',
                  style: AppTextStyles.caption(context),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// By-entity section
// ---------------------------------------------------------------------------

class _EntitySection extends StatelessWidget {
  final List<EntityReport> entities;
  final String symbol;

  const _EntitySection({required this.entities, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Por entidad bancaria', style: AppTextStyles.h500(context)),
        const SizedBox(height: 12),
        for (final entity in entities) ...[
          _EntityCard(report: entity, symbol: symbol),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _EntityCard extends StatelessWidget {
  final EntityReport report;
  final String symbol;

  const _EntityCard({required this.report, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report.entityName, style: AppTextStyles.h600(context)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _EntityStat(
                    label: 'Ingresos',
                    value: report.totalIncome,
                    symbol: symbol,
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: _EntityStat(
                    label: 'Gastos',
                    value: report.totalExpense,
                    symbol: symbol,
                    color: AppColors.error,
                  ),
                ),
                Expanded(
                  child: _EntityStat(
                    label: 'Neto',
                    value: report.net,
                    symbol: symbol,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityStat extends StatelessWidget {
  final String label;
  final double value;
  final String symbol;
  final Color color;

  const _EntityStat({
    required this.label,
    required this.value,
    required this.symbol,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption(context)),
        const SizedBox(height: 2),
        AmountText(
          symbol: symbol,
          amount: value,
          style: AppTextStyles.body1(context),
          color: color,
        ),
      ],
    );
  }
}
