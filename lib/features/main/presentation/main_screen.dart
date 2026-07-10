// lib/features/main/presentation/main_screen.dart

import 'dart:io';
import 'package:cashflowiq/core/services/update_service.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/widgets/update_dialog.dart';
import 'package:cashflowiq/features/main/presentation/widgets/custom_bottom_bar.dart';
import 'package:cashflowiq/features/dashboard/presentation/dashboard_screen.dart';
import 'package:cashflowiq/features/profile/presentation/profile_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/transaction_type_screen.dart';
import 'package:cashflowiq/features/reports/presentation/reports_screen.dart';
import 'package:cashflowiq/features/transactions/presentation/transactions_screen.dart';
import 'package:cashflowiq/features/voucher/presentation/voucher_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const _sharingChannel = MethodChannel('cashflowiq/sharing');

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
    WidgetsBinding.instance.addObserver(this);

    // Check if app was launched or foregrounded via a share intent
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSharedImage());

    // One-shot check for a newer self-hosted APK build. Best-effort - failures are swallowed inside the service.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (info != null && mounted) {
      showUpdateDialog(context, info);
    }
  }

  Future<void> _checkSharedImage() async {
    try {
      final path = await _sharingChannel.invokeMethod<String>('getSharedImage');
      if (path != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoucherScanScreen(initialImage: File(path)),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      DataCache.instance.clear();
      _checkSharedImage();
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);

    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onTabTapped(0);
      },
      child: Scaffold(
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
      ),
    );
  }
}
