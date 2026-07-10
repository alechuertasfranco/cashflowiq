// lib/features/splits/screens/splits_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/widgets/app_bottom_sheet.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/skeleton_loader.dart';
import 'package:cashflowiq/core/widgets/staggered_fade_in.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/splits/data/split_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
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
  final _accountService = BankAccountService();
  final _searchController = TextEditingController();

  List<TransactionSplit> _pending = [];
  List<TransactionSplit> _settled = [];
  String _query = '';

  bool _isLoadingPending = true;
  bool _isLoadingSettled = true;

  List<TransactionSplit> _filter(List<TransactionSplit> splits) {
    if (_query.isEmpty) return splits;
    final q = _query.toLowerCase();
    return splits
        .where((s) => s.contact.name.toLowerCase().contains(q))
        .toList();
  }

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
    _searchController.dispose();
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
    final account = await _pickDestinationAccount();
    if (account == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.settle(split.id, split.amount, account.id);
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

  Future<BankAccount?> _pickDestinationAccount() async {
    List<BankAccount> accounts;
    try {
      accounts = await _accountService.getAccounts();
    } catch (e) {
      debugPrint('Error loading accounts: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar las cuentas')),
      );
      return null;
    }

    if (accounts.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aún no tienes cuentas bancarias registradas'),
        ),
      );
      return null;
    }

    if (!mounted) return null;
    return showAppBottomSheet<BankAccount>(
      context,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '¿A qué cuenta te pagó?',
                style: ctx.heading4(),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: accounts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final a = accounts[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: ctx.radiusMdRadius,
                      side: BorderSide(color: ctx.colorBorder),
                    ),
                    tileColor: ctx.colorSurface,
                    leading: Icon(
                      Icons.account_balance,
                      color: ctx.colorPrimary,
                    ),
                    title: Text(
                      a.name,
                      style: ctx.textSubtitle1(),
                    ),
                    subtitle: Text(a.bankEntity.name),
                    onTap: () => Navigator.pop(ctx, a),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppHeaderBar(
        title: 'Gastos compartidos',
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Liquidados'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AppTextField(
                controller: _searchController,
                hintText: 'Buscar por contacto',
                prefixIcon: Icon(
                  Icons.search,
                  color: context.colorMuted,
                  size: 20,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.close,
                          color: context.colorMuted,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SplitList(
                    splits: _filter(_pending),
                    isLoading: _isLoadingPending,
                    showSettleButton: true,
                    onRefresh: () => _loadPending(invalidate: true),
                    onSettle: _settle,
                    emptyTitle: _query.isEmpty
                        ? 'Sin deudas pendientes'
                        : 'Sin resultados',
                    emptyDescription: _query.isEmpty
                        ? 'Cuando registres un gasto compartido, los pendientes aparecerán aquí'
                        : 'Ningún contacto pendiente coincide con "$_query"',
                  ),
                  _SplitList(
                    splits: _filter(_settled),
                    isLoading: _isLoadingSettled,
                    showSettleButton: false,
                    onRefresh: () => _loadSettled(invalidate: true),
                    onSettle: null,
                    emptyTitle: _query.isEmpty
                        ? 'Sin deudas liquidadas'
                        : 'Sin resultados',
                    emptyDescription: _query.isEmpty
                        ? 'Las deudas que hayas marcado como pagadas aparecerán aquí'
                        : 'Ningún contacto liquidado coincide con "$_query"',
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
      return const SkeletonListLoader(itemCount: 4, itemHeight: 76);
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
          return StaggeredFadeIn(
            index: index,
            child: _SplitCard(
              split: split,
              showSettleButton: showSettleButton,
              onSettle: onSettle != null ? () => onSettle!(split) : null,
            ),
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
        color: context.colorSurface,
        borderRadius: context.radiusLgRadius,
        border: Border.all(color: context.colorBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: split.isSettled
                  ? context.colorSuccess.withAlpha(25)
                  : context.colorError.withAlpha(25),
              borderRadius: context.radiusMdRadius,
            ),
            child: Icon(
              split.isSettled ? Icons.check_circle_outline : Icons.person,
              color: split.isSettled
                  ? context.colorSuccessStrong
                  : context.colorError,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(split.contact.name, style: context.heading6()),
                const SizedBox(height: 2),
                Text(
                  _formatDate(split.createdAt),
                  style: context.textCaption(
                    color: context.colorTextSecondary,
                  ),
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
                style: context.heading5(),
                color: split.isSettled
                    ? context.colorSuccessStrong
                    : context.colorError,
              ),
              if (showSettleButton && onSettle != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onSettle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorPrimary,
                      borderRadius: context.radiusSmRadius,
                    ),
                    child: Text(
                      'Liquidar',
                      style: context.textCaption(
                        color: context.colorOnPrimary,
                      ),
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
