// lib/features/transactions/presentation/transaction_detail_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/app_dialog.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
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

  Color _typeColor(BuildContext context) => switch (transaction.type) {
        TransactionType.income => context.colorSuccess,
        TransactionType.expense => context.colorError,
        TransactionType.transfer => context.colorPrimary,
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

  String _fmtDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return "$day/$month/${d.year}  $h:$min";
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: "Eliminar movimiento",
      message: "¿Seguro que deseas eliminar este movimiento? Esta acción no se puede deshacer.",
      confirmText: "Eliminar",
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) return;

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
    final typeColor = _typeColor(context);

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppHeaderBar(
        title: _typeLabel,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: context.colorPrimary),
            tooltip: "Editar movimiento",
            onPressed: () => _edit(context),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: context.colorError),
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
                              color: typeColor.withAlpha(26),
                              borderRadius: context.radiusXlRadius,
                            ),
                            child: Icon(_typeIcon, color: typeColor, size: 30),
                          ),
                          const SizedBox(height: 16),
                          AmountText(
                            symbol: transaction.currencySymbol.isNotEmpty
                                ? transaction.currencySymbol
                                : transaction.currencyCode,
                            amount: transaction.amount,
                            sign: _amountSign,
                            style: context.textBalance(),
                            color: typeColor,
                          ),
                        ],
                      ),
                    ),

                    // Details card
                    Container(
                      decoration: BoxDecoration(
                        color: context.colorSurface,
                        borderRadius: context.radiusLgRadius,
                      ),
                      child: Column(
                        children: [
                          _row(context, Icons.calendar_today_outlined, "Fecha y hora",
                              _fmtDate(transaction.date)),
                          if (categoryName != null) ...[
                            _divider(context),
                            _row(context, Icons.category_outlined, "Categoría", categoryName!),
                          ],
                          if (transaction.type == TransactionType.income) ...[
                            if (accountName != null) ...[
                              _divider(context),
                              _row(context, Icons.account_balance_outlined, "Cuenta destino",
                                  accountName!),
                            ],
                          ],
                          if (transaction.type == TransactionType.expense) ...[
                            if (cardName != null) ...[
                              _divider(context),
                              _row(context, Icons.credit_card_outlined, "Tarjeta", cardName!),
                            ] else if (accountName != null) ...[
                              _divider(context),
                              _row(context, Icons.account_balance_outlined, "Cuenta origen",
                                  accountName!),
                            ],
                          ],
                          if (transaction.type == TransactionType.transfer) ...[
                            if (accountName != null) ...[
                              _divider(context),
                              _row(context, Icons.account_balance_outlined, "Origen", accountName!),
                            ],
                            if (toAccountName != null) ...[
                              _divider(context),
                              _row(context, Icons.account_balance_outlined, "Destino",
                                  toAccountName!),
                            ],
                            if (toCardName != null) ...[
                              _divider(context),
                              _row(context, Icons.credit_card_outlined, "Destino (tarjeta)",
                                  toCardName!),
                            ],
                          ],
                          if (transaction.currencyCode.isNotEmpty) ...[
                            _divider(context),
                            _row(
                              context,
                              Icons.monetization_on_outlined,
                              "Moneda",
                              "${transaction.currencySymbol} ${transaction.currencyCode}".trim(),
                            ),
                          ],
                          if (transaction.isRecurring) ...[
                            _divider(context),
                            _row(context, Icons.repeat, "Origen", "Regla recurrente"),
                          ],
                          if (transaction.description != null &&
                              transaction.description!.isNotEmpty) ...[
                            _divider(context),
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
                color: context.colorBackground,
                boxShadow: context.shadowCard,
              ),
              child: PrimaryButton(
                label: "Replicar movimiento",
                icon: Icons.copy_all_outlined,
                onPressed: () => _replicate(context),
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
          Icon(icon, size: 18, color: context.colorMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: context.textBody2(color: context.colorTextSecondary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: context.textSubtitle2(color: context.colorTextPrimary),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: context.colorBorder,
        indent: 46,
      );
}
