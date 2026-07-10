// lib/features/transactions/presentation/transfer_transaction/transfer_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/skeleton_loader.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:cashflowiq/features/transactions/presentation/transfer_transaction/transfer_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';

class TransferScreen extends StatefulWidget {
  final Transaction? prefill;
  final bool editMode;

  const TransferScreen({super.key, this.prefill, this.editMode = false});

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
      backgroundColor: context.colorBackground,
      appBar: AppHeaderBar(title: widget.editMode ? "Editar transferencia" : "Nueva transferencia"),
      body: SafeArea(
        child: isLoading
            ? const SkeletonListLoader()
            : accounts.isEmpty
            ? _emptyState()
            : TransferFormScreen(prefill: widget.prefill, editMode: widget.editMode),
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
