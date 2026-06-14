// lib/features/transactions/presentation/recurring/widgets/recurring_step_account.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/core/widgets/currency_dropdown.dart';
import 'package:cashflowiq/core/widgets/sub_step_switcher.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:flutter/material.dart';

class RecurringStepAccount extends StatelessWidget {
  final String type; // 'INCOME' | 'EXPENSE'
  final String paymentSource; // 'account' | 'card' (for EXPENSE)
  final List<BankEntity> accountEntities;
  final List<BankEntity> cardEntities;
  final BankEntity? selectedEntity;
  final BankAccount? selectedAccount;
  final CreditCard? selectedCreditCard;
  final String viewKey;
  final bool goingForward;
  final List<BankAccount> Function(BankEntity) accountsFor;
  final List<CreditCard> Function(BankEntity) cardsFor;
  final List<Currency> currencies;
  final Currency? selectedCurrency;
  final void Function(String) onPaymentSourceChanged;
  final void Function(BankEntity) onEntityTap;
  final void Function(BankAccount) onAccountTap;
  final void Function(CreditCard) onCardTap;
  final VoidCallback onBack;
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;
  final void Function(Currency?) onCurrencyChanged;

  const RecurringStepAccount({
    super.key,
    required this.type,
    required this.paymentSource,
    required this.accountEntities,
    required this.cardEntities,
    required this.selectedEntity,
    required this.selectedAccount,
    required this.selectedCreditCard,
    required this.viewKey,
    required this.goingForward,
    required this.accountsFor,
    required this.cardsFor,
    required this.currencies,
    required this.selectedCurrency,
    required this.onPaymentSourceChanged,
    required this.onEntityTap,
    required this.onAccountTap,
    required this.onCardTap,
    required this.onBack,
    required this.onAddAccount,
    required this.onAddCreditCard,
    required this.onCurrencyChanged,
  });

  List<BankEntity> get _activeEntities =>
      (type == 'INCOME' || paymentSource == 'account') ? accountEntities : cardEntities;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Payment source toggle (EXPENSE only)
        if (type == 'EXPENSE')
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _PaymentSourceToggle(
              paymentSource: paymentSource,
              onChanged: onPaymentSourceChanged,
            ),
          ),

        // Entity / accounts sub-step
        Expanded(
          child: SubStepSwitcher(
            viewKey: viewKey,
            goingForward: goingForward,
            child: selectedEntity != null
                ? _AccountsOrCardsView(
                    entity: selectedEntity!,
                    accounts: accountsFor(selectedEntity!),
                    cards: type == 'EXPENSE' && paymentSource == 'card'
                        ? cardsFor(selectedEntity!)
                        : [],
                    showCards: type == 'EXPENSE' && paymentSource == 'card',
                    selectedAccount: selectedAccount,
                    selectedCreditCard: selectedCreditCard,
                    onAccountTap: onAccountTap,
                    onCardTap: onCardTap,
                    onBack: onBack,
                    onAddAccount: onAddAccount,
                    onAddCreditCard: onAddCreditCard,
                  )
                : _EntityListView(
                    entities: _activeEntities,
                    accountsFor: accountsFor,
                    cardsFor: cardsFor,
                    showCards: type == 'EXPENSE' && paymentSource == 'card',
                    titleLabel: type == 'INCOME' ? "¿A qué cuenta?" : "¿Con qué pagas?",
                    onEntityTap: onEntityTap,
                    onAddAccount: onAddAccount,
                    onAddCreditCard: onAddCreditCard,
                  ),
          ),
        ),

        // Currency section (always visible at the bottom)
        _CurrencySection(
          selectedAccount: selectedAccount,
          selectedCreditCard: selectedCreditCard,
          currencies: currencies,
          selectedCurrency: selectedCurrency,
          onCurrencyChanged: onCurrencyChanged,
        ),
      ],
    );
  }
}

// ── Payment source toggle ────────────────────────────────────────────────────

class _PaymentSourceToggle extends StatelessWidget {
  final String paymentSource;
  final void Function(String) onChanged;

  const _PaymentSourceToggle({
    required this.paymentSource,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget option(String label, String value, bool left) {
      final selected = paymentSource == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(left ? 12 : 0),
                right: Radius.circular(left ? 0 : 12),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.body2(
                  context,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option("Cuenta bancaria", 'account', true),
        option("Tarjeta de crédito", 'card', false),
      ],
    );
  }
}

// ── Entity list ──────────────────────────────────────────────────────────────

class _EntityListView extends StatelessWidget {
  final List<BankEntity> entities;
  final List<BankAccount> Function(BankEntity) accountsFor;
  final List<CreditCard> Function(BankEntity) cardsFor;
  final bool showCards;
  final String titleLabel;
  final void Function(BankEntity) onEntityTap;
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;

  const _EntityListView({
    required this.entities,
    required this.accountsFor,
    required this.cardsFor,
    required this.showCards,
    required this.titleLabel,
    required this.onEntityTap,
    required this.onAddAccount,
    required this.onAddCreditCard,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titleLabel, style: AppTextStyles.h400(context)),
          const SizedBox(height: 20),
          if (entities.isEmpty)
            _EmptyHint(
              showCards: showCards,
              onAddAccount: onAddAccount,
              onAddCreditCard: onAddCreditCard,
            )
          else ...[
            ...entities.map((e) => _EntityTile(
                  entity: e,
                  accountCount: accountsFor(e).length,
                  cardCount: showCards ? cardsFor(e).length : 0,
                  showCards: showCards,
                  onTap: () => onEntityTap(e),
                )),
            const SizedBox(height: 8),
            _AddRow(
              showCards: showCards,
              onAddAccount: onAddAccount,
              onAddCreditCard: onAddCreditCard,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final bool showCards;
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;

  const _EmptyHint({
    required this.showCards,
    required this.onAddAccount,
    required this.onAddCreditCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showCards
              ? "Aún no tienes cuentas ni tarjetas registradas."
              : "Aún no tienes cuentas bancarias registradas.",
          style: AppTextStyles.body2(context, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        _AddRow(
          showCards: showCards,
          onAddAccount: onAddAccount,
          onAddCreditCard: onAddCreditCard,
        ),
      ],
    );
  }
}

class _EntityTile extends StatelessWidget {
  final BankEntity entity;
  final int accountCount;
  final int cardCount;
  final bool showCards;
  final VoidCallback onTap;

  const _EntityTile({
    required this.entity,
    required this.accountCount,
    required this.cardCount,
    required this.showCards,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(entity.colorHex);
    final parts = <String>[
      if (!showCards && accountCount > 0)
        "$accountCount cuenta${accountCount != 1 ? 's' : ''}",
      if (showCards && cardCount > 0)
        "$cardCount tarjeta${cardCount != 1 ? 's' : ''}",
      if (showCards && accountCount > 0)
        "$accountCount cuenta${accountCount != 1 ? 's' : ''}",
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _EntityBadge(entity: entity, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entity.name, style: AppTextStyles.subtitle2(context)),
                  if (parts.isNotEmpty)
                    Text(
                      parts.join(" · "),
                      style: AppTextStyles.body2(context, color: color),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Accounts / cards view ────────────────────────────────────────────────────

class _AccountsOrCardsView extends StatelessWidget {
  final BankEntity entity;
  final List<BankAccount> accounts;
  final List<CreditCard> cards;
  final bool showCards;
  final BankAccount? selectedAccount;
  final CreditCard? selectedCreditCard;
  final void Function(BankAccount) onAccountTap;
  final void Function(CreditCard) onCardTap;
  final VoidCallback onBack;
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;

  const _AccountsOrCardsView({
    required this.entity,
    required this.accounts,
    required this.cards,
    required this.showCards,
    required this.selectedAccount,
    required this.selectedCreditCard,
    required this.onAccountTap,
    required this.onCardTap,
    required this.onBack,
    required this.onAddAccount,
    required this.onAddCreditCard,
  });

  @override
  Widget build(BuildContext context) {
    final entityColor = parseHexColor(entity.colorHex);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 13),
            label: const Text("Entidades"),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _EntityBadge(entity: entity, size: 28),
              const SizedBox(width: 8),
              Expanded(child: Text(entity.name, style: AppTextStyles.h400(context))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            showCards ? "Selecciona una cuenta o tarjeta" : "Selecciona una cuenta",
            style: AppTextStyles.body2(context, color: AppColors.textSecondary),
          ),
          if (accounts.isNotEmpty && !showCards) ...[
            const SizedBox(height: 20),
            Text("Cuentas bancarias", style: AppTextStyles.body2(context, color: entityColor)),
            const SizedBox(height: 10),
            ...accounts.map((a) => _AccountCard(
                  account: a,
                  isSelected: selectedAccount?.id == a.id,
                  onTap: () => onAccountTap(a),
                )),
          ],
          if (accounts.isNotEmpty && showCards) ...[
            const SizedBox(height: 20),
            Text("Cuentas bancarias", style: AppTextStyles.body2(context, color: entityColor)),
            const SizedBox(height: 10),
            ...accounts.map((a) => _AccountCard(
                  account: a,
                  isSelected: selectedAccount?.id == a.id,
                  onTap: () => onAccountTap(a),
                )),
          ],
          if (cards.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text("Tarjetas de crédito", style: AppTextStyles.body2(context, color: entityColor)),
            const SizedBox(height: 10),
            ...cards.map((c) => _CreditCardCard(
                  card: c,
                  isSelected: selectedCreditCard?.id == c.id,
                  onTap: () => onCardTap(c),
                )),
          ],
          const SizedBox(height: 8),
          _AddRow(
            showCards: showCards,
            onAddAccount: onAddAccount,
            onAddCreditCard: onAddCreditCard,
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final BankAccount account;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountCard({required this.account, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance, size: 20,
                color: isSelected ? AppColors.primary : AppColors.muted),
            const SizedBox(width: 12),
            Expanded(child: Text(account.name, style: AppTextStyles.subtitle2(context))),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CreditCardCard extends StatelessWidget {
  final CreditCard card;
  final bool isSelected;
  final VoidCallback onTap;

  const _CreditCardCard({required this.card, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.credit_card, size: 20,
                color: isSelected ? AppColors.primary : AppColors.muted),
            const SizedBox(width: 12),
            Expanded(child: Text(card.name, style: AppTextStyles.subtitle2(context))),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Currency section ──────────────────────────────────────────────────────────

class _CurrencySection extends StatelessWidget {
  final BankAccount? selectedAccount;
  final CreditCard? selectedCreditCard;
  final List<Currency> currencies;
  final Currency? selectedCurrency;
  final void Function(Currency?) onCurrencyChanged;

  const _CurrencySection({
    required this.selectedAccount,
    required this.selectedCreditCard,
    required this.currencies,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Currency? derived = selectedCreditCard != null
        ? selectedCreditCard!.currency
        : selectedAccount?.currency;
    final String? fromLabel = selectedCreditCard != null
        ? "(desde la tarjeta)"
        : selectedAccount != null
            ? "(desde la cuenta)"
            : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Moneda",
              style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          if (derived != null && fromLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text("${derived.flag} ${derived.code}",
                      style: AppTextStyles.body1(context)),
                  const SizedBox(width: 8),
                  Text(fromLabel,
                      style: AppTextStyles.caption(context, color: AppColors.muted)),
                ],
              ),
            )
          else
            CurrencyDropdown(
              currencies: currencies,
              value: selectedCurrency,
              onChanged: onCurrencyChanged,
            ),
        ],
      ),
    );
  }
}

// ── Shared: entity badge & add row ────────────────────────────────────────────

class _EntityBadge extends StatelessWidget {
  final BankEntity entity;
  final double size;

  const _EntityBadge({required this.entity, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(entity.colorHex);
    final label = entity.code.substring(0, entity.code.length.clamp(0, 3));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.25)),
      child: Center(
        child: Text(label, style: AppTextStyles.caption(context, color: getContrastColor(color))),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  final bool showCards;
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;

  const _AddRow({
    required this.showCards,
    required this.onAddAccount,
    required this.onAddCreditCard,
  });

  @override
  Widget build(BuildContext context) {
    if (!showCards) {
      return OutlinedButton.icon(
        onPressed: onAddAccount,
        icon: const Icon(Icons.add, size: 16),
        label: const Text("Agregar cuenta"),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAddAccount,
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Cuenta"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAddCreditCard,
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Tarjeta"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
