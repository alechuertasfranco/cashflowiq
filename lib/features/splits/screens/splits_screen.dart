// lib/features/splits/screens/splits_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/features/splits/data/split_service.dart';
import 'package:cashflowiq/shared/models/transaction_split.dart';
import 'package:flutter/material.dart';

class SplitsScreen extends StatefulWidget {
  const SplitsScreen({super.key});

  @override
  State<SplitsScreen> createState() => _SplitsScreenState();
}

class _SplitsScreenState extends State<SplitsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = SplitService();

  List<TransactionSplit> _pending = [];
  List<TransactionSplit> _settled = [];

  bool _isLoadingPending = true;
  bool _isLoadingSettled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPending();
    _loadSettled();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPending({bool invalidate = false}) async {
    if (invalidate) DataCache.instance.invalidate('splits_pending');
    setState(() => _isLoadingPending = true);
    try {
      final splits = await _service.fetchSplits(settled: false);
      if (!mounted) return;
      setState(() {
        _pending = splits;
        _isLoadingPending = false;
      });
    } catch (e) {
      debugPrint('Error loading pending splits: $e');
      if (!mounted) return;
      setState(() => _isLoadingPending = false);
    }
  }

  Future<void> _loadSettled({bool invalidate = false}) async {
    if (invalidate) DataCache.instance.invalidate('splits_settled');
    setState(() => _isLoadingSettled = true);
    try {
      final splits = await _service.fetchSplits(settled: true);
      if (!mounted) return;
      setState(() {
        _settled = splits;
        _isLoadingSettled = false;
      });
    } catch (e) {
      debugPrint('Error loading settled splits: $e');
      if (!mounted) return;
      setState(() => _isLoadingSettled = false);
    }
  }

  Future<void> _settle(TransactionSplit split) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.settle(split.id, split.amount);
      await _loadPending();
      await _loadSettled();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Deuda liquidada correctamente')),
      );
    } catch (e) {
      debugPrint('Error settling split: $e');
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Error al liquidar la deuda')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Gastos compartidos', style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Liquidados'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
        controller: _tabController,
        children: [
          _SplitList(
            splits: _pending,
            isLoading: _isLoadingPending,
            showSettleButton: true,
            onRefresh: () => _loadPending(invalidate: true),
            onSettle: _settle,
            emptyTitle: 'Sin deudas pendientes',
            emptyDescription:
                'Cuando registres un gasto compartido, los pendientes aparecerán aquí',
          ),
          _SplitList(
            splits: _settled,
            isLoading: _isLoadingSettled,
            showSettleButton: false,
            onRefresh: () => _loadSettled(invalidate: true),
            onSettle: null,
            emptyTitle: 'Sin deudas liquidadas',
            emptyDescription:
                'Las deudas que hayas marcado como pagadas aparecerán aquí',
          ),
        ],
      ),
      ),
    );
  }
}

// ── Split list tab ────────────────────────────────────────────────────────────

class _SplitList extends StatelessWidget {
  final List<TransactionSplit> splits;
  final bool isLoading;
  final bool showSettleButton;
  final Future<void> Function() onRefresh;
  final Future<void> Function(TransactionSplit)? onSettle;
  final String emptyTitle;
  final String emptyDescription;

  const _SplitList({
    required this.splits,
    required this.isLoading,
    required this.showSettleButton,
    required this.onRefresh,
    required this.onSettle,
    required this.emptyTitle,
    required this.emptyDescription,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (splits.isEmpty) {
      return InsightEmptyState(
        icon: Icons.handshake_outlined,
        title: emptyTitle,
        description: emptyDescription,
        actionText: 'Actualizar',
        onAction: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: splits.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final split = splits[index];
          return _SplitCard(
            split: split,
            showSettleButton: showSettleButton,
            onSettle:
                onSettle != null ? () => onSettle!(split) : null,
          );
        },
      ),
    );
  }
}

// ── Split card ────────────────────────────────────────────────────────────────

class _SplitCard extends StatelessWidget {
  final TransactionSplit split;
  final bool showSettleButton;
  final VoidCallback? onSettle;

  const _SplitCard({
    required this.split,
    required this.showSettleButton,
    required this.onSettle,
  });

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: split.isSettled
                  ? AppColors.success.withAlpha(25)
                  : AppColors.error.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              split.isSettled ? Icons.check_circle_outline : Icons.person,
              color: split.isSettled ? AppColors.successStrong : AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  split.contact.name,
                  style: AppTextStyles.h600(context),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(split.createdAt),
                  style: AppTextStyles.caption(context,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Amount + settle button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountText(
                symbol: split.currencySymbol ?? '',
                amount: split.amount,
                style: AppTextStyles.h500(context),
                color: split.isSettled ? AppColors.successStrong : AppColors.error,
              ),
              if (showSettleButton && onSettle != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onSettle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Liquidar',
                      style: AppTextStyles.caption(context,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
