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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_Header(), const SizedBox(height: 20), _BalanceCard(), const SizedBox(height: 20), _InsightsCard()],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text("CashFlowIQ", style: AppTextStyles.caption),
        SizedBox(height: 4),
        Text("Tu dinero, en control", style: AppTextStyles.heading),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Balance actual", style: AppTextStyles.caption),
            const SizedBox(height: 8),
            const Text("S/ 4,250.00", style: AppTextStyles.heading),
            const SizedBox(height: 12),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text("+ Ingresos: S/ 6,000"), Text("- Gastos: S/ 1,750")]),
          ],
        ),
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            Icon(Icons.trending_up, color: AppColors.success),
            SizedBox(width: 12),
            Expanded(child: Text("Estás gastando 32% más en comida este mes", style: AppTextStyles.body)),
          ],
        ),
      ),
    );
  }
}
