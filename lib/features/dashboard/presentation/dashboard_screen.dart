import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [_Header(), SizedBox(height: 20), _BalanceCard(), SizedBox(height: 20), _InsightsCard()]),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("CashFlowIQ", style: AppTextStyles.caption(context)),
        const SizedBox(height: 4),
        Text("Tu dinero, en control", style: AppTextStyles.h300(context)),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Balance actual", style: AppTextStyles.caption(context)),
            const SizedBox(height: 8),
            Text("S/ 4,250.00", style: AppTextStyles.h100(context)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("+ Ingresos: S/ 6,000", style: AppTextStyles.body2(context)),
                Text("- Gastos: S/ 1,750", style: AppTextStyles.body2(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(child: Text("Estás gastando 32% más en comida este mes", style: AppTextStyles.subtitle2(context))),
          ],
        ),
      ),
    );
  }
}
