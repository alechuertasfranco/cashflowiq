// lib/features/transactions/presentation/recurring/recurring_transactions_screen.dart

import 'package:cashflowiq/core/services/notification_service.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/core/widgets/app_dialog.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/skeleton_loader.dart';
import 'package:cashflowiq/core/widgets/staggered_fade_in.dart';
import 'package:cashflowiq/core/widgets/swipe_to_delete.dart';
import 'package:cashflowiq/features/transactions/data/recurring_transaction_service.dart';
import 'package:cashflowiq/features/transactions/presentation/recurring/recurring_execution_form_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/recurring/recurring_transaction_form_screen.dart';
import 'package:cashflowiq/shared/models/recurring_transaction.dart';
import 'package:flutter/material.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  final _service = RecurringTransactionService();

  List<RecurringTransaction> _rules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final rules = await _service.fetchAll();
      rules.sort((a, b) => a.nextExecutionDate.compareTo(b.nextExecutionDate));
      if (!mounted) return;
      setState(() {
        _rules = rules;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading recurring transactions: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar las reglas recurrentes")),
      );
    }
  }

  Future<void> _goToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecurringTransactionFormScreen(),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _goToEdit(RecurringTransaction rule) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecurringTransactionFormScreen(existing: rule),
      ),
    );
    if (result == true) _load();
  }

  Future<bool> _confirmRegister(RecurringTransaction rule) {
    final isIncome = rule.type == 'INCOME';
    final amountStr =
        '${rule.currencySymbol ?? ''}${rule.amount!.toStringAsFixed(2)}';
    return showAppConfirmDialog(
      context,
      title: 'Registrar pago',
      message: '¿Deseas registrar "${rule.name}" por '
          '${isIncome ? '+' : '-'}$amountStr? '
          'Se creará una transacción en tus movimientos.',
      confirmText: 'Registrar',
    );
  }

  Future<void> _executeRule(RecurringTransaction rule) async {
    if (rule.amount != null) {
      final confirmed = await _confirmRegister(rule);
      if (!confirmed) return;
      try {
        await NotificationService.instance.autoRegister(rule);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${rule.name} registrado')),
        );
        await _load();
      } catch (e) {
        debugPrint('Error executing rule: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al registrar la transacción')),
        );
      }
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecurringExecutionFormScreen(rule: rule),
        ),
      );
      if (result == true) _load();
    }
  }

  Future<void> _delete(RecurringTransaction rule) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.delete(rule.id);
      await _load();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text("Regla eliminada")),
      );
    } catch (e) {
      debugPrint("Error deleting recurring rule: $e");
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text("Error al eliminar la regla")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: const AppHeaderBar(title: "Transacciones recurrentes"),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colorPrimary,
        onPressed: _goToCreate,
        child: Icon(Icons.add, color: context.colorOnPrimary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const SkeletonListLoader()
            : _rules.isEmpty
                ? InsightEmptyState(
                    icon: Icons.repeat,
                    title: "Sin reglas recurrentes",
                    description:
                        "Automatiza tus ingresos y gastos periódicos creando una regla recurrente",
                    actionText: "Crear regla",
                    onAction: _goToCreate,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      DataCache.instance.invalidate('recurring_transactions');
                      await _load();
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _rules.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final rule = _rules[index];
                        return StaggeredFadeIn(
                          index: index,
                          child: SwipeToDelete(
                            onDelete: () => _delete(rule),
                            showConfirmation: true,
                            child: _RecurringRuleTile(
                              rule: rule,
                              onTap: () => _goToEdit(rule),
                              onExecute: () => _executeRule(rule),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class _RecurringRuleTile extends StatelessWidget {
  final RecurringTransaction rule;
  final VoidCallback onTap;
  final VoidCallback onExecute;

  const _RecurringRuleTile({
    required this.rule,
    required this.onTap,
    required this.onExecute,
  });

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  @override
  Widget build(BuildContext context) {
    final isIncome = rule.type == 'INCOME';
    final typeColor = isIncome ? context.colorSuccess : context.colorError;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: context.radiusLgRadius,
          border: Border.all(color: context.colorBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(25),
                    borderRadius: context.radiusMdRadius,
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Name and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rule.name, style: context.heading6()),
                      if (rule.categoryName != null)
                        Text(
                          rule.categoryName!,
                          style: context.textCaption(
                              color: context.colorTextSecondary),
                        ),
                    ],
                  ),
                ),

                // Amount
                if (rule.amount != null)
                  AmountText(
                    symbol: rule.currencySymbol ?? '',
                    amount: rule.amount!,
                    sign: isIncome ? '+' : '-',
                    style: context.heading5(),
                    color: typeColor,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colorMuted.withAlpha(30),
                      borderRadius: context.radiusSmRadius,
                    ),
                    child: Text(
                      'Variable',
                      style: context.textCaption(color: context.colorMuted),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                // Frequency badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colorSecondary,
                    borderRadius: context.radiusSmRadius,
                  ),
                  child: Text(
                    rule.frequency.toLabel(),
                    style: context.textCaption(color: context.colorPrimary),
                  ),
                ),
                const SizedBox(width: 8),

                // Next execution date
                Icon(Icons.event, size: 14, color: context.colorMuted),
                const SizedBox(width: 4),
                Text(
                  _formatDate(rule.nextExecutionDate),
                  style: context.textCaption(),
                ),

                const Spacer(),

                if (!rule.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colorMuted.withAlpha(40),
                      borderRadius: context.radiusSmRadius,
                    ),
                    child: Text(
                      'Inactivo',
                      style: context.textCaption(color: context.colorMuted),
                    ),
                  )
                else if (rule.notificationDaysBefore != null && rule.currentPeriodRegistered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colorSuccess.withAlpha(25),
                      borderRadius: context.radiusSmRadius,
                    ),
                    child: Text(
                      'Registrado',
                      style: context.textCaption(color: context.colorSuccessStrong),
                    ),
                  )
                else if (rule.notificationDaysBefore != null)
                  GestureDetector(
                    onTap: onExecute,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colorPrimary.withAlpha(20),
                        borderRadius: context.radiusSmRadius,
                        border: Border.all(color: context.colorPrimary.withAlpha(60)),
                      ),
                      child: Text(
                        'Registrar ahora',
                        style: context.textCaption(color: context.colorPrimary),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colorSuccess.withAlpha(25),
                      borderRadius: context.radiusSmRadius,
                    ),
                    child: Text(
                      'Activo',
                      style: context.textCaption(color: context.colorSuccessStrong),
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
