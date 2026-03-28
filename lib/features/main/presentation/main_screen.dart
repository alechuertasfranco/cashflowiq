import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/features/dashboard/presentation/dashboard_screen.dart';
import 'package:cashflowiq/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [DashboardScreen(), _TransactionsScreen(), _AddScreen(), _ReportsScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Movimientos'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Agregar'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _TransactionsScreen extends StatelessWidget {
  const _TransactionsScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Movimientos"));
  }
}

class _AddScreen extends StatelessWidget {
  const _AddScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Agregar transacción"));
  }
}

class _ReportsScreen extends StatelessWidget {
  const _ReportsScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Reportes"));
  }
}
