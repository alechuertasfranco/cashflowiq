// lib/features/investment_fund/presentation/investment_funds_screen.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/swipe_to_delete.dart';

import 'package:cashflowiq/features/investment_fund/data/investment_fund_service.dart';
import 'package:cashflowiq/features/investment_fund/presentation/form_investment_fund_screen.dart';
import 'package:cashflowiq/features/investment_fund/widgets/card.dart';

import 'package:cashflowiq/shared/models/investment_fund.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/money.dart';

class InvestmentFundsScreen extends StatefulWidget {
  const InvestmentFundsScreen({super.key});

  @override
  State<InvestmentFundsScreen> createState() => _InvestmentFundsScreenState();
}

class _InvestmentFundsScreenState extends State<InvestmentFundsScreen> {
  final InvestmentFundService _service = InvestmentFundService();

  List<InvestmentFund> _funds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFunds();
  }

  Future<void> _loadFunds() async {
    setState(() => _isLoading = true);

    try {
      final funds = await _service.getFunds();

      if (!mounted) return;

      setState(() {
        _funds = funds;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading funds: $e");

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error cargando inversiones")));
    }
  }

  /// 💰 TOTAL INVERTIDO (por moneda)
  Map<Currency, Money> _getInvestedByCurrency() {
    final Map<Currency, Money> totals = {};

    for (final fund in _funds) {
      final invested = fund.investedMoney;

      totals.update(fund.currency, (value) => value.add(invested), ifAbsent: () => invested);
    }

    return totals;
  }

  /// ➕ Crear
  Future<void> _goToCreate() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormInvestmentFundScreen()));

    if (result == true) _loadFunds();
  }

  /// ✏️ Editar
  Future<void> _goToEdit(InvestmentFund fund) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormInvestmentFundScreen(fund: fund)),
    );

    if (result == true) _loadFunds();
  }

  /// ❌ Delete
  Future<void> _delete(InvestmentFund fund) async {
    final messenger = ScaffoldMessenger.of(context);

    await _service.deleteFund(fund.id);
    await _loadFunds();

    if (!mounted) return;

    messenger.showSnackBar(const SnackBar(content: Text("Inversión eliminada")));
  }

  @override
  Widget build(BuildContext context) {
    final totals = _getInvestedByCurrency();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Inversiones", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.complementary,
        onPressed: _goToCreate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 💰 TOTAL INVERTIDO
                    if (_funds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total invertido", style: AppTextStyles.caption(context)),
                            const SizedBox(height: 4),

                            if (totals.isEmpty)
                              Text("0", style: AppTextStyles.balance(context))
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: totals.entries.map((entry) {
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

                    /// EMPTY
                    if (_funds.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.trending_up, size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              Text("No tienes inversiones", style: AppTextStyles.subtitle1(context)),
                              const SizedBox(height: 8),
                              Text(
                                "Empieza a construir tu patrimonio registrando inversiones",
                                style: AppTextStyles.caption(context),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _goToCreate, child: const Text("Agregar inversión")),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadFunds,
                          child: ListView.separated(
                            itemCount: _funds.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final fund = _funds[index];

                              return SwipeToDelete(
                                onDelete: () => _delete(fund),
                                child: InvestmentFundCard(fund: fund, onTap: () => _goToEdit(fund)),
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
