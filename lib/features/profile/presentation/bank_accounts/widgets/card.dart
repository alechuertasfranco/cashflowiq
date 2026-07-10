import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/core/widgets/app_card.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';

class BankAccountCard extends StatelessWidget {
  final BankAccount account;
  final VoidCallback onTap;

  const BankAccountCard({super.key, required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          /// 🎨 Banco
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: parseHexColor(account.bankEntity.colorHex),
              borderRadius: context.radiusSmRadius,
            ),
            child: const Icon(Icons.account_balance, color: Colors.white, size: 16),
          ),

          const SizedBox(width: 16),

          /// 📄 Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name, style: context.textSubtitle2()),
                Text(
                  "${account.bankEntity.code} · ${account.bankEntity.name}",
                  style: context.textCaption(),
                ),
              ],
            ),
          ),

          /// 💰 Balance
          Text(account.balance.format(), style: context.heading3()),
        ],
      ),
    );
  }
}
