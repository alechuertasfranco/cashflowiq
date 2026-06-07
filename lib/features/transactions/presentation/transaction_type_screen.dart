// lib/features/transactions/presentation/transaction_type_screen.dart

import 'package:cashflowiq/features/transactions/presentation/expense_transaction/expense_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/income_transaction/income_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/recurring/recurring_transactions_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/transfer_transaction/transfer_screen.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/transactions/presentation/widgets/transaction_type_card.dart';

class TransactionTypeScreen extends StatelessWidget {
  const TransactionTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Text("¿Qué quieres registrar?", style: AppTextStyles.h300(context)),
              const SizedBox(height: 4),
              Text("Selecciona el tipo de movimiento", style: AppTextStyles.caption(context)),

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
                      color: AppColors.success,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeScreen())),
                    ),
                    TransactionTypeCard(
                      title: "Gasto",
                      description: "Salida de dinero",
                      icon: Icons.arrow_upward,
                      color: AppColors.error,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen())),
                    ),
                    TransactionTypeCard(
                      title: "Transferencia",
                      description: "Entre tus cuentas",
                      icon: Icons.swap_horiz,
                      color: AppColors.primary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen())),
                    ),
                    TransactionTypeCard(
                      title: "Split",
                      description: "Gasto compartido",
                      icon: Icons.group,
                      color: AppColors.primary,
                      onTap: () {
                        // TODO: navegar a form split
                      },
                    ),
                    TransactionTypeCard(
                      title: "Recurrentes",
                      description: "Reglas automáticas",
                      icon: Icons.repeat,
                      color: AppColors.accent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecurringTransactionsScreen()),
                      ),
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
