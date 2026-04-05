// lib/features/investment_fund/widgets/card.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/shared/models/investment_fund.dart';

class InvestmentFundCard extends StatelessWidget {
  final InvestmentFund fund;
  final VoidCallback? onTap;

  const InvestmentFundCard({super.key, required this.fund, this.onTap});

  @override
  Widget build(BuildContext context) {
    final money = fund.investedMoney;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(fund.name, style: AppTextStyles.subtitle1(context), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                _TypeBadge(type: fund.fundType),
              ],
            ),

            const SizedBox(height: 12),

            /// 💰 CAPITAL INVERTIDO (DECISIÓN)
            Text(money.format(), style: AppTextStyles.balance(context)),

            const SizedBox(height: 12),

            /// 🧠 CONTEXTO
            Row(
              children: [
                Expanded(
                  child: _InfoItem(label: "Entidad", value: fund.bankEntity.name),
                ),
                Expanded(
                  child: _InfoItem(label: "Tipo", value: _typeToLabel(fund.fundType)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _typeToLabel(InvestmentFundType type) {
    switch (type) {
      case InvestmentFundType.mutualFund:
        return "Fondos mutuos";
      case InvestmentFundType.afp:
        return "Fondo de pensiones";
      case InvestmentFundType.insurance:
        return "Seguro con devolución";
      case InvestmentFundType.etf:
        return "ETF";
      case InvestmentFundType.other:
        return "Otro";
    }
  }
}

/// 🔹 CONTEXTO
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption(context)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.body2(context)),
      ],
    );
  }
}

/// 🔹 BADGE DE TIPO (contexto, no decisión)
class _TypeBadge extends StatelessWidget {
  final InvestmentFundType type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
      child: Text(type.name, style: AppTextStyles.caption(context)),
    );
  }
}
