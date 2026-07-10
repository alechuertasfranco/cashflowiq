// lib/features/transactions/presentation/transactions_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/core/widgets/app_bottom_sheet.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/skeleton_loader.dart';
import 'package:cashflowiq/core/widgets/staggered_fade_in.dart';
import 'package:cashflowiq/core/widgets/swipe_to_delete.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/features/profile/data/credit_card_service.dart';
import 'package:cashflowiq/features/transactions/data/transaction_service.dart';
import 'package:cashflowiq/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/transaction_type_screen.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:flutter/material.dart';

class TransactionsScreen extends StatefulWidget {
  final String? initialAccountId;

  const TransactionsScreen({super.key, this.initialAccountId});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _txService = TransactionService();
  final _categoryService = CategoryService();
  final _accountService = BankAccountService();
  final _cardService = CreditCardService();

  List<Transaction> _transactions = [];
  List<BankAccount> _allAccounts = [];
  Map<String, String> _categoryNames = {};
  Map<String, String> _accountNames = {};
  Map<String, String> _cardNames = {};

  TransactionType? _typeFilter;
  DateTimeRange? _dateRange;
  BankEntity? _entityFilter;
  BankAccount? _accountFilter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _txService.getTransactions(
          type: _typeFilter?.toApi(),
          fromDate: _dateRange?.start.toIso8601String().split('T').first,
          toDate: _dateRange?.end.toIso8601String().split('T').first,
        ),
        _categoryService.getCategories(),
        _accountService.getAccounts(),
        _cardService.getCreditCards(),
      ]);

      final txs = results[0] as List<Transaction>;
      final cats = results[1] as List<Category>;
      final accounts = results[2] as List<BankAccount>;
      final cards = results[3] as List<CreditCard>;

      if (!mounted) return;
      setState(() {
        _transactions = txs;
        _allAccounts = accounts;
        _categoryNames = {for (final c in cats) c.id: c.name};
        _accountNames = {for (final a in accounts) a.id: a.name};
        _cardNames = {for (final c in cards) c.id: c.name};
        if (widget.initialAccountId != null && _accountFilter == null) {
          _accountFilter = accounts.where((a) => a.id == widget.initialAccountId).firstOrNull;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Transaction> get _filteredTransactions {
    if (_accountFilter != null) {
      final id = _accountFilter!.id;
      return _transactions.where((tx) => tx.accountId == id || tx.toAccountId == id).toList();
    }
    if (_entityFilter != null) {
      final ids = _allAccounts
          .where((a) => a.bankEntity.id == _entityFilter!.id)
          .map((a) => a.id)
          .toSet();
      return _transactions
          .where((tx) =>
              (tx.accountId != null && ids.contains(tx.accountId)) ||
              (tx.toAccountId != null && ids.contains(tx.toAccountId)))
          .toList();
    }
    return _transactions;
  }

  List<BankEntity> get _uniqueEntities {
    final seen = <String>{};
    return [
      for (final a in _allAccounts)
        if (seen.add(a.bankEntity.id)) a.bankEntity,
    ];
  }

  Future<void> _openDetail(Transaction tx) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(
          transaction: tx,
          categoryName: tx.categoryId != null ? _categoryNames[tx.categoryId] : null,
          accountName: tx.accountId != null ? _accountNames[tx.accountId] : null,
          cardName: tx.creditCardId != null ? _cardNames[tx.creditCardId] : null,
          toAccountName: tx.toAccountId != null ? _accountNames[tx.toAccountId] : null,
          toCardName: tx.toCreditCardId != null ? _cardNames[tx.toCreditCardId] : null,
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Transaction tx) async {
    try {
      await _txService.deleteTransaction(tx.id);
      setState(() => _transactions.remove(tx));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar la transacción")),
      );
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _load();
    }
  }

  void _showFilterSheet() {
    showAppBottomSheet(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Filtrar por cuenta", style: ctx.heading5()),
                if (_entityFilter != null || _accountFilter != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _entityFilter = null;
                        _accountFilter = null;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text("Limpiar", style: ctx.textBody2(color: ctx.colorPrimary)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_uniqueEntities.isNotEmpty) ...[
              Text("Entidad bancaria", style: ctx.textCaption(color: ctx.colorTextSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _uniqueEntities.map((entity) {
                  final selected = _entityFilter?.id == entity.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _entityFilter = selected ? null : entity;
                        _accountFilter = null;
                      });
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: ctx.motionFast,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? ctx.colorPrimary : ctx.colorBackground,
                        borderRadius: ctx.radiusXlRadius,
                        border: Border.all(
                          color: selected ? ctx.colorPrimary : ctx.colorBorder,
                        ),
                      ),
                      child: Text(
                        entity.name,
                        style: ctx.textBody2(color: selected ? ctx.colorOnPrimary : ctx.colorTextSecondary),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            Text("Cuenta específica", style: ctx.textCaption(color: ctx.colorTextSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allAccounts.map((account) {
                final selected = _accountFilter?.id == account.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _accountFilter = selected ? null : account;
                      _entityFilter = null;
                    });
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: ctx.motionFast,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? ctx.colorPrimary : ctx.colorBackground,
                      borderRadius: ctx.radiusXlRadius,
                      border: Border.all(
                        color: selected ? ctx.colorPrimary : ctx.colorBorder,
                      ),
                    ),
                    child: Text(
                      account.name,
                      style: ctx.textBody2(color: selected ? ctx.colorOnPrimary : ctx.colorTextSecondary),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Transaction>> get _grouped {
    final sorted = [..._filteredTransactions]..sort((a, b) => b.date.compareTo(a.date));
    final map = <String, List<Transaction>>{};
    for (final tx in sorted) {
      final key = _fmtDate(tx.date);
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }

  String _fmtDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  String _fmtTime(DateTime d) =>
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  Future<void> _onReorderGroup(List<Transaction> txs, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;

    final reordered = [...txs];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    // Times sorted newest-first (matches display order: position 0 = highest time)
    final existingTimes = txs.map((t) => t.date).toList()
      ..sort((a, b) => b.compareTo(a));

    // All at the same time? (e.g., legacy transactions at 00:00)
    final allSame = existingTimes.every(
      (t) => t.difference(existingTimes.first).inSeconds.abs() < 2,
    );

    final List<Transaction> toUpdate = [];

    if (allSame) {
      // Generate evenly-spaced times within the day: position 0 → 23:59, 1 → 23:58, ...
      final base = DateTime(existingTimes.first.year, existingTimes.first.month, existingTimes.first.day);
      for (int i = 0; i < reordered.length; i++) {
        final newDate = base.add(Duration(minutes: (23 * 60 + 59) - i));
        toUpdate.add(reordered[i].copyWith(date: newDate));
      }
    } else {
      // Redistribute the existing times across the new display order
      for (int i = 0; i < reordered.length; i++) {
        final newDate = existingTimes[i];
        if (reordered[i].date != newDate) {
          toUpdate.add(reordered[i].copyWith(date: newDate));
        }
      }
    }

    setState(() {
      for (final tx in toUpdate) {
        final idx = _transactions.indexWhere((t) => t.id == tx.id);
        if (idx != -1) _transactions[idx] = tx;
      }
    });

    for (final tx in toUpdate) {
      try {
        await _txService.updateTransaction(tx.id, tx);
      } catch (e) {
        debugPrint('Reorder persist error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAccountFilter = _entityFilter != null || _accountFilter != null;

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppHeaderBar(
        title: "Movimientos",
        actions: [
          IconButton(
            icon: Icon(
              Icons.date_range,
              color: _dateRange != null ? context.colorPrimary : context.colorMuted,
            ),
            onPressed: _pickDateRange,
            tooltip: "Filtrar por fecha",
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune,
                  color: hasAccountFilter ? context.colorPrimary : context.colorMuted,
                ),
                onPressed: _showFilterSheet,
                tooltip: "Filtrar por cuenta",
              ),
              if (hasAccountFilter)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: context.colorPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.add, color: context.colorPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionTypeScreen()),
            ).then((_) => _load()),
            tooltip: "Nueva transacción",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _typeFilterChips(),
            if (_dateRange != null) _dateRangeBanner(),
            if (hasAccountFilter) _accountFilterBanner(),
            Expanded(
              child: _isLoading
                  ? const SkeletonListLoader()
                  : _filteredTransactions.isEmpty
                      ? _emptyState()
                      : _list(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeFilterChips() {
    const options = [null, TransactionType.income, TransactionType.expense, TransactionType.transfer];
    const labels = ["Todos", "Ingresos", "Gastos", "Transferencias"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(options.length, (i) {
          final selected = _typeFilter == options[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (_typeFilter == options[i]) return;
                setState(() => _typeFilter = options[i]);
                _load();
              },
              child: AnimatedContainer(
                duration: context.motionFast,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? context.colorPrimary : context.colorSurface,
                  borderRadius: context.radiusXlRadius,
                  border: Border.all(
                    color: selected ? context.colorPrimary : context.colorBorder,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: context.textBody2(
                    color: selected ? context.colorOnPrimary : context.colorTextSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _dateRangeBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorSecondary,
        borderRadius: context.radiusMdRadius,
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 16, color: context.colorPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${_fmtDate(_dateRange!.start)} – ${_fmtDate(_dateRange!.end)}",
              style: context.textBody2(color: context.colorPrimary),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _dateRange = null);
              _load();
            },
            child: Icon(Icons.close, size: 16, color: context.colorPrimary),
          ),
        ],
      ),
    );
  }

  Widget _accountFilterBanner() {
    final label = _accountFilter?.name ?? _entityFilter!.name;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorSecondary,
        borderRadius: context.radiusMdRadius,
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance, size: 16, color: context.colorPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: context.textBody2(color: context.colorPrimary),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _entityFilter = null;
              _accountFilter = null;
            }),
            child: Icon(Icons.close, size: 16, color: context.colorPrimary),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    final grouped = _grouped;
    final dateKeys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () async {
        DataCache.instance.invalidatePrefix('transactions');
        DataCache.instance.invalidate('categories_all');
        DataCache.instance.invalidate('accounts');
        DataCache.instance.invalidate('credit_cards');
        await _load();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: dateKeys.length,
        itemBuilder: (_, i) => StaggeredFadeIn(
          index: i,
          child: _dateGroup(dateKeys[i], grouped[dateKeys[i]]!),
        ),
      ),
    );
  }

  Widget _dateGroup(String date, List<Transaction> txs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(date, style: context.textCaption(color: context.colorTextSecondary)),
        ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          padding: EdgeInsets.zero,
          onReorder: (oldIndex, newIndex) => _onReorderGroup(txs, oldIndex, newIndex),
          children: [
            for (int i = 0; i < txs.length; i++)
              Padding(
                key: ValueKey(txs[i].id),
                padding: const EdgeInsets.only(bottom: 8),
                child: ReorderableDelayedDragStartListener(
                  index: i,
                  child: SwipeToDelete(
                    onDelete: () => _delete(txs[i]),
                    showConfirmation: true,
                    child: GestureDetector(
                      onTap: () => _openDetail(txs[i]),
                      child: _transactionTile(txs[i]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _transactionTile(Transaction tx) {
    final (icon, color, title, subtitle, sign) = _tileData(tx);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: context.radiusLgRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: context.radiusMdRadius,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textSubtitle2(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: context.textCaption(color: context.colorMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountText(
                symbol: tx.currencySymbol,
                amount: tx.amount,
                sign: sign.isEmpty ? null : sign,
                style: context.textSubtitle2(),
                color: color,
              ),
              Text(
                _fmtTime(tx.date),
                style: context.textCaption(color: context.colorMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (IconData, Color, String, String, String) _tileData(Transaction tx) {
    switch (tx.type) {
      case TransactionType.income:
        final incomeCategory = tx.categoryId != null ? _categoryNames[tx.categoryId] ?? "Ingreso" : "Ingreso";
        final account = tx.accountId != null ? _accountNames[tx.accountId] ?? "" : "";
        final hasIncomeDesc = tx.description != null && tx.description!.isNotEmpty;
        final incomeSubtitle = hasIncomeDesc
            ? (account.isNotEmpty ? "$incomeCategory · $account" : incomeCategory)
            : account;
        return (Icons.arrow_downward, context.colorSuccess, hasIncomeDesc ? tx.description! : incomeCategory, incomeSubtitle, "+");

      case TransactionType.expense:
        final expenseCategory = tx.categoryId != null ? _categoryNames[tx.categoryId] ?? "Gasto" : "Gasto";
        final source = tx.creditCardId != null
            ? _cardNames[tx.creditCardId] ?? ""
            : tx.accountId != null
                ? _accountNames[tx.accountId] ?? ""
                : "";
        final hasExpenseDesc = tx.description != null && tx.description!.isNotEmpty;
        final expenseSubtitle = hasExpenseDesc
            ? (source.isNotEmpty ? "$expenseCategory · $source" : expenseCategory)
            : source;
        return (Icons.arrow_upward, context.colorError, hasExpenseDesc ? tx.description! : expenseCategory, expenseSubtitle, "-");

      case TransactionType.transfer:
        final from = tx.accountId != null ? _accountNames[tx.accountId] ?? "" : "";
        final to = tx.toAccountId != null
            ? _accountNames[tx.toAccountId] ?? ""
            : tx.toCreditCardId != null
                ? _cardNames[tx.toCreditCardId] ?? ""
                : "";
        final subtitle = from.isNotEmpty && to.isNotEmpty ? "$from → $to" : "";
        return (Icons.swap_horiz, context.colorPrimary, "Transferencia", subtitle, "");
    }
  }

  Widget _emptyState() {
    return InsightEmptyState(
      icon: Icons.receipt_long,
      title: "Sin movimientos",
      description: "Registra tus ingresos, gastos y transferencias para ver tu historial aquí",
      actionText: "Registrar movimiento",
      onAction: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TransactionTypeScreen()),
      ).then((_) => _load()),
    );
  }
}
