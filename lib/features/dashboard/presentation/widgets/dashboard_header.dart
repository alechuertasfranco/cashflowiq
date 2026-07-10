// lib/features/dashboard/presentation/widgets/dashboard_header.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CashFlowIQ', style: context.textCaption()),
        const SizedBox(height: 4),
        Text('Tu dinero, en control', style: context.heading3()),
      ],
    );
  }
}
