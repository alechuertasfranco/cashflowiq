import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/core/widgets/sub_step_switcher.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/payment_source_item.dart';
import 'package:flutter/material.dart';

/// Unified entity → account/card selection step.
///
/// Modes driven by parameters:
///   • Accounts-only  — [cardsFor] = null  (income, split, transfer-from)
///   • Cards + accounts without toggle — [cardsFor] ≠ null, [sourceType] = null  (expense)
///   • Cards + accounts with toggle    — [cardsFor] ≠ null, [sourceType] ≠ null  (transfer-to, recurring)
class FormStepPaymentSource extends StatelessWidget {
  // ── Core ──────────────────────────────────────────────────────────────────
  final List<BankEntity> entities;
  final BankEntity? selectedEntity;
  final BankAccount? selectedAccount;
  final String viewKey;
  final bool goingForward;
  final List<BankAccount> Function(BankEntity) accountsFor;
  final void Function(BankEntity) onEntityTap;
  final void Function(BankAccount) onAccountTap;
  final VoidCallback onBack;
  final VoidCallback onAddAccount;

  // ── Customization ─────────────────────────────────────────────────────────
  final String title;
  final Color? accentColor;

  // ── Cards (null = accounts-only) ──────────────────────────────────────────
  final CreditCard? selectedCreditCard;
  final List<CreditCard> Function(BankEntity)? cardsFor;
  final void Function(CreditCard)? onCardTap;
  final VoidCallback? onAddCreditCard;

  // ── Source toggle (null = no toggle) ─────────────────────────────────────
  final String? sourceType;
  final void Function(String)? onSourceTypeChanged;

  // ── Extras ────────────────────────────────────────────────────────────────
  final List<PaymentSourceItem> mostUsedItems;
  final Widget? bottomSlot;

  const FormStepPaymentSource({
    super.key,
    required this.entities,
    required this.selectedEntity,
    required this.selectedAccount,
    required this.viewKey,
    required this.goingForward,
    required this.accountsFor,
    required this.onEntityTap,
    required this.onAccountTap,
    required this.onBack,
    required this.onAddAccount,
    this.title = '¿A qué cuenta?',
    this.accentColor,
    this.selectedCreditCard,
    this.cardsFor,
    this.onCardTap,
    this.onAddCreditCard,
    this.sourceType,
    this.onSourceTypeChanged,
    this.mostUsedItems = const [],
    this.bottomSlot,
  });

  bool get _hasCards => cardsFor != null;
  bool get _hasToggle => sourceType != null;
  bool get _isCardMode => sourceType == 'card';

  @override
  Widget build(BuildContext context) {
    final resolvedAccentColor = accentColor ?? context.colorPrimary;

    final subStep = SubStepSwitcher(
      viewKey: viewKey,
      goingForward: goingForward,
      child: selectedEntity != null
          ? _buildAccountsView(context, resolvedAccentColor)
          : _buildEntityList(context, resolvedAccentColor),
    );

    if (_hasToggle || bottomSlot != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasToggle)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: _SourceToggle(
                sourceType: sourceType!,
                onChanged: onSourceTypeChanged!,
              ),
            ),
          if (_hasToggle) const SizedBox(height: 12),
          Expanded(child: subStep),
          ?bottomSlot,
        ],
      );
    }
    return subStep;
  }

  Widget _buildEntityList(BuildContext context, Color accentColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.heading4()),
          if (mostUsedItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _QuickAccessRow(
              items: mostUsedItems,
              selectedAccount: selectedAccount,
              selectedCreditCard: selectedCreditCard,
              accentColor: accentColor,
            ),
          ],
          const SizedBox(height: 20),
          if (entities.isEmpty)
            _EmptyHint(
              hasCards: _hasCards,
              accentColor: accentColor,
              onAddAccount: onAddAccount,
              onAddCreditCard: onAddCreditCard,
            )
          else ...[
            ...entities.map((e) => _EntityTile(
                  entity: e,
                  accounts: accountsFor(e),
                  cards: _hasCards && !_hasToggle ? cardsFor!(e) : const [],
                  showCardCount: _hasCards && _isCardMode,
                  onTap: () => onEntityTap(e),
                )),
            const SizedBox(height: 8),
            _AddRow(
              showCards: _hasCards,
              isCardMode: _isCardMode,
              accentColor: accentColor,
              onAddAccount: onAddAccount,
              onAddCreditCard: onAddCreditCard,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountsView(BuildContext context, Color accentColor) {
    final entity = selectedEntity!;
    final accounts = accountsFor(entity);
    final cards = _hasCards ? cardsFor!(entity) : <CreditCard>[];
    final entityColor = parseHexColor(entity.colorHex);

    final showBothSections = _hasCards && !_hasToggle;
    final showCardSection = _hasCards && _isCardMode;
    final subtitle = showBothSections || showCardSection
        ? (showBothSections ? 'Selecciona una cuenta o tarjeta' : 'Selecciona una tarjeta')
        : 'Selecciona una cuenta';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 13),
            label: const Text('Entidades'),
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
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
              Expanded(child: Text(entity.name, style: context.heading4())),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: context.textBody2(color: context.colorTextSecondary)),

          // Accounts section
          if (accounts.isNotEmpty && !showCardSection) ...[
            const SizedBox(height: 20),
            Text('Cuentas bancarias', style: context.textBody2(color: entityColor)),
            const SizedBox(height: 10),
            ...accounts.map((a) => _AccountCard(
                  account: a,
                  isSelected: selectedAccount?.id == a.id,
                  accentColor: accentColor,
                  onTap: () => onAccountTap(a),
                )),
          ],

          // Cards section
          if (cards.isNotEmpty && (showBothSections || showCardSection)) ...[
            const SizedBox(height: 20),
            Text('Tarjetas de crédito', style: context.textBody2(color: entityColor)),
            const SizedBox(height: 10),
            ...cards.map((c) => _CreditCardCard(
                  card: c,
                  isSelected: selectedCreditCard?.id == c.id,
                  accentColor: accentColor,
                  onTap: () => onCardTap!(c),
                )),
          ],

          const SizedBox(height: 8),
          _AddRow(
            showCards: _hasCards,
            isCardMode: _isCardMode,
            accentColor: accentColor,
            onAddAccount: onAddAccount,
            onAddCreditCard: onAddCreditCard,
          ),
        ],
      ),
    );
  }
}

// ── Source toggle ─────────────────────────────────────────────────────────────

class _SourceToggle extends StatelessWidget {
  final String sourceType;
  final void Function(String) onChanged;

  const _SourceToggle({required this.sourceType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget option(String label, String value, bool left) {
      final selected = sourceType == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: context.motionFast,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? context.colorPrimary : context.colorSurface,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(left ? context.radiusMd : 0),
                right: Radius.circular(left ? 0 : context.radiusMd),
              ),
              border: Border.all(color: context.colorBorder),
            ),
            child: Center(
              child: Text(
                label,
                style: context.textBody2(
                  color: selected ? context.colorOnPrimary : context.colorTextSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option('Cuenta bancaria', 'account', true),
        option('Tarjeta de crédito', 'card', false),
      ],
    );
  }
}

// ── Entity list helpers ───────────────────────────────────────────────────────

class _QuickAccessRow extends StatelessWidget {
  final List<PaymentSourceItem> items;
  final BankAccount? selectedAccount;
  final CreditCard? selectedCreditCard;
  final Color accentColor;

  const _QuickAccessRow({
    required this.items,
    required this.selectedAccount,
    required this.selectedCreditCard,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Más usado', style: context.textCaption(color: context.colorTextSecondary)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items
                .map((item) {
                  final isSelected = item.isAccount
                      ? selectedAccount?.id == item.id
                      : selectedCreditCard?.id == item.id;
                  return _QuickAccessCard(
                    icon: item.icon,
                    name: item.name,
                    isSelected: isSelected,
                    accentColor: accentColor,
                    onTap: item.onTap,
                  );
                })
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
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.name,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withAlpha(20) : context.colorSurface,
          borderRadius: context.radiusMdRadius,
          border: Border.all(
            color: isSelected ? accentColor : context.colorBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? accentColor : context.colorMuted),
            const SizedBox(width: 6),
            Text(name, style: context.textCaption(color: context.colorTextPrimary)),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check, size: 14, color: accentColor),
            ],
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
  final bool showCardCount;
  final VoidCallback onTap;

  const _EntityTile({
    required this.entity,
    required this.accounts,
    required this.cards,
    required this.showCardCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(entity.colorHex);
    final parts = <String>[
      if (!showCardCount && accounts.isNotEmpty)
        '${accounts.length} cuenta${accounts.length != 1 ? 's' : ''}',
      if (showCardCount && cards.isNotEmpty)
        '${cards.length} tarjeta${cards.length != 1 ? 's' : ''}',
      if (!showCardCount && cards.isNotEmpty)
        '${cards.length} tarjeta${cards.length != 1 ? 's' : ''}',
      if (showCardCount && accounts.isNotEmpty)
        '${accounts.length} cuenta${accounts.length != 1 ? 's' : ''}',
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: context.radiusLgRadius,
          border: Border.all(color: context.colorBorder),
        ),
        child: Row(
          children: [
            _EntityBadge(entity: entity, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entity.name, style: context.textSubtitle2()),
                  if (parts.isNotEmpty)
                    Text(parts.join(' · '), style: context.textBody2(color: color)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.colorMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final bool hasCards;
  final Color accentColor;
  final VoidCallback onAddAccount;
  final VoidCallback? onAddCreditCard;

  const _EmptyHint({
    required this.hasCards,
    required this.accentColor,
    required this.onAddAccount,
    required this.onAddCreditCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasCards
              ? 'Aún no tienes cuentas ni tarjetas registradas.'
              : 'Aún no tienes cuentas bancarias registradas.',
          style: context.textBody2(color: context.colorTextSecondary),
        ),
        const SizedBox(height: 16),
        _AddRow(
          showCards: hasCards,
          isCardMode: false,
          accentColor: accentColor,
          onAddAccount: onAddAccount,
          onAddCreditCard: onAddCreditCard,
        ),
      ],
    );
  }
}

// ── Accounts/cards view helpers ───────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final BankAccount account;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _AccountCard({
    required this.account,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motionFast,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withAlpha(20) : context.colorSurface,
          borderRadius: context.radiusLgRadius,
          border: Border.all(
            color: isSelected ? accentColor : context.colorBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance, size: 20,
                color: isSelected ? accentColor : context.colorMuted),
            const SizedBox(width: 12),
            Expanded(child: Text(account.name, style: context.textSubtitle2())),
            if (isSelected) Icon(Icons.check_circle, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CreditCardCard extends StatelessWidget {
  final CreditCard card;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _CreditCardCard({
    required this.card,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motionFast,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withAlpha(20) : context.colorSurface,
          borderRadius: context.radiusLgRadius,
          border: Border.all(
            color: isSelected ? accentColor : context.colorBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.credit_card, size: 20,
                color: isSelected ? accentColor : context.colorMuted),
            const SizedBox(width: 12),
            Expanded(child: Text(card.name, style: context.textSubtitle2())),
            if (isSelected) Icon(Icons.check_circle, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Shared entity badge & add row ─────────────────────────────────────────────

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
        child: Text(label, style: context.textCaption(color: getContrastColor(color))),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  final bool showCards;
  final bool isCardMode;
  final Color accentColor;
  final VoidCallback onAddAccount;
  final VoidCallback? onAddCreditCard;

  const _AddRow({
    required this.showCards,
    required this.isCardMode,
    required this.accentColor,
    required this.onAddAccount,
    required this.onAddCreditCard,
  });

  @override
  Widget build(BuildContext context) {
    // Accounts-only → single "Agregar cuenta" button
    if (!showCards || (showCards && isCardMode && onAddCreditCard == null)) {
      return OutlinedButton.icon(
        onPressed: onAddAccount,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Agregar cuenta'),
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
          shape: RoundedRectangleBorder(borderRadius: context.radiusMdRadius),
        ),
      );
    }

    // Cards-only mode (toggle active, card selected)
    if (isCardMode) {
      return OutlinedButton.icon(
        onPressed: onAddCreditCard,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Agregar tarjeta'),
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
          shape: RoundedRectangleBorder(borderRadius: context.radiusMdRadius),
        ),
      );
    }

    // Accounts + cards without toggle (expense) → two buttons
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAddAccount,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Cuenta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accentColor,
              side: BorderSide(color: accentColor),
              shape: RoundedRectangleBorder(borderRadius: context.radiusMdRadius),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAddCreditCard,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tarjeta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accentColor,
              side: BorderSide(color: accentColor),
              shape: RoundedRectangleBorder(borderRadius: context.radiusMdRadius),
            ),
          ),
        ),
      ],
    );
  }
}
