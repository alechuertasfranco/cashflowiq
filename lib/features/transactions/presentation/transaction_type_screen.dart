// lib/features/transactions/presentation/transaction_type_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/features/splits/screens/split_form_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/expense_transaction/expense_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/income_transaction/income_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/recurring/recurring_transactions_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/transfer_transaction/transfer_screen.dart';
import 'package:cashflowiq/features/statements/presentation/statement_import_screen.dart';
import 'package:cashflowiq/features/voucher/presentation/voucher_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/features/transactions/presentation/widgets/transaction_type_card.dart';

class TransactionTypeScreen extends StatelessWidget {
  const TransactionTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Text("¿Qué quieres registrar?", style: context.heading3()),
              const SizedBox(height: 4),
              Text("Selecciona el tipo de movimiento", style: context.textCaption()),

              const SizedBox(height: 24),

              /// Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    TransactionTypeCard(
                      title: "Ingreso",
                      description: "Entrada de dinero",
                      icon: Icons.arrow_downward,
                      color: context.colorSuccess,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeScreen())),
                    ),
                    TransactionTypeCard(
                      title: "Gasto",
                      description: "Salida de dinero",
                      icon: Icons.arrow_upward,
                      color: context.colorError,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen())),
                    ),
                    TransactionTypeCard(
                      title: "Transferencia",
                      description: "Entre tus cuentas",
                      icon: Icons.swap_horiz,
                      color: context.colorPrimary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen())),
                    ),
                    TransactionTypeCard(
                      title: "Recurrentes",
                      description: "Reglas automáticas",
                      icon: Icons.repeat,
                      color: context.colorAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecurringTransactionsScreen()),
                      ),
                    ),
                    TransactionTypeCard(
                      title: "Split",
                      description: "Gasto compartido",
                      icon: Icons.group,
                      color: context.colorPrimary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SplitFormScreen())),
                    ),
                    TransactionTypeCard(
                      title: "Voucher",
                      description: "Escanear comprobante",
                      icon: Icons.document_scanner,
                      color: context.colorAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherScanScreen())),
                    ),
                    TransactionTypeCard(
                      title: "Estado de cuenta",
                      description: "Importar y conciliar",
                      icon: Icons.upload_file,
                      color: context.colorPrimary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatementImportScreen())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
