// lib/features/transactions/presentation/transfer_transaction/widgets/transfer_step_to.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/core/widgets/sub_step_switcher.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:flutter/material.dart';

class TransferStepTo extends StatelessWidget {
  final String destinationType; // 'account' | 'card'
  final List<BankEntity> accountEntities;
  final List<BankEntity> cardEntities;
  final BankEntity? selectedEntity;
  final BankAccount? selectedAccount;
  final CreditCard? selectedCreditCard;
  final String viewKey;
  final bool goingForward;
  final List<BankAccount> Function(BankEntity) accountsFor;
  final List<CreditCard> Function(BankEntity) cardsFor;
  final void Function(String) onTypeChanged;
  final void Function(BankEntity) onEntityTap;
  final void Function(BankAccount) onAccountTap;
  final void Function(CreditCard) onCardTap;
  final VoidCallback onBack;
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;

  const TransferStepTo({
    super.key,
    required this.destinationType,
    required this.accountEntities,
    required this.cardEntities,
    required this.selectedEntity,
    required this.selectedAccount,
    required this.selectedCreditCard,
    required this.viewKey,
    required this.goingForward,
    required this.accountsFor,
    required this.cardsFor,
    required this.onTypeChanged,
    required this.onEntityTap,
    required this.onAccountTap,
    required this.onCardTap,
    required this.onBack,
    required this.onAddAccount,
    required this.onAddCreditCard,
  });

  @override
  Widget build(BuildContext context) {
    final isAccount = destinationType == 'account';
    final entities = isAccount ? accountEntities : cardEntities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          child: _DestinationToggle(
            destinationType: destinationType,
            onTypeChanged: onTypeChanged,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SubStepSwitcher(
            viewKey: viewKey,
            goingForward: goingForward,
            child: selectedEntity != null
                ? (isAccount
                    ? _AccountsView(
                        entity: selectedEntity!,
                        accounts: accountsFor(selectedEntity!),
                        selectedAccount: selectedAccount,
                        onAccountTap: onAccountTap,
                        onBack: onBack,
                        onAddAccount: onAddAccount,
                      )
                    : _CardsView(
                        entity: selectedEntity!,
                        cards: cardsFor(selectedEntity!),
                        selectedCreditCard: selectedCreditCard,
                        onCardTap: onCardTap,
                        onBack: onBack,
                        onAddCreditCard: onAddCreditCard,
                      ))
                : _EntityListView(
                    entities: entities,
                    isAccount: isAccount,
                    accountsFor: accountsFor,
                    cardsFor: cardsFor,
                    onEntityTap: onEntityTap,
                    onAddAccount: onAddAccount,
                    onAddCreditCard: onAddCreditCard,
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Destination toggle ───────────────────────────────────────────────────────

class _DestinationToggle extends StatelessWidget {
  final String destinationType;
  final void Function(String) onTypeChanged;

  const _DestinationToggle({
    required this.destinationType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isAccount = destinationType == 'account';
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onTypeChanged('account'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isAccount ? AppColors.primary : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Cuenta bancaria",
                  style: AppTextStyles.body2(
                    context,
                    color: isAccount ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onTypeChanged('card'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !isAccount ? AppColors.primary : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Tarjeta de crédito",
                  style: AppTextStyles.body2(
                    context,
                    color: !isAccount ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Entity list ──────────────────────────────────────────────────────────────

class _EntityListView extends StatelessWidget {
  final List<BankEntity> entities;
  final bool isAccount;
  final List<BankAccount> Function(BankEntity) accountsFor;
  final List<CreditCard> Function(BankEntity) cardsFor;
  final void Function(BankEntity) onEntityTap;
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;

  const _EntityListView({
    required this.entities,
    required this.isAccount,
    required this.accountsFor,
    required this.cardsFor,
    required this.onEntityTap,
    required this.onAddAccount,
    required this.onAddCreditCard,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("¿A dónde?", style: AppTextStyles.h400(context)),
          const SizedBox(height: 20),
          if (entities.isEmpty)
            _EmptyHint(
              isAccount: isAccount,
              onAddAccount: onAddAccount,
              onAddCreditCard: onAddCreditCard,
            )
          else ...[
            ...entities.map((e) => _EntityTile(
                  entity: e,
                  countLabel: isAccount
                      ? _accountCountLabel(accountsFor(e).length)
                      : _cardCountLabel(cardsFor(e).length),
                  onTap: () => onEntityTap(e),
                )),
            const SizedBox(height: 8),
            if (isAccount)
              _AddAccountButton(onAddAccount: onAddAccount)
            else
              _AddCreditCardButton(onAddCreditCard: onAddCreditCard),
          ],
        ],
      ),
    );
  }

  String _accountCountLabel(int count) =>
      "$count cuenta${count != 1 ? 's' : ''}";

  String _cardCountLabel(int count) =>
      "$count tarjeta${count != 1 ? 's' : ''}";
}

class _EmptyHint extends StatelessWidget {
  final bool isAccount;
  final VoidCallback onAddAccount;
  final VoidCallback onAddCreditCard;

  const _EmptyHint({
    required this.isAccount,
    required this.onAddAccount,
    required this.onAddCreditCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAccount
              ? "Aún no tienes cuentas bancarias registradas."
              : "Aún no tienes tarjetas de crédito registradas.",
          style: AppTextStyles.body2(context, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        if (isAccount)
          _AddAccountButton(onAddAccount: onAddAccount)
        else
          _AddCreditCardButton(onAddCreditCard: onAddCreditCard),
      ],
    );
  }
}

class _EntityTile extends StatelessWidget {
  final BankEntity entity;
  final String countLabel;
  final VoidCallback onTap;

  const _EntityTile({
    required this.entity,
    required this.countLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(entity.colorHex);

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
                  Text(countLabel, style: AppTextStyles.body2(context, color: color)),
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

// ── Accounts view ────────────────────────────────────────────────────────────

class _AccountsView extends StatelessWidget {
  final BankEntity entity;
  final List<BankAccount> accounts;
  final BankAccount? selectedAccount;
  final void Function(BankAccount) onAccountTap;
  final VoidCallback onBack;
  final VoidCallback onAddAccount;

  const _AccountsView({
    required this.entity,
    required this.accounts,
    required this.selectedAccount,
    required this.onAccountTap,
    required this.onBack,
    required this.onAddAccount,
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
            "Selecciona una cuenta",
            style: AppTextStyles.body2(context, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Text(
            "Cuentas bancarias",
            style: AppTextStyles.body2(context, color: entityColor),
          ),
          const SizedBox(height: 10),
          if (accounts.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "No hay cuentas para esta entidad.",
                  style: AppTextStyles.body2(context, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _AddAccountButton(onAddAccount: onAddAccount),
              ],
            )
          else ...[
            ...accounts.map((a) => _AccountCard(
                  account: a,
                  isSelected: selectedAccount?.id == a.id,
                  onTap: () => onAccountTap(a),
                )),
            const SizedBox(height: 8),
            _AddAccountButton(onAddAccount: onAddAccount),
          ],
        ],
      ),
    );
  }
}

// ── Cards view ───────────────────────────────────────────────────────────────

class _CardsView extends StatelessWidget {
  final BankEntity entity;
  final List<CreditCard> cards;
  final CreditCard? selectedCreditCard;
  final void Function(CreditCard) onCardTap;
  final VoidCallback onBack;
  final VoidCallback onAddCreditCard;

  const _CardsView({
    required this.entity,
    required this.cards,
    required this.selectedCreditCard,
    required this.onCardTap,
    required this.onBack,
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
            "Selecciona una tarjeta",
            style: AppTextStyles.body2(context, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Text(
            "Tarjetas de crédito",
            style: AppTextStyles.body2(context, color: entityColor),
          ),
          const SizedBox(height: 10),
          if (cards.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "No hay tarjetas para esta entidad.",
                  style: AppTextStyles.body2(context, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _AddCreditCardButton(onAddCreditCard: onAddCreditCard),
              ],
            )
          else ...[
            ...cards.map((c) => _CardCard(
                  card: c,
                  isSelected: selectedCreditCard?.id == c.id,
                  onTap: () => onCardTap(c),
                )),
            const SizedBox(height: 8),
            _AddCreditCardButton(onAddCreditCard: onAddCreditCard),
          ],
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

class _CardCard extends StatelessWidget {
  final CreditCard card;
  final bool isSelected;
  final VoidCallback onTap;

  const _CardCard({required this.card, required this.isSelected, required this.onTap});

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

// ── Shared: entity badge & add buttons ───────────────────────────────────────

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

class _AddAccountButton extends StatelessWidget {
  final VoidCallback onAddAccount;

  const _AddAccountButton({required this.onAddAccount});

  @override
  Widget build(BuildContext context) {
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
}

class _AddCreditCardButton extends StatelessWidget {
  final VoidCallback onAddCreditCard;

  const _AddCreditCardButton({required this.onAddCreditCard});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onAddCreditCard,
      icon: const Icon(Icons.add, size: 16),
      label: const Text("Agregar tarjeta"),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
