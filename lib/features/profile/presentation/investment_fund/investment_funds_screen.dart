// lib/features/investment_fund/presentation/investment_funds_screen.dart

import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/skeleton_loader.dart';
import 'package:cashflowiq/core/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/swipe_to_delete.dart';

import 'package:cashflowiq/features/profile/data/investment_fund_service.dart';
import 'package:cashflowiq/features/profile/presentation/investment_fund/form_investment_fund_screen.dart';
import 'package:cashflowiq/features/profile/presentation/investment_fund/fund_detail_screen.dart';
import 'package:cashflowiq/features/profile/presentation/investment_fund/widgets/card.dart';

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
        _funds = funds..sort((a, b) => b.investedAmount.compareTo(a.investedAmount));
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

  /// 🔍 Ver detalle / historial
  Future<void> _goToDetail(InvestmentFund fund) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FundDetailScreen(fund: fund)),
    );
    // Snapshot writes and the detail screen's current_value self-heal each
    // invalidate this cache themselves when they actually change something,
    // so a plain reload here is enough — no need to force-bust the cache.
    _loadFunds();
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
      backgroundColor: context.colorBackground,
      appBar: const AppHeaderBar(title: "Inversiones"),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colorComplementary,
        onPressed: _goToCreate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _isLoading
              ? const SkeletonListLoader()
              : _funds.isEmpty
              ? Expanded(
                  child: InsightEmptyState(
                    icon: Icons.trending_up,
                    title: "No tienes inversiones",
                    description: "Empieza a construir tu patrimonio registrando inversiones",
                    actionText: "Agregar inversión",
                    onAction: _goToCreate,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Total invertido", style: context.textCaption()),
                          const SizedBox(height: 4),

                          if (totals.isEmpty)
                            Text("0", style: context.textBalance())
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: totals.entries.map((entry) {
                                final money = entry.value;

                                return Text(
                                  "${money.currency.flag ?? ''} ${money.format()}",
                                  style: context.textBalance(),
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
                          DataCache.instance.invalidate('investment_funds');
                          await _loadFunds();
                        },
                        child: ListView.separated(
                          itemCount: _funds.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final fund = _funds[index];

                            return StaggeredFadeIn(
                              index: index,
                              child: SwipeToDelete(
                                onDelete: () => _delete(fund),
                                child: InvestmentFundCard(fund: fund, onTap: () => _goToDetail(fund)),
                              ),
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
