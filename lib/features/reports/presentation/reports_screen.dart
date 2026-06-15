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
  List<CategoryReport> _expenses = [];
  List<CategoryReport> _incomes = [];
  List<EntityReport> _entities = [];
  List<MonthlyTrendPoint> _trend = [];
  List<BudgetVsActualItem> _budgetVsActual = [];

  bool _isLoading = true;
  String? _errorMessage;

  // Toggle: which category type is displayed
  String _categoryType = 'EXPENSE';

  static const List<String> _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static const List<String> _monthShort = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
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
        _service.getByCategory(year: _year, month: _month, type: 'INCOME'),
        _service.getByEntity(year: _year, month: _month),
        _service.getMonthlyTrend(months: 6),
        _service.getBudgetVsActual(year: _year, month: _month),
      ]);

      if (!mounted) return;
      setState(() {
        _cashflows = results[0] as List<CashflowReport>;
        _expenses = results[1] as List<CategoryReport>;
        _incomes = results[2] as List<CategoryReport>;
        _entities = results[3] as List<EntityReport>;
        _trend = results[4] as List<MonthlyTrendPoint>;
        _budgetVsActual = results[5] as List<BudgetVsActualItem>;
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

  List<String> get _currencyCodes {
    final codes = <String>{
      for (final r in _cashflows) r.currencyCode,
      for (final r in _expenses) r.currencyCode,
      for (final r in _incomes) r.currencyCode,
      for (final r in _entities) r.currencyCode,
      for (final r in _budgetVsActual) r.currencyCode,
    };
    final sorted = codes.toList()..sort();
    return sorted;
  }

  List<String> get _trendCurrencyCodes {
    final codes = <String>{for (final p in _trend) p.currencyCode};
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
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _buildAllSections(context),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildAllSections(BuildContext context) {
    final widgets = <Widget>[];
    final hasMonthlyData = _currencyCodes.isNotEmpty;
    final hasTrend = _trend.isNotEmpty;

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

    // --- Monthly trend (always shown, not month-filtered) ---
    if (hasTrend) {
      for (final code in _trendCurrencyCodes) {
        final points = _trend.where((p) => p.currencyCode == code).toList();
        if (points.isNotEmpty) {
          widgets.add(_SectionHeader(label: code));
          widgets.add(
            _MonthlyTrendCard(
              points: points,
              monthShort: _monthShort,
            ),
          );
          widgets.add(const SizedBox(height: 16));
        }
      }
    }

    // --- Per-currency sections ---
    for (final code in _currencyCodes) {
      final cashflow = _cashflows.where((r) => r.currencyCode == code).firstOrNull;
      final expenses = _expenses.where((r) => r.currencyCode == code).toList();
      final incomes = _incomes.where((r) => r.currencyCode == code).toList();
      final entities = _entities.where((r) => r.currencyCode == code).toList();
      final budgets = _budgetVsActual.where((r) => r.currencyCode == code).toList();

      // Skip currency header if trend already showed it
      if (!hasTrend) {
        widgets.add(_SectionHeader(label: code));
      }

      if (cashflow != null) {
        final symbol = cashflow.currencySymbol;
        widgets.add(_CashflowCard(report: cashflow, symbol: symbol));
        widgets.add(const SizedBox(height: 16));
      }

      final catSymbol = expenses.firstOrNull?.currencySymbol ??
          incomes.firstOrNull?.currencySymbol ??
          cashflow?.currencySymbol ??
          code;

      if (expenses.isNotEmpty || incomes.isNotEmpty) {
        widgets.add(
          _CategorySection(
            expenses: expenses,
            incomes: incomes,
            symbol: catSymbol,
            selectedType: _categoryType,
            onTypeChanged: (type) => setState(() => _categoryType = type),
          ),
        );
        widgets.add(const SizedBox(height: 16));
      }

      if (budgets.isNotEmpty) {
        final budgetSymbol = budgets.first.currencySymbol;
        widgets.add(_BudgetVsActualSection(items: budgets, symbol: budgetSymbol));
        widgets.add(const SizedBox(height: 16));
      }

      if (entities.isNotEmpty) {
        final entitySymbol = entities.first.currencySymbol;
        widgets.add(_EntitySection(entities: entities, symbol: entitySymbol));
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
// Monthly trend card
// ---------------------------------------------------------------------------

class _MonthlyTrendCard extends StatelessWidget {
  final List<MonthlyTrendPoint> points;
  final List<String> monthShort;

  const _MonthlyTrendCard({required this.points, required this.monthShort});

  @override
  Widget build(BuildContext context) {
    final maxVal = points.fold(0.0, (max, p) {
      final m = p.totalIncome > p.totalExpense ? p.totalIncome : p.totalExpense;
      return m > max ? m : max;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Evolución mensual', style: AppTextStyles.h500(context)),
                const Spacer(),
                _LegendDot(color: AppColors.success, label: 'Ingresos'),
                const SizedBox(width: 12),
                _LegendDot(color: AppColors.error, label: 'Gastos'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < points.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: _TrendBar(
                        point: points[i],
                        maxVal: maxVal,
                        monthLabel: monthShort[(points[i].month - 1)],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption(context)),
      ],
    );
  }
}

class _TrendBar extends StatelessWidget {
  final MonthlyTrendPoint point;
  final double maxVal;
  final String monthLabel;

  const _TrendBar({
    required this.point,
    required this.maxVal,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    const barAreaHeight = 88.0;
    final incomeH = maxVal > 0 ? (point.totalIncome / maxVal * barAreaHeight) : 0.0;
    final expenseH = maxVal > 0 ? (point.totalExpense / maxVal * barAreaHeight) : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Bar(height: incomeH, color: AppColors.success),
            const SizedBox(width: 2),
            _Bar(height: expenseH, color: AppColors.error),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          monthLabel,
          style: AppTextStyles.caption(context, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      width: 10,
      height: height.clamp(2.0, double.infinity),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// By-category section with GASTO / INGRESO toggle
// ---------------------------------------------------------------------------

class _CatGroup {
  final int parentId;
  final String parentName;
  final List<CategoryReport> children;

  _CatGroup({required this.parentId, required this.parentName, required this.children});

  double get total => children.fold(0.0, (s, c) => s + c.total);
}

class _CategorySection extends StatefulWidget {
  final List<CategoryReport> expenses;
  final List<CategoryReport> incomes;
  final String symbol;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const _CategorySection({
    required this.expenses,
    required this.incomes,
    required this.symbol,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  final Set<int> _expanded = {};
  bool _showAll = false;

  List<CategoryReport> get _activeList =>
      widget.selectedType == 'EXPENSE' ? widget.expenses : widget.incomes;

  List<_CatGroup> _buildGroups(List<CategoryReport> categories) {
    final order = <int>[];
    final map = <int, _CatGroup>{};

    for (final cat in categories) {
      final parentId = cat.parentCategoryId ?? cat.categoryId;
      final parentName = cat.parentCategoryName ?? cat.categoryName;

      if (!map.containsKey(parentId)) {
        order.add(parentId);
        map[parentId] = _CatGroup(parentId: parentId, parentName: parentName, children: []);
      }
      map[parentId]!.children.add(cat);
    }

    return order.map((id) => map[id]!).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups(_activeList);
    final grandTotal = _activeList.fold(0.0, (s, c) => s + c.total);
    final cap = _showAll ? groups.length : groups.length.clamp(0, 5);
    final displayed = groups.sublist(0, cap);
    final hasMore = groups.length > 5;

    final isExpense = widget.selectedType == 'EXPENSE';
    final color = isExpense ? AppColors.error : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isExpense ? 'Gastos por categoría' : 'Ingresos por categoría',
              style: AppTextStyles.h500(context),
            ),
            const Spacer(),
            _TypeToggle(
              selected: widget.selectedType,
              onChanged: (v) {
                setState(() => _showAll = false);
                widget.onTypeChanged(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_activeList.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Sin ${isExpense ? 'gastos' : 'ingresos'} categorizados este mes',
                  style: AppTextStyles.body2(context, color: AppColors.muted),
                ),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (int i = 0; i < displayed.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _buildGroup(context, displayed[i], grandTotal, color),
                  ],
                  if (hasMore) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => setState(() => _showAll = !_showAll),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showAll
                                ? 'Ver menos'
                                : 'Ver todos (${groups.length})',
                            style: AppTextStyles.caption(context, color: AppColors.primary),
                          ),
                          Icon(
                            _showAll ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGroup(
    BuildContext context,
    _CatGroup group,
    double grandTotal,
    Color barColor,
  ) {
    final parentPercent = grandTotal > 0 ? (group.total / grandTotal * 100) : 0.0;
    final hasChildren = group.children.length > 1 ||
        (group.children.isNotEmpty && group.children.first.parentCategoryId != null);
    final isExpanded = _expanded.contains(group.parentId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: hasChildren
              ? () => setState(() {
                    if (isExpanded) {
                      _expanded.remove(group.parentId);
                    } else {
                      _expanded.add(group.parentId);
                    }
                  })
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.parentName,
                      style: AppTextStyles.subtitle2(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AmountText(
                    symbol: widget.symbol,
                    amount: group.total,
                    style: AppTextStyles.caption(context),
                  ),
                  Text(
                    '  ${parentPercent.toStringAsFixed(1)}%',
                    style: AppTextStyles.caption(context),
                  ),
                  if (hasChildren) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (parentPercent / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ],
          ),
        ),
        if (isExpanded && hasChildren) ...[
          const SizedBox(height: 10),
          for (int i = 0; i < group.children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _CategoryRow(
                report: group.children[i],
                symbol: widget.symbol,
                barColor: barColor,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _TypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            label: 'Gasto',
            selected: selected == 'EXPENSE',
            color: AppColors.error,
            onTap: () => onChanged('EXPENSE'),
            isLeft: true,
          ),
          _ToggleOption(
            label: 'Ingreso',
            selected: selected == 'INCOME',
            color: AppColors.success,
            onTap: () => onChanged('INCOME'),
            isLeft: false,
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final bool isLeft;

  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(7) : Radius.zero,
            right: isLeft ? Radius.zero : const Radius.circular(7),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption(
            context,
            color: selected ? color : AppColors.muted,
          ).copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryReport report;
  final String symbol;
  final Color barColor;

  const _CategoryRow({
    required this.report,
    required this.symbol,
    required this.barColor,
  });

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
                style: AppTextStyles.body2(context),
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
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(barColor.withValues(alpha: 0.6)),
          ),
        ),
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
    if (pct >= 80) return const Color(0xFFF97316); // orange
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
              child: Text(
                item.categoryName,
                style: AppTextStyles.subtitle2(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
                AmountText(
                  symbol: symbol,
                  amount: item.spentAmount,
                  style: AppTextStyles.caption(context, color: barColor),
                ),
                Text(
                  ' de ',
                  style: AppTextStyles.caption(context, color: AppColors.muted),
                ),
                AmountText(
                  symbol: symbol,
                  amount: item.budgetAmount,
                  style: AppTextStyles.caption(context, color: AppColors.textSecondary),
                ),
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
