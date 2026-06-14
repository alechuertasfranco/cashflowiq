// lib/features/transactions/presentation/transaction_detail_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/features/transactions/data/transaction_service.dart';
import 'package:cashflowiq/features/transactions/presentation/expense_transaction/expense_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/income_transaction/income_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/transfer_transaction/transfer_screen.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:flutter/material.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;
  final String? categoryName;
  final String? accountName;
  final String? cardName;
  final String? toAccountName;
  final String? toCardName;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.categoryName,
    this.accountName,
    this.cardName,
    this.toAccountName,
    this.toCardName,
  });

  Color get _typeColor => switch (transaction.type) {
        TransactionType.income => AppColors.success,
        TransactionType.expense => AppColors.error,
        TransactionType.transfer => AppColors.primary,
      };

  IconData get _typeIcon => switch (transaction.type) {
        TransactionType.income => Icons.arrow_downward,
        TransactionType.expense => Icons.arrow_upward,
        TransactionType.transfer => Icons.swap_horiz,
      };

  String get _typeLabel => switch (transaction.type) {
        TransactionType.income => "Ingreso",
        TransactionType.expense => "Gasto",
        TransactionType.transfer => "Transferencia",
      };

  String? get _amountSign => switch (transaction.type) {
        TransactionType.income => "+",
        TransactionType.expense => "-",
        TransactionType.transfer => null,
      };

  String _fmtDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text("Eliminar movimiento", style: AppTextStyles.h500(ctx)),
        content: Text(
          "¿Seguro que deseas eliminar este movimiento? Esta acción no se puede deshacer.",
          style: AppTextStyles.body1(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancelar", style: AppTextStyles.body1(ctx, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Eliminar", style: AppTextStyles.body1(ctx, color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await TransactionService().deleteTransaction(transaction.id);
      if (!context.mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar el movimiento")),
      );
    }
  }

  Future<void> _edit(BuildContext context) async {
    final Widget screen = switch (transaction.type) {
      TransactionType.income => IncomeScreen(prefill: transaction, editMode: true),
      TransactionType.expense => ExpenseScreen(prefill: transaction, editMode: true),
      TransactionType.transfer => TransferScreen(prefill: transaction, editMode: true),
    };

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _replicate(BuildContext context) async {
    final Widget screen = switch (transaction.type) {
      TransactionType.income => IncomeScreen(prefill: transaction),
      TransactionType.expense => ExpenseScreen(prefill: transaction),
      TransactionType.transfer => TransferScreen(prefill: transaction),
    };

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_typeLabel, style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: "Editar movimiento",
            onPressed: () => _edit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: "Eliminar movimiento",
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    // Amount hero
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _typeColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(_typeIcon, color: _typeColor, size: 30),
                          ),
                          const SizedBox(height: 16),
                          AmountText(
                            symbol: transaction.currencySymbol.isNotEmpty
                                ? transaction.currencySymbol
                                : transaction.currencyCode,
                            amount: transaction.amount,
                            sign: _amountSign,
                            style: AppTextStyles.balance(context),
                            color: _typeColor,
                          ),
                        ],
                      ),
                    ),

                    // Details card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _row(context, Icons.calendar_today_outlined, "Fecha",
                              _fmtDate(transaction.date)),
                          if (categoryName != null) ...[
                            _divider(),
                            _row(context, Icons.category_outlined, "Categoría", categoryName!),
                          ],
                          if (transaction.type == TransactionType.income) ...[
                            if (accountName != null) ...[
                              _divider(),
                              _row(context, Icons.account_balance_outlined, "Cuenta destino",
                                  accountName!),
                            ],
                          ],
                          if (transaction.type == TransactionType.expense) ...[
                            if (cardName != null) ...[
                              _divider(),
                              _row(context, Icons.credit_card_outlined, "Tarjeta", cardName!),
                            ] else if (accountName != null) ...[
                              _divider(),
                              _row(context, Icons.account_balance_outlined, "Cuenta origen",
                                  accountName!),
                            ],
                          ],
                          if (transaction.type == TransactionType.transfer) ...[
                            if (accountName != null) ...[
                              _divider(),
                              _row(context, Icons.account_balance_outlined, "Origen", accountName!),
                            ],
                            if (toAccountName != null) ...[
                              _divider(),
                              _row(context, Icons.account_balance_outlined, "Destino",
                                  toAccountName!),
                            ],
                            if (toCardName != null) ...[
                              _divider(),
                              _row(context, Icons.credit_card_outlined, "Destino (tarjeta)",
                                  toCardName!),
                            ],
                          ],
                          if (transaction.currencyCode.isNotEmpty) ...[
                            _divider(),
                            _row(
                              context,
                              Icons.monetization_on_outlined,
                              "Moneda",
                              "${transaction.currencySymbol} ${transaction.currencyCode}".trim(),
                            ),
                          ],
                          if (transaction.isRecurring) ...[
                            _divider(),
                            _row(context, Icons.repeat, "Origen", "Regla recurrente"),
                          ],
                          if (transaction.description != null &&
                              transaction.description!.isNotEmpty) ...[
                            _divider(),
                            _row(context, Icons.notes_outlined, "Descripción",
                                transaction.description!),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Replicate button
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy_all_outlined, size: 18, color: Colors.white),
                  label: Text(
                    "Replicar movimiento",
                    style: AppTextStyles.subtitle2(context, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _replicate(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body2(context, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.subtitle2(context, color: AppColors.textPrimary),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border,
        indent: 46,
      );
}
