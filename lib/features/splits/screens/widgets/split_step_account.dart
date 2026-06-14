// lib/features/splits/screens/widgets/split_step_account.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/core/widgets/sub_step_switcher.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:flutter/material.dart';

class SplitStepAccount extends StatelessWidget {
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

  const SplitStepAccount({
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
              selectedAccount: selectedAccount,
              onAccountTap: onAccountTap,
              onBack: onBack,
              onAddAccount: onAddAccount,
            )
          : _EntityListView(
              entities: entities,
              accountsFor: accountsFor,
              onEntityTap: onEntityTap,
              onAddAccount: onAddAccount,
            ),
    );
  }
}

// ── Entity list ──────────────────────────────────────────────────────────────

class _EntityListView extends StatelessWidget {
  final List<BankEntity> entities;
  final List<BankAccount> Function(BankEntity) accountsFor;
  final void Function(BankEntity) onEntityTap;
  final VoidCallback onAddAccount;

  const _EntityListView({
    required this.entities,
    required this.accountsFor,
    required this.onEntityTap,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("¿Con qué cuenta pagaste?", style: AppTextStyles.h400(context)),
          const SizedBox(height: 20),
          if (entities.isEmpty)
            _EmptyAccountHint(onAddAccount: onAddAccount)
          else ...[
            ...entities.map((e) => _EntityTile(
                  entity: e,
                  accounts: accountsFor(e),
                  onTap: () => onEntityTap(e),
                )),
            const SizedBox(height: 8),
            _AddAccountButton(onAddAccount: onAddAccount),
          ],
        ],
      ),
    );
  }
}

class _EmptyAccountHint extends StatelessWidget {
  final VoidCallback onAddAccount;

  const _EmptyAccountHint({required this.onAddAccount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Aún no tienes cuentas bancarias registradas.",
          style: AppTextStyles.body2(context, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        _AddAccountButton(onAddAccount: onAddAccount),
      ],
    );
  }
}

class _EntityTile extends StatelessWidget {
  final BankEntity entity;
  final List<BankAccount> accounts;
  final VoidCallback onTap;

  const _EntityTile({
    required this.entity,
    required this.accounts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(entity.colorHex);
    final countLabel = "${accounts.length} cuenta${accounts.length != 1 ? 's' : ''}";

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
            _EmptyAccountHint(onAddAccount: onAddAccount)
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

// ── Shared: entity badge & add button ────────────────────────────────────────

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
