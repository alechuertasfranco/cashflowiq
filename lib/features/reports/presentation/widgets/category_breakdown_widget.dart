import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/features/reports/data/reports_models.dart';
import 'package:cashflowiq/features/reports/presentation/widgets/report_filter_bar.dart';
import 'package:flutter/material.dart';

class CategoryBreakdownWidget extends StatefulWidget {
  final List<CategoryReport> expenses;
  final List<CategoryReport> incomes;
  final String symbol;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const CategoryBreakdownWidget({
    super.key,
    required this.expenses,
    required this.incomes,
    required this.symbol,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  State<CategoryBreakdownWidget> createState() => _CategoryBreakdownWidgetState();
}

class _CategoryBreakdownWidgetState extends State<CategoryBreakdownWidget> {
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
    final color = isExpense ? context.colorError : context.colorSuccess;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isExpense ? 'Gastos por categoría' : 'Ingresos por categoría',
              style: context.heading5(),
            ),
            const Spacer(),
            ReportFilterBar(
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
                  style: context.textBody2(color: context.colorMuted),
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
                            style: context.textCaption(color: context.colorPrimary),
                          ),
                          Icon(
                            _showAll ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                            color: context.colorPrimary,
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
                      style: context.textSubtitle2(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AmountText(
                    symbol: widget.symbol,
                    amount: group.total,
                    style: context.textCaption(),
                  ),
                  Text(
                    '  ${parentPercent.toStringAsFixed(1)}%',
                    style: context.textCaption(),
                  ),
                  if (hasChildren) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: context.colorMuted,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: context.radiusSmRadius,
                child: LinearProgressIndicator(
                  value: (parentPercent / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: context.colorBorder,
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

class _CatGroup {
  final int parentId;
  final String parentName;
  final List<CategoryReport> children;

  _CatGroup({required this.parentId, required this.parentName, required this.children});

  double get total => children.fold(0.0, (s, c) => s + c.total);
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
                style: context.textBody2(),
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
                  style: context.textCaption(),
                ),
                Text(
                  '  ${report.percentage.toStringAsFixed(1)}%',
                  style: context.textCaption(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: context.radiusSmRadius,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: context.colorBorder,
            valueColor: AlwaysStoppedAnimation<Color>(barColor.withValues(alpha: 0.6)),
          ),
        ),
      ],
    );
  }
}
