import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/features/reports/data/reports_models.dart';
import 'package:cashflowiq/features/reports/presentation/reports_data_loader.dart';
import 'package:cashflowiq/features/reports/presentation/widgets/cashflow_chart_widget.dart';
import 'package:cashflowiq/features/reports/presentation/widgets/category_breakdown_widget.dart';
import 'package:cashflowiq/features/reports/presentation/widgets/month_navigator.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _loader = ReportDataLoader();

  @override
  void initState() {
    super.initState();
    _loader.loadAll();
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loader.loadAll(invalidateCache: true),
          child: ListenableBuilder(
            listenable: _loader,
            builder: (context, _) => _buildBody(context),
          ),
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
                MonthNavigator(
                  monthName: ReportDataLoader.monthNames[_loader.month - 1],
                  year: _loader.year,
                  onPrevious: _loader.previousMonth,
                  onNext: _loader.nextMonth,
                  canGoNext: _loader.canGoNext,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        if (_loader.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_loader.errorMessage != null)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _loader.errorMessage!,
                  style: AppTextStyles.body1(context, color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(_buildAllSections(context)),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildAllSections(BuildContext context) {
    final widgets = <Widget>[];
    final hasMonthlyData = _loader.currencyCodes.isNotEmpty;
    final hasTrend = _loader.trend.isNotEmpty;

    if (!hasMonthlyData && !hasTrend) {
      widgets.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              'Sin movimientos este mes',
              style: AppTextStyles.body1(context, color: AppColors.muted),
            ),
          ),
        ),
      );
      return widgets;
    }

    if (hasTrend) {
      for (final code in _loader.trendCurrencyCodes) {
        final points = _loader.trend.where((p) => p.currencyCode == code).toList();
        if (points.isNotEmpty) {
          widgets.add(_SectionHeader(label: code));
          widgets.add(CashflowChartWidget(
            points: points,
            monthShort: ReportDataLoader.monthShort,
          ));
          widgets.add(const SizedBox(height: 16));
        }
      }
    }

    for (final code in _loader.currencyCodes) {
      final cashflow = _loader.cashflows.where((r) => r.currencyCode == code).firstOrNull;
      final expenses = _loader.expenses.where((r) => r.currencyCode == code).toList();
      final incomes = _loader.incomes.where((r) => r.currencyCode == code).toList();
      final entities = _loader.entities.where((r) => r.currencyCode == code).toList();
      final budgets = _loader.budgetVsActual.where((r) => r.currencyCode == code).toList();

      if (!hasTrend) widgets.add(_SectionHeader(label: code));

      if (cashflow != null) {
        widgets.add(_CashflowCard(report: cashflow, symbol: cashflow.currencySymbol));
        widgets.add(const SizedBox(height: 16));
      }

      final catSymbol = expenses.firstOrNull?.currencySymbol ??
          incomes.firstOrNull?.currencySymbol ??
          cashflow?.currencySymbol ??
          code;

      if (expenses.isNotEmpty || incomes.isNotEmpty) {
        widgets.add(
          CategoryBreakdownWidget(
            expenses: expenses,
            incomes: incomes,
            symbol: catSymbol,
            selectedType: _loader.categoryType,
            onTypeChanged: _loader.setCategoryType,
          ),
        );
        widgets.add(const SizedBox(height: 16));
      }

      if (budgets.isNotEmpty) {
        widgets.add(_BudgetVsActualSection(items: budgets, symbol: budgets.first.currencySymbol));
        widgets.add(const SizedBox(height: 16));
      }

      if (entities.isNotEmpty) {
        widgets.add(_EntitySection(entities: entities, symbol: entities.first.currencySymbol));
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }
}

// ---------------------------------------------------------------------------
// Section header with currency chip
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              label,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Cashflow summary card
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
            _ExpenseRow(label: 'Gasto fijo', amount: report.fixedExpense, symbol: symbol),
            const SizedBox(height: 8),
            _ExpenseRow(label: 'Gasto variable', amount: report.variableExpense, symbol: symbol),
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
          AmountText(symbol: symbol, amount: amount, style: AppTextStyles.h500(context), color: color),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final String label;
  final double amount;
  final String symbol;

  const _ExpenseRow({required this.label, required this.amount, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body1(context, color: AppColors.textSecondary)),
        AmountText(symbol: symbol, amount: amount, style: AppTextStyles.body1(context)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Budget vs actual section
// ---------------------------------------------------------------------------

class _BudgetVsActualSection extends StatelessWidget {
  final List<BudgetVsActualItem> items;
  final String symbol;

  const _BudgetVsActualSection({required this.items, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Presupuesto vs gasto real', style: AppTextStyles.h500(context)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 4),
                    const Divider(height: 16, color: AppColors.border),
                  ],
                  _BudgetRow(item: items[i], symbol: symbol),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final BudgetVsActualItem item;
  final String symbol;

  const _BudgetRow({required this.item, required this.symbol});

  Color _barColor(double pct) {
    if (pct >= 100) return AppColors.error;
    if (pct >= 80) return const Color(0xFFF97316);
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final pct = item.percentageUsed;
    final progress = (pct / 100).clamp(0.0, 1.0);
    final barColor = _barColor(pct);
    final isOver = pct >= 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(item.categoryName, style: AppTextStyles.subtitle2(context),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (isOver)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Excedido',
                  style: AppTextStyles.caption(context, color: AppColors.error)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AmountText(symbol: symbol, amount: item.spentAmount,
                    style: AppTextStyles.caption(context, color: barColor)),
                Text(' de ', style: AppTextStyles.caption(context, color: AppColors.muted)),
                AmountText(symbol: symbol, amount: item.budgetAmount,
                    style: AppTextStyles.caption(context, color: AppColors.textSecondary)),
              ],
            ),
            Text(
              '${pct.toStringAsFixed(1)}%',
              style: AppTextStyles.caption(context, color: barColor)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
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
                Expanded(child: _EntityStat(label: 'Ingresos', value: report.totalIncome,
                    symbol: symbol, color: AppColors.success)),
                Expanded(child: _EntityStat(label: 'Gastos', value: report.totalExpense,
                    symbol: symbol, color: AppColors.error)),
                Expanded(child: _EntityStat(label: 'Neto', value: report.net,
                    symbol: symbol, color: AppColors.primary)),
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

  const _EntityStat({required this.label, required this.value, required this.symbol, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption(context)),
        const SizedBox(height: 2),
        AmountText(symbol: symbol, amount: value, style: AppTextStyles.body1(context), color: color),
      ],
    );
  }
}
