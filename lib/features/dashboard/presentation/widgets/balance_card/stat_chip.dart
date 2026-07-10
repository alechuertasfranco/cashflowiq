import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/amount_text.dart';
import 'package:flutter/material.dart';

class StatChip extends StatelessWidget {
  final String label;
  final String symbol;
  final double amount;
  final String sign;
  final Color color;

  const StatChip({
    super.key,
    required this.label,
    required this.symbol,
    required this.amount,
    required this.sign,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: context.radiusSmRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textCaption(color: color)),
          const SizedBox(height: 4),
          AmountText(
            symbol: symbol,
            amount: amount,
            sign: sign,
            style: context.textBody2(),
            color: color,
          ),
        ],
      ),
    );
  }
}
