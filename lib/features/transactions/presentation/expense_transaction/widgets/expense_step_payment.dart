// lib/features/transactions/presentation/expense_transaction/widgets/expense_step_payment.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/core/widgets/sub_step_switcher.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:flutter/material.dart';

class ExpenseStepPayment extends StatelessWidget {
  final List<BankEntity> entities;
  final BankEntity? selectedEntity;
  final BankAccount? selectedAccount;
  final CreditCard? selectedCreditCard;
  final String viewKey;
  final bool goingForward;
  final List<BankAccount> Function(BankEntity) accountsFor;
  final List<CreditCard> Function(BankEntity) cardsFor;
  final void Function(BankEntity) onEntityTap;
  final void Function(BankAccount) onAccountTap;
  final void Function(CreditCard) onCardTap;
  final VoidCallback onBack;
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;
  final List<BankAccount> mostUsedAccounts;
  final List<CreditCard> mostUsedCreditCards;

  const ExpenseStepPayment({
    super.key,
    required this.entities,
    required this.selectedEntity,
    required this.selectedAccount,
    required this.selectedCreditCard,
    required this.viewKey,
    required this.goingForward,
    required this.accountsFor,
    required this.cardsFor,
    required this.onEntityTap,
    required this.onAccountTap,
    required this.onCardTap,
    required this.onBack,
    required this.onAddAccount,
    required this.onAddCreditCard,
    this.mostUsedAccounts = const [],
    this.mostUsedCreditCards = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SubStepSwitcher(
      viewKey: viewKey,
      goingForward: goingForward,
      child: selectedEntity != null
          ? _AccountsView(
              entity: selectedEntity!,
              accounts: accountsFor(selectedEntity!),
              cards: cardsFor(selectedEntity!),
              selectedAccount: selectedAccount,
              selectedCreditCard: selectedCreditCard,
              onAccountTap: onAccountTap,
              onCardTap: onCardTap,
              onBack: onBack,
              onAddAccount: onAddAccount,
              onAddCreditCard: onAddCreditCard,
            )
          : _EntityListView(
              entities: entities,
              accountsFor: accountsFor,
              cardsFor: cardsFor,
              onEntityTap: onEntityTap,
              onAccountTap: onAccountTap,
              onCardTap: onCardTap,
              onAddAccount: onAddAccount,
              onAddCreditCard: onAddCreditCard,
              mostUsedAccounts: mostUsedAccounts,
              mostUsedCreditCards: mostUsedCreditCards,
            ),
    );
  }
}

// ── Entity list ──────────────────────────────────────────────────────────────

class _EntityListView extends StatelessWidget {
  final List<BankEntity> entities;
  final List<BankAccount> Function(BankEntity) accountsFor;
  final List<CreditCard> Function(BankEntity) cardsFor;
  final void Function(BankEntity) onEntityTap;
  final void Function(BankAccount) onAccountTap;
  final void Function(CreditCard) onCardTap;
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;
  final List<BankAccount> mostUsedAccounts;
  final List<CreditCard> mostUsedCreditCards;

  const _EntityListView({
    required this.entities,
    required this.accountsFor,
    required this.cardsFor,
    required this.onEntityTap,
    required this.onAccountTap,
    required this.onCardTap,
    required this.onAddAccount,
    required this.onAddCreditCard,
    this.mostUsedAccounts = const [],
    this.mostUsedCreditCards = const [],
  });

  @override
  Widget build(BuildContext context) {
    final showQuickAccess = mostUsedAccounts.isNotEmpty || mostUsedCreditCards.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("¿Con qué pagaste?", style: AppTextStyles.h400(context)),
          if (showQuickAccess) ...[
            const SizedBox(height: 16),
            _QuickAccessRow(
              accounts: mostUsedAccounts,
              cards: mostUsedCreditCards,
              onAccountTap: onAccountTap,
              onCardTap: onCardTap,
            ),
          ],
          const SizedBox(height: 20),
          if (entities.isEmpty)
            _EmptyPaymentHint(onAddAccount: onAddAccount, onAddCreditCard: onAddCreditCard)
          else ...[
            ...entities.map((e) => _EntityTile(
                  entity: e,
                  accounts: accountsFor(e),
                  cards: cardsFor(e),
                  onTap: () => onEntityTap(e),
                )),
            const SizedBox(height: 8),
            _AddRow(onAddAccount: onAddAccount, onAddCreditCard: onAddCreditCard),
          ],
        ],
      ),
    );
  }
}

class _EmptyPaymentHint extends StatelessWidget {
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;

  const _EmptyPaymentHint({
    required this.onAddAccount,
    required this.onAddCreditCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Aún no tienes cuentas ni tarjetas registradas.",
          style: AppTextStyles.body2(context, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        _AddRow(onAddAccount: onAddAccount, onAddCreditCard: onAddCreditCard),
      ],
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  final List<BankAccount> accounts;
  final List<CreditCard> cards;
  final void Function(BankAccount) onAccountTap;
  final void Function(CreditCard) onCardTap;

  const _QuickAccessRow({
    required this.accounts,
    required this.cards,
    required this.onAccountTap,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    const maxSlots = 3;
    final items = <Widget>[];
    var ai = 0;
    var ci = 0;
    while (items.length < maxSlots && (ai < accounts.length || ci < cards.length)) {
      if (ai < accounts.length) {
        final a = accounts[ai++];
        items.add(_QuickAccessCard(
          icon: Icons.account_balance,
          name: a.name,
          entityCode: a.bankEntity.code,
          onTap: () => onAccountTap(a),
        ));
      }
      if (items.length < maxSlots && ci < cards.length) {
        final c = cards[ci++];
        items.add(_QuickAccessCard(
          icon: Icons.credit_card,
          name: c.name,
          entityCode: c.bankEntity.code,
          onTap: () => onCardTap(c),
        ));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Más usado",
          style: AppTextStyles.caption(context, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items
                .expand((w) => [w, const SizedBox(width: 8)])
                .toList()
              ..removeLast(),
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String entityCode;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.name,
    required this.entityCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entityCode,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(name, style: AppTextStyles.caption(context, color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityTile extends StatelessWidget {
  final BankEntity entity;
  final List<BankAccount> accounts;
  final List<CreditCard> cards;
  final VoidCallback onTap;

  const _EntityTile({
    required this.entity,
    required this.accounts,
    required this.cards,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(entity.colorHex);
    final parts = <String>[
      if (accounts.isNotEmpty)
        "${accounts.length} cuenta${accounts.length > 1 ? 's' : ''}",
      if (cards.isNotEmpty)
        "${cards.length} tarjeta${cards.length > 1 ? 's' : ''}",
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

class _AccountsView extends StatelessWidget {
  final BankEntity entity;
  final List<BankAccount> accounts;
  final List<CreditCard> cards;
  final BankAccount? selectedAccount;
  final CreditCard? selectedCreditCard;
  final void Function(BankAccount) onAccountTap;
  final void Function(CreditCard) onCardTap;
  final VoidCallback onBack;
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;

  const _AccountsView({
    required this.entity,
    required this.accounts,
    required this.cards,
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
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 13),
            label: const Text("Entidades"),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
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
            "Selecciona una cuenta o tarjeta",
            style: AppTextStyles.body2(context, color: AppColors.textSecondary),
          ),
          if (accounts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              "Cuentas bancarias",
              style: AppTextStyles.body2(context, color: entityColor),
            ),
            const SizedBox(height: 10),
            ...accounts.map((a) => _AccountCard(
                  account: a,
                  isSelected: selectedAccount?.id == a.id,
                  onTap: () => onAccountTap(a),
                )),
          ],
          if (cards.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              "Tarjetas de crédito",
              style: AppTextStyles.body2(context, color: entityColor),
            ),
            const SizedBox(height: 10),
            ...cards.map((c) => _CreditCardCard(
                  card: c,
                  isSelected: selectedCreditCard?.id == c.id,
                  onTap: () => onCardTap(c),
                )),
          ],
          const SizedBox(height: 8),
          _AddRow(onAddAccount: onAddAccount, onAddCreditCard: onAddCreditCard),
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
          color: isSelected ? AppColors.error.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.error : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance, size: 20,
                color: isSelected ? AppColors.error : AppColors.muted),
            const SizedBox(width: 12),
            Expanded(child: Text(account.name, style: AppTextStyles.subtitle2(context))),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.error, size: 20),
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
          color: isSelected ? AppColors.error.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.error : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.credit_card, size: 20,
                color: isSelected ? AppColors.error : AppColors.muted),
            const SizedBox(width: 12),
            Expanded(child: Text(card.name, style: AppTextStyles.subtitle2(context))),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.error, size: 20),
          ],
        ),
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
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;

  const _AddRow({required this.onAddAccount, required this.onAddCreditCard});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAddAccount,
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Cuenta"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
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
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
