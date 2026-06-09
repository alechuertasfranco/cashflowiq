import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';

class BankAccountCard extends StatelessWidget {
  final BankAccount account;
  final VoidCallback onTap;

  const BankAccountCard({super.key, required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            /// 🎨 Banco
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: parseHexColor(account.bankEntity.colorHex),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.account_balance, color: Colors.white, size: 16),
            ),

            const SizedBox(width: 16),

            /// 📄 Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, style: AppTextStyles.subtitle2(context)),
                  Text(
                    "${account.bankEntity.code} · ${account.bankEntity.name}",
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ),
            ),

            /// 💰 Balance
            Text(account.balance.format(), style: AppTextStyles.h300(context)),
          ],
        ),
      ),
    );
  }
}
