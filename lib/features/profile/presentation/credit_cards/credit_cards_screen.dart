// lib/features/credit_cards/presentation/credit_cards_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/skeleton_loader.dart';
import 'package:cashflowiq/core/widgets/staggered_fade_in.dart';
import 'package:cashflowiq/core/widgets/swipe_to_delete.dart';
import 'package:cashflowiq/features/profile/data/credit_card_service.dart';
import 'package:cashflowiq/features/profile/presentation/credit_cards/form_credit_card_screen.dart';
import 'package:cashflowiq/features/profile/presentation/credit_cards/widgets/card.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/money.dart';
import 'package:flutter/material.dart';

class CreditCardsScreen extends StatefulWidget {
  const CreditCardsScreen({super.key});

  @override
  State<CreditCardsScreen> createState() => _CreditCardsScreenState();
}

class _CreditCardsScreenState extends State<CreditCardsScreen> {
  final CreditCardService _service = CreditCardService();

  List<CreditCard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);

    try {
      final cards = await _service.getCreditCards();
      if (!mounted) return;

      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading credit cards: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error cargando tarjetas")));
    }
  }

  /// 💳 Agrupar línea de crédito por moneda
  Map<Currency, Money> _getCreditLimitsByCurrency() {
    final Map<Currency, Money> totals = {};

    for (final card in _cards) {
      final limit = card.creditLimitMoney;

      totals.update(card.currency, (value) => value.add(limit), ifAbsent: () => limit);
    }

    return totals;
  }

  /// ➕ Crear tarjeta
  Future<void> _goToCreateCard() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormCreditCardScreen()));

    if (result == true) _loadCards();
  }

  /// ✏️ Editar tarjeta
  Future<void> _goToEditCard(CreditCard card) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => FormCreditCardScreen(card: card)));

    if (result == true) _loadCards();
  }

  /// ❌ DELETE
  Future<void> _deleteCard(CreditCard card) async {
    final messenger = ScaffoldMessenger.of(context);

    await _service.deleteCreditCard(card.id);
    await _loadCards();

    if (!mounted) return;

    messenger.showSnackBar(const SnackBar(content: Text("Tarjeta eliminada")));
  }

  @override
  Widget build(BuildContext context) {
    final limitsByCurrency = _getCreditLimitsByCurrency();

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: const AppHeaderBar(title: "Tarjetas de crédito"),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colorComplementary,
        onPressed: _goToCreateCard,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _isLoading
              ? const SkeletonListLoader()
              : _cards.isEmpty
              ? Expanded(
                  child: InsightEmptyState(
                    icon: Icons.credit_card_outlined,
                    title: "No tienes tarjetas",
                    description: "Agrega una tarjeta para gestionar tu deuda inteligentemente",
                    actionText: "Agregar tarjeta",
                    onAction: _goToCreateCard,
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
                          Text("Línea total", style: context.textCaption()),
                          const SizedBox(height: 4),

                          if (limitsByCurrency.isEmpty)
                            Text("0", style: context.textBalance())
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: limitsByCurrency.entries.map((entry) {
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
                          DataCache.instance.invalidate('credit_cards');
                          await _loadCards();
                        },
                        child: ListView.separated(
                          itemCount: _cards.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final card = _cards[index];

                            return StaggeredFadeIn(
                              index: index,
                              child: SwipeToDelete(
                                onDelete: () => _deleteCard(card),
                                child: CreditCardCard(card: card, onTap: () => _goToEditCard(card)),
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
