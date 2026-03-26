import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() {
  runApp(const CashFlowIQApp());
}

class CashFlowIQApp extends StatelessWidget {
  const CashFlowIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'CashFlowIQ', debugShowCheckedModeBanner: false, theme: AppTheme.light, home: const DashboardScreen());
  }
}
