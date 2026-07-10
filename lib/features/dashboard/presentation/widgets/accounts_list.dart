// lib/features/dashboard/presentation/widgets/accounts_list.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:cashflowiq/features/dashboard/data/dashboard_summary.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/balance_card/currency_utils.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/credit_cards_list.dart';
import 'package:cashflowiq/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';

enum _AccountsTab { accounts, creditCards }

class DashboardAccountsList extends StatefulWidget {
  final List<AccountBalance> accounts;
  final List<CreditCardBalance> creditCards;

  const DashboardAccountsList({
    super.key,
    required this.accounts,
    this.creditCards = const [],
  });

  @override
  State<DashboardAccountsList> createState() => _DashboardAccountsListState();
}

class _DashboardAccountsListState extends State<DashboardAccountsList> {
  _AccountsTab _tab = _AccountsTab.accounts;
  String? _entityFilter;
  bool _showAll = false;

  static const _previewCount = 5;

  void _setEntityFilter(String? code) {
    setState(() {
      _entityFilter = code;
      _showAll = false;
    });
  }

  List<String> get _entityCodesForActiveTab {
    final source = _tab == _AccountsTab.accounts
        ? widget.accounts.map((a) => a.bankEntityCode)
        : widget.creditCards.map((c) => c.bankEntityCode);
    final seen = <String>{};
    return [for (final code in source) if (seen.add(code)) code];
  }

  List<AccountBalance> get _filteredAccounts => _entityFilter == null
      ? widget.accounts
      : widget.accounts.where((a) => a.bankEntityCode == _entityFilter).toList();

  List<CreditCardBalance> get _filteredCards => _entityFilter == null
      ? widget.creditCards
      : widget.creditCards.where((c) => c.bankEntityCode == _entityFilter).toList();

  @override
  Widget build(BuildContext context) {
    final entityCodes = _entityCodesForActiveTab;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tab == _AccountsTab.accounts ? 'Mis cuentas' : 'Deuda de tarjetas',
          style: context.heading5(),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _EntityChip(
                label: 'Cuentas',
                selected: _tab == _AccountsTab.accounts,
                onTap: () => setState(() {
                  _tab = _AccountsTab.accounts;
                  _entityFilter = null;
                  _showAll = false;
                }),
              ),
              _EntityChip(
                label: 'Tarjetas',
                selected: _tab == _AccountsTab.creditCards,
                onTap: () => setState(() {
                  _tab = _AccountsTab.creditCards;
                  _entityFilter = null;
                  _showAll = false;
                }),
              ),
              if (entityCodes.length > 1) ...[
                const SizedBox(width: 4),
                ...entityCodes.map(
                  (code) => _EntityChip(
                    label: code,
                    selected: _entityFilter == code,
                    onTap: () => _setEntityFilter(_entityFilter == code ? null : code),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_tab == _AccountsTab.accounts) _buildAccounts(),
        if (_tab == _AccountsTab.creditCards)
          DashboardCreditCardsList(cards: _filteredCards),
      ],
    );
  }

  Widget _buildAccounts() {
    final filtered = _filteredAccounts;
    final withBalance = filtered.where((a) => a.balance != 0).toList();
    final hasHidden = filtered.any((a) => a.balance == 0);
    final hasMore = !_showAll && (withBalance.length > _previewCount || hasHidden);
    final visible = _showAll ? filtered : withBalance.take(_previewCount).toList();

    if (widget.accounts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Sin cuentas',
              style: context.textBody1(color: context.colorMuted),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
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
                color: context.colorSurface,
                borderRadius: context.radiusMdRadius,
                border: Border.all(color: context.colorBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver todas las cuentas (${filtered.length})',
                    style: context.textBody2(color: context.colorPrimary),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 16, color: context.colorPrimary),
                ],
              ),
            ),
          ),
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
          duration: context.motionFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? context.colorPrimary : context.colorSurface,
            borderRadius: context.radiusPillRadius,
            border: Border.all(color: selected ? context.colorPrimary : context.colorBorder),
          ),
          child: Text(
            label,
            style: context.textCaption(
              color: selected ? context.colorOnPrimary : context.colorTextSecondary,
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
        borderRadius: context.radiusLgRadius,
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
                    Text(account.name, style: context.textSubtitle1()),
                    Text(account.bankEntityCode, style: context.textCaption()),
                  ],
                ),
              ),
              AmountText(
                symbol: dashboardCurrencySymbol(account.currencyCode),
                amount: account.balance,
                style: context.heading6(),
                color: context.colorPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
