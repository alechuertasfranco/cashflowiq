// lib/features/transactions/presentation/transfer_transaction/transfer_screen.dart

import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:cashflowiq/features/transactions/presentation/transfer_transaction/transfer_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';

class TransferScreen extends StatefulWidget {
  final Transaction? prefill;

  const TransferScreen({super.key, this.prefill});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _accountService = BankAccountService();

  bool isLoading = true;
  List<BankAccount> accounts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _accountService.getAccounts();
      setState(() {
        accounts = data;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Nueva transferencia", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : accounts.isEmpty
            ? _emptyState()
            : TransferFormScreen(accounts: accounts, prefill: widget.prefill),
      ),
    );
  }

  Widget _emptyState() {
    return InsightEmptyState(
      icon: Icons.account_balance,
      title: "Necesitas al menos 1 cuenta",
      description: "Para registrar una transferencia debes tener al menos una cuenta bancaria activa",
      actionText: "Ir a mis cuentas",
      onAction: () => Navigator.pop(context),
    );
  }
}
