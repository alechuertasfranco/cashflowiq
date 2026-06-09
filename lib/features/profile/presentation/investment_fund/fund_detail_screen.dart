// lib/features/profile/presentation/investment_fund/fund_detail_screen.dart

import 'package:cashflowiq/core/services/notification_service.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/widgets/swipe_to_delete.dart';
import 'package:cashflowiq/features/profile/data/investment_fund_service.dart';
import 'package:cashflowiq/features/profile/presentation/investment_fund/form_investment_fund_screen.dart';
import 'package:cashflowiq/features/profile/presentation/investment_fund/form_snapshot_screen.dart';
import 'package:cashflowiq/shared/models/investment_fund.dart';
import 'package:cashflowiq/shared/models/investment_fund_snapshot.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FundDetailScreen extends StatefulWidget {
  final InvestmentFund fund;

  const FundDetailScreen({super.key, required this.fund});

  @override
  State<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends State<FundDetailScreen> {
  final _service = InvestmentFundService();
  List<InvestmentFundSnapshot> _snapshots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final snapshots = await _service.getSnapshots(widget.fund.id);
      if (!mounted) return;
      setState(() {
        _snapshots = snapshots;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSnapshot() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormSnapshotScreen(fund: widget.fund)),
    );
    if (result == true) {
      DataCache.instance.invalidate('fund_snapshots_${widget.fund.id}');
      await _load();
    }
  }

  Future<void> _deleteSnapshot(InvestmentFundSnapshot snap) async {
    try {
      await _service.deleteSnapshot(widget.fund.id, snap.id);
      setState(() => _snapshots.remove(snap));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error al eliminar")));
    }
  }

  // -------------------------------------------------------------------------
  // Chart data
  // -------------------------------------------------------------------------

  List<FlSpot> get _chartSpots {
    if (_snapshots.isEmpty) return [];
    final origin = _snapshots.first.snapshotDate;
    return _snapshots.map((s) {
      final days = s.snapshotDate.difference(origin).inDays.toDouble();
      return FlSpot(days, s.value);
    }).toList();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String _fmtDate(DateTime d) {
    const m = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${m[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final fund = widget.fund;
    final hasCurrentValue = fund.currentValue != null;
    final diff = hasCurrentValue ? fund.currentValue! - fund.investedAmount : null;
    final isGain = diff != null && diff >= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(fund.name, style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            tooltip: "Activar recordatorio mensual",
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await NotificationService.instance.scheduleMonthlyInvestmentReminder();
              messenger.showSnackBar(
                const SnackBar(content: Text("Recordatorio mensual activado")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: "Editar fondo",
            onPressed: () async {
              final nav = Navigator.of(context);
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => FormInvestmentFundScreen(fund: widget.fund),
                ),
              );
              if (result == true) nav.pop(true);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _addSnapshot,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("Registrar balance", style: AppTextStyles.body2(context, color: Colors.white)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            DataCache.instance.invalidate('fund_snapshots_${fund.id}');
            await _load();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
              _HeaderCard(
                fund: fund,
                diff: diff,
                isGain: isGain,
              ),
              const SizedBox(height: 20),

              // Chart
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_snapshots.length >= 2)
                _ChartCard(snapshots: _snapshots, spots: _chartSpots, fund: fund)
              else if (_snapshots.isEmpty)
                _EmptyChart(onAdd: _addSnapshot)
              else
                _SinglePointHint(),

              if (_snapshots.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  "Historial de balances",
                  style: AppTextStyles.subtitle1(context),
                ),
                const SizedBox(height: 12),
                ..._snapshots.reversed.map(
                  (snap) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SwipeToDelete(
                      key: ValueKey(snap.id),
                      onDelete: () => _deleteSnapshot(snap),
                      child: _SnapshotRow(
                        snapshot: snap,
                        symbol: fund.currency.symbol,
                        decimals: fund.currency.decimals,
                        fmtDate: _fmtDate,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header card
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  final InvestmentFund fund;
  final double? diff;
  final bool isGain;

  const _HeaderCard({required this.fund, required this.diff, required this.isGain});

  @override
  Widget build(BuildContext context) {
    final hasCurrentValue = fund.currentValue != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Valor actual", style: AppTextStyles.caption(context, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            hasCurrentValue ? fund.currentValueMoney!.format() : "—",
            style: AppTextStyles.balance(context),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(
                label: "Invertido",
                value: fund.investedMoney.format(),
                context: context,
              ),
              if (diff != null) ...[
                const SizedBox(width: 24),
                _Stat(
                  label: isGain ? "Ganancia" : "Pérdida",
                  value: "${isGain ? '+' : ''}${fund.currency.symbol} ${diff!.abs().toStringAsFixed(fund.currency.decimals)}",
                  valueColor: isGain ? AppColors.success : AppColors.error,
                  context: context,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final BuildContext context;

  const _Stat({required this.label, required this.value, this.valueColor, required this.context});

  @override
  Widget build(BuildContext _) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption(context, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.subtitle1(context, color: valueColor),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Chart card
// ---------------------------------------------------------------------------

class _ChartCard extends StatelessWidget {
  final List<InvestmentFundSnapshot> snapshots;
  final List<FlSpot> spots;
  final InvestmentFund fund;

  const _ChartCard({required this.snapshots, required this.spots, required this.fund});

  @override
  Widget build(BuildContext context) {
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yPad = (maxY - minY) * 0.1 + 1;

    const months = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final origin = snapshots.first.snapshotDate;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text("Evolución del valor", style: AppTextStyles.subtitle2(context)),
          ),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minY - yPad,
                maxY: maxY + yPad,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY + yPad * 2) / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: spots.length > 1
                          ? (spots.last.x - spots.first.x) / (spots.length - 1)
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final date = origin.add(Duration(days: value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            months[date.month],
                            style: AppTextStyles.caption(context, color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withAlpha(26),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    getTooltipItems: (spots) => spots.map((s) {
                      return LineTooltipItem(
                        '${fund.currency.symbol} ${s.y.toStringAsFixed(fund.currency.decimals)}',
                        AppTextStyles.caption(context, color: AppColors.primary),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / single-point states
// ---------------------------------------------------------------------------

class _EmptyChart extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyChart({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.show_chart, size: 40, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            "Sin historial todavía",
            style: AppTextStyles.subtitle2(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "Registra el balance de este mes para empezar a ver la evolución de tu inversión",
            style: AppTextStyles.caption(context, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SinglePointHint extends StatelessWidget {
  const _SinglePointHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Registra al menos 2 balances para ver el gráfico",
              style: AppTextStyles.body2(context, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Snapshot row
// ---------------------------------------------------------------------------

class _SnapshotRow extends StatelessWidget {
  final InvestmentFundSnapshot snapshot;
  final String symbol;
  final int decimals;
  final String Function(DateTime) fmtDate;

  const _SnapshotRow({
    required this.snapshot,
    required this.symbol,
    required this.decimals,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            fmtDate(snapshot.snapshotDate),
            style: AppTextStyles.body1(context),
          ),
          Text(
            "$symbol ${snapshot.value.toStringAsFixed(decimals)}",
            style: AppTextStyles.subtitle2(context, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
