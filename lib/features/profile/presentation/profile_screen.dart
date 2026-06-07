import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/profile/presentation/bank_accounts/bank_accounts_screen.dart';
import 'package:cashflowiq/features/profile/presentation/bank_entities/bank_entities_screen.dart';
import 'package:cashflowiq/features/profile/presentation/categories/categories_screen.dart';
import 'package:cashflowiq/features/profile/presentation/credit_cards/credit_cards_screen.dart';
import 'package:cashflowiq/features/profile/presentation/investment_fund/investment_funds_screen.dart';
import 'package:cashflowiq/features/splits/screens/contacts_screen.dart';
import 'package:cashflowiq/shared/models/category.dart';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Text("Perfil", style: AppTextStyles.h300(context)),
              const SizedBox(height: 4),
              Text("Gestiona tu cuenta", style: AppTextStyles.caption(context)),

              const SizedBox(height: 24),

              /// User Card
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

              /// Categorías
              _SectionTitle("Categorías"),
              const SizedBox(height: 12),
              _MenuCard(
                items: [
                  _MenuItem(
                    icon: Icons.arrow_downward,
                    title: "Categorías de ingresos",
                    subtitle: "Organiza tus ingresos por categoría",
                    onTap: () => _go(context, const CategoriesScreen(type: CategoryType.income)),
                  ),

                  _MenuItem(
                    icon: Icons.arrow_upward,
                    title: "Categorías de gastos",
                    subtitle: "Organiza tus gastos por categoría",
                    onTap: () => _go(context, const CategoriesScreen(type: CategoryType.expense)),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// Activos financieros
              _SectionTitle("Activos financieros"),
              const SizedBox(height: 12),
              _MenuCard(
                items: [
                  _MenuItem(
                    icon: Icons.domain,
                    title: "Entidades bancarias",
                    subtitle: "Organiza tus cuentas por banco",
                    onTap: () => _go(context, const BankEntitiesScreen()),
                  ),
                  _MenuItem(
                    icon: Icons.account_balance,
                    title: "Cuentas bancarias",
                    subtitle: "Gestiona tu dinero disponible",
                    onTap: () => _go(context, const BankAccountsScreen()),
                  ),
                  _MenuItem(
                    icon: Icons.credit_card,
                    title: "Tarjetas de crédito",
                    subtitle: "Controla tu deuda y límites",
                    onTap: () => _go(context, const CreditCardsScreen()),
                  ),
                  _MenuItem(
                    icon: Icons.trending_up,
                    title: "Fondos de inversión",
                    subtitle: "Haz crecer tu dinero",
                    onTap: () => _go(context, const InvestmentFundsScreen()),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// Contactos
              _SectionTitle("Contactos"),
              const SizedBox(height: 12),
              _MenuCard(
                items: [
                  _MenuItem(
                    icon: Icons.people,
                    title: "Mis contactos",
                    subtitle: "Gestiona contactos para gastos compartidos",
                    onTap: () => _go(context, const ContactsScreen()),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// Cuenta
              _SectionTitle("Cuenta"),
              const SizedBox(height: 12),
              _MenuCard(
                items: [_MenuItem(icon: Icons.logout, title: "Cerrar sesión", onTap: _logout)],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

/// 🔹 Section title reutilizable
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(title, style: AppTextStyles.subtitle1(context)),
    );
  }
}

/// 🔹 Card reutilizable
class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(children: [items[index], if (index != items.length - 1) const Divider(height: 1)]);
        }),
      ),
    );
  }
}

/// 🔹 Item reutilizable
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: AppTextStyles.body1(context)),
      subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.caption(context)) : null,
      onTap: onTap,
    );
  }
}
