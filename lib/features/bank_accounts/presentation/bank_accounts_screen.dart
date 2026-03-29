// lib/features/bank_accounts/presentation/bank_accounts_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/swipe_to_delete.dart';
import 'package:cashflowiq/features/bank_accounts/data/bank_account_service.dart';
import 'package:cashflowiq/features/bank_accounts/presentation/form_account_screen.dart';
import 'package:cashflowiq/features/bank_accounts/widgets/card.dart';
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
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error cargando cuentas")));
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

    // 🔁 Refrescar si hubo cambios
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

    // 🔁 Refrescar si hubo cambios
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
        child: const Icon(Icons.add, color: Color(0xFFFFFFFF)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 🔹 Balance total
                          Text("Balance total", style: AppTextStyles.caption(context)),
                          const SizedBox(height: 4),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: balancesByCurrency.entries.map((entry) {
                              final money = entry.value;
                              return Text(
                                "${money.currency.flag} ${money.format()}",
                                style: AppTextStyles.balance(context),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// 🔹 Estado vacío
                    if (_accounts.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.account_balance_outlined, size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              Text("No tienes cuentas bancarias", style: AppTextStyles.subtitle1(context)),
                              const SizedBox(height: 8),
                              Text(
                                "Agrega una cuenta para empezar a entender tu dinero",
                                style: AppTextStyles.caption(context),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _goToCreateAccount, child: const Text("Crear cuenta")),
                            ],
                          ),
                        ),
                      )
                    /// 🔹 Lista
                    else
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadAccounts,
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
