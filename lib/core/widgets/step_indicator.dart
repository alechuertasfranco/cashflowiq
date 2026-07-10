// lib/core/widgets/step_indicator.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color? activeColor;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedActiveColor = activeColor ?? context.colorError;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return AnimatedContainer(
            duration: context.motionBase,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: (isActive || isDone) ? resolvedActiveColor : context.colorBorder,
              borderRadius: context.radiusPillRadius,
            ),
          );
        }),
      ),
    );
  }
}
