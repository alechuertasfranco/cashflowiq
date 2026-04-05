// lib/features/credit_cards/presentation/credit_cards_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/swipe_to_delete.dart';
import 'package:cashflowiq/features/credit_cards/data/credit_card_service.dart';
import 'package:cashflowiq/features/credit_cards/presentation/form_credit_card_screen.dart';
import 'package:cashflowiq/features/credit_cards/widgets/card.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Tarjetas de crédito", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.complementary,
        onPressed: _goToCreateCard,
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
                    if (_cards.isNotEmpty)
                      /// 🔹 LÍNEA TOTAL
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Línea total", style: AppTextStyles.caption(context)),
                            const SizedBox(height: 4),

                            if (limitsByCurrency.isEmpty)
                              Text("0", style: AppTextStyles.balance(context))
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: limitsByCurrency.entries.map((entry) {
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

                    /// 🔹 EMPTY STATE
                    if (_cards.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.credit_card_outlined, size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              Text("No tienes tarjetas", style: AppTextStyles.subtitle1(context)),
                              const SizedBox(height: 8),
                              Text(
                                "Agrega una tarjeta para gestionar tu deuda inteligentemente",
                                style: AppTextStyles.caption(context),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _goToCreateCard, child: const Text("Agregar tarjeta")),
                            ],
                          ),
                        ),
                      )
                    /// 🔹 LISTA
                    else
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadCards,
                          child: ListView.separated(
                            itemCount: _cards.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final card = _cards[index];

                              return SwipeToDelete(
                                onDelete: () => _deleteCard(card),
                                child: CreditCardCard(card: card, onTap: () => _goToEditCard(card)),
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
