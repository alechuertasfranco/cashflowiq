// lib/features/bank_accounts/presentation/bank_accounts_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/swipe_to_delete.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/presentation/bank_accounts/form_account_screen.dart';
import 'package:cashflowiq/features/profile/presentation/bank_accounts/widgets/card.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/money.dart';
import 'package:flutter/material.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  final BankAccountService _service = BankAccountService();

  List<BankAccount> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);

    try {
      final accounts = await _service.getAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts..sort((a, b) => b.initialAmount.compareTo(a.initialAmount));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint("Error cargando cuentas: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error cargando cuentas")));
    }
  }

  /// ✅ Agrupar balances por moneda usando Money
  Map<Currency, Money> _getBalancesByCurrency() {
    final Map<Currency, Money> totals = {};

    for (final acc in _accounts) {
      totals.update(acc.currency, (value) => value.add(acc.balance), ifAbsent: () => acc.balance);
    }

    return totals;
  }

  /// ➕ Crear cuenta
  Future<void> _goToCreateAccount() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormAccountScreen()));

    if (result == true) {
      _loadAccounts();
    }
  }

  /// ✏️ Editar cuenta
  Future<void> _goToEditAccount(BankAccount account) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormAccountScreen(account: account)),
    );

    if (result == true) {
      _loadAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final balancesByCurrency = _getBalancesByCurrency();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Cuentas bancarias", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _goToCreateAccount,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_accounts.isEmpty)
              ? Expanded(
                  child: InsightEmptyState(
                    icon: Icons.account_balance_outlined,
                    title: "No tienes cuentas bancarias",
                    description: "Agrega una cuenta para empezar a entender tu dinero",
                    actionText: "Crear cuenta",
                    onAction: _goToCreateAccount,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔹 BALANCES
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Balance total", style: AppTextStyles.caption(context)),
                          const SizedBox(height: 4),

                          if (balancesByCurrency.isEmpty)
                            Text("0", style: AppTextStyles.balance(context))
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: balancesByCurrency.entries.map((entry) {
                                final money = entry.value;

                                return Text(
                                  "${money.currency.flag ?? ''} ${money.format()}",
                                  style: AppTextStyles.balance(context),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          DataCache.instance.invalidate('accounts');
                          await _loadAccounts();
                        },
                        child: ListView.separated(
                          itemCount: _accounts.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final account = _accounts[index];

                            return SwipeToDelete(
                              onDelete: () async {
                                final messenger = ScaffoldMessenger.of(context);

                                await _service.deleteAccount(account.id);
                                await _loadAccounts();

                                if (!mounted) return;

                                messenger.showSnackBar(const SnackBar(content: Text("Cuenta eliminada")));
                              },
                              child: BankAccountCard(account: account, onTap: () => _goToEditAccount(account)),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
