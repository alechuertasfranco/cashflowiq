// lib/features/main/presentation/main_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/features/main/presentation/widgets/custom_bottom_bar.dart';
import 'package:cashflowiq/features/dashboard/presentation/dashboard_screen.dart';
import 'package:cashflowiq/features/profile/presentation/profile_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/transaction_type_screen.dart';
import 'package:cashflowiq/features/reports/presentation/reports_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    TransactionTypeScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);

    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: _screens,
        ),
      ),

      bottomNavigationBar: CustomBottomBar(currentIndex: _currentIndex, onTap: _onTabTapped),
    );
  }
}
