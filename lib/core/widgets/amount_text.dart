// lib/core/widgets/amount_text.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/shared/models/money.dart';
import 'package:flutter/material.dart';

/// Displays a monetary amount with its currency symbol always visible.
///
/// The symbol is rendered at ~80% of the amount's font size in a muted
/// colour so the number stays visually dominant while the currency is never
/// ambiguous.
///
/// ```dart
/// AmountText(symbol: 'S/', amount: 250.0, style: AppTextStyles.h500(context))
/// AmountText.fromMoney(account.balance, style: AppTextStyles.h600(context))
/// AmountText.fromMoney(money, sign: '+', color: AppColors.success, style: ...)
/// ```
class AmountText extends StatelessWidget {
  final double amount;
  final String symbol;
  final int decimals;
  final TextStyle? style;
  final Color? color;

  /// Optional prefix shown before the symbol: '+', '-', or null.
  final String? sign;

  const AmountText({
    super.key,
    required this.amount,
    required this.symbol,
    this.decimals = 2,
    this.style,
    this.color,
    this.sign,
  });

  factory AmountText.fromMoney(
    Money money, {
    Key? key,
    TextStyle? style,
    Color? color,
    String? sign,
  }) {
    return AmountText(
      key: key,
      amount: money.amount,
      symbol: money.currency.symbol,
      decimals: money.currency.decimals,
      style: style,
      color: color,
      sign: sign,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimary;
    final base = (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: effectiveColor,
    );
    final symbolStyle = base.copyWith(
      fontSize: (base.fontSize ?? 14) * 0.80,
      color: effectiveColor.withValues(alpha: 0.65),
      fontWeight: FontWeight.w400,
    );

    final formatted = amount.abs().toStringAsFixed(decimals);

    return Text.rich(
      TextSpan(
        children: [
          if (sign != null) TextSpan(text: '$sign ', style: base),
          TextSpan(text: '$symbol ', style: symbolStyle),
          TextSpan(text: formatted, style: base),
        ],
      ),
    );
  }
}

/// A small currency code pill — use it beside amounts when a badge is clearer
/// than an inline symbol, e.g. in summary cards.
///
/// ```dart
/// Row(children: [CurrencyBadge(code: 'PEN'), const SizedBox(width: 6), ...])
/// ```
class CurrencyBadge extends StatelessWidget {
  final String code;
  final Color? backgroundColor;
  final Color? textColor;

  const CurrencyBadge({
    super.key,
    required this.code,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.secondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
