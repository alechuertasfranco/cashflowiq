import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/bank_accounts/presentation/bank_accounts_screen.dart';
import 'package:cashflowiq/features/bank_entities/presentation/bank_entities_screen.dart';
import 'package:cashflowiq/features/credit_cards/presentation/credit_cards_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Text("Perfil", style: AppTextStyles.h300(context)),
              const SizedBox(height: 4),
              Text("Gestiona tu cuenta", style: AppTextStyles.caption(context)),

              const SizedBox(height: 24),

              /// User Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user?.email != null ? user!.email![0].toUpperCase() : "U",
                          style: AppTextStyles.h400(context).copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text(user?.email ?? "Usuario", style: AppTextStyles.subtitle1(context))),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// Financial Assets
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
                child: Text("Activos financieros", style: AppTextStyles.subtitle1(context)),
              ),
              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.domain, color: AppColors.textSecondary),
                      title: Text("Entidades bancarias", style: AppTextStyles.body1(context)),
                      subtitle: Text("Organiza tus cuentas por banco", style: AppTextStyles.caption(context)),
                      onTap: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const BankEntitiesScreen())),
                    ),
                    const Divider(height: 1),

                    ListTile(
                      leading: const Icon(Icons.account_balance, color: AppColors.textSecondary),
                      title: Text("Cuentas bancarias", style: AppTextStyles.body1(context)),
                      subtitle: Text("Gestiona tu dinero disponible", style: AppTextStyles.caption(context)),
                      onTap: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const BankAccountsScreen())),
                    ),
                    const Divider(height: 1),

                    ListTile(
                      leading: const Icon(Icons.credit_card, color: AppColors.textSecondary),
                      title: Text("Tarjetas de crédito", style: AppTextStyles.body1(context)),
                      subtitle: Text("Controla tu deuda y límites", style: AppTextStyles.caption(context)),
                      onTap: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditCardsScreen())),
                    ),
                    const Divider(height: 1),

                    ListTile(
                      leading: const Icon(Icons.trending_up, color: AppColors.textSecondary),
                      title: Text("Fondos de inversión", style: AppTextStyles.body1(context)),
                      subtitle: Text("Haz crecer tu dinero", style: AppTextStyles.caption(context)),
                      onTap: () {
                        // TODO: Navegar a pantalla de inversiones
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// Actions
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
                child: Text("Cuenta", style: AppTextStyles.subtitle1(context)),
              ),
              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.textSecondary),
                      title: Text("Cerrar sesión", style: AppTextStyles.body1(context)),
                      onTap: () async {
                        await _logout();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
