// lib/features/dashboard/presentation/dashboard_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/features/dashboard/data/dashboard_service.dart';
import 'package:cashflowiq/features/dashboard/data/dashboard_summary.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/accounts_list.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/balance_card.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:cashflowiq/features/dashboard/presentation/widgets/insight_card.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _service = DashboardService();

  DashboardSummary? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _service.getSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar el resumen';
      });
      debugPrint('Error cargando dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            DataCache.instance.invalidate('dashboard_summary');
            await _loadSummary();
          },
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        children: [
          SizedBox(
            height: 300,
            child: Center(
              child: Text(
                _errorMessage!,
                style: AppTextStyles.body1(context, color: AppColors.error),
              ),
            ),
          ),
        ],
      );
    }

    final summary = _summary!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const DashboardHeader(),
        const SizedBox(height: 20),
        DashboardBalanceCard(
          accounts: summary.accounts,
          netBalance: summary.netBalance,
          totalIncome: summary.totalIncome,
          totalExpense: summary.totalExpense,
          allTimeIncome: summary.allTimeIncome,
          allTimeExpense: summary.allTimeExpense,
        ),
        const SizedBox(height: 20),
        DashboardInsightCard(
          mostActiveAccount: summary.mostActiveAccountId != null
              ? summary.accounts
                  .where((a) => a.id == summary.mostActiveAccountId)
                  .firstOrNull
              : null,
          mostActiveAccountName: summary.mostActiveAccountName,
          mostActiveAccountTxCount: summary.mostActiveAccountTxCount,
        ),
        const SizedBox(height: 20),
        DashboardAccountsList(accounts: summary.accounts),
      ],
    );
  }
}
