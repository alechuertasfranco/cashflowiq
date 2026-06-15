// lib/features/dashboard/presentation/widgets/accounts_list.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/features/dashboard/data/dashboard_summary.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/balance_card/currency_utils.dart';
import 'package:cashflowiq/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';

class DashboardAccountsList extends StatefulWidget {
  final List<AccountBalance> accounts;

  const DashboardAccountsList({super.key, required this.accounts});

  @override
  State<DashboardAccountsList> createState() => _DashboardAccountsListState();
}

class _DashboardAccountsListState extends State<DashboardAccountsList> {
  String? _entityFilter;
  bool _showAll = false;

  static const _previewCount = 5;

  void _setEntityFilter(String? code) {
    setState(() {
      _entityFilter = code;
      _showAll = false;
    });
  }

  List<String> get _uniqueEntityCodes {
    final seen = <String>{};
    return [
      for (final a in widget.accounts)
        if (seen.add(a.bankEntityCode)) a.bankEntityCode,
    ];
  }

  List<AccountBalance> get _filtered => _entityFilter == null
      ? widget.accounts
      : widget.accounts.where((a) => a.bankEntityCode == _entityFilter).toList();

  @override
  Widget build(BuildContext context) {
    final entities = _uniqueEntityCodes;
    final filtered = _filtered;
    final withBalance = filtered.where((a) => a.balance != 0).toList();
    final hasHidden = filtered.any((a) => a.balance == 0);
    final hasMore = !_showAll && (withBalance.length > _previewCount || hasHidden);
    final visible = _showAll ? filtered : withBalance.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mis cuentas', style: AppTextStyles.h500(context)),
        const SizedBox(height: 12),
        if (widget.accounts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Sin cuentas',
                  style: AppTextStyles.body1(context, color: AppColors.muted),
                ),
              ),
            ),
          )
        else ...[
          if (entities.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _EntityChip(
                    label: 'Todas',
                    selected: _entityFilter == null,
                    onTap: () => _setEntityFilter(null),
                  ),
                  ...entities.map(
                    (code) => _EntityChip(
                      label: code,
                      selected: _entityFilter == code,
                      onTap: () => _setEntityFilter(_entityFilter == code ? null : code),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...visible.map(
            (account) => _AccountRow(
              account: account,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionsScreen(initialAccountId: account.id.toString()),
                ),
              ),
            ),
          ),
          if (hasMore)
            GestureDetector(
              onTap: () => setState(() => _showAll = true),
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ver todas las cuentas (${filtered.length})',
                      style: AppTextStyles.body2(context, color: AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _EntityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EntityChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption(
              context,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final AccountBalance account;
  final VoidCallback onTap;

  const _AccountRow({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: AppTextStyles.subtitle1(context)),
                    Text(account.bankEntityCode, style: AppTextStyles.caption(context)),
                  ],
                ),
              ),
              AmountText(
                symbol: dashboardCurrencySymbol(account.currencyCode),
                amount: account.balance,
                style: AppTextStyles.h600(context),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
