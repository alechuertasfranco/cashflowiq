import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/staggered_fade_in.dart';
import 'package:cashflowiq/features/profile/presentation/bank_accounts/bank_accounts_screen.dart';
import 'package:cashflowiq/features/profile/presentation/bank_entities/bank_entities_screen.dart';
import 'package:cashflowiq/features/profile/presentation/categories/categories_screen.dart';
import 'package:cashflowiq/features/profile/presentation/credit_cards/credit_cards_screen.dart';
import 'package:cashflowiq/features/profile/presentation/investment_fund/investment_funds_screen.dart';
import 'package:cashflowiq/features/splits/screens/contacts_screen.dart';
import 'package:cashflowiq/features/splits/screens/splits_screen.dart';
import 'package:cashflowiq/features/voucher/presentation/payment_services_screen.dart';
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

    final sections = [
      /// Header
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Perfil", style: context.heading3()),
          const SizedBox(height: 4),
          Text("Gestiona tu cuenta", style: context.textCaption()),
        ],
      ),

      /// User Card
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: context.colorPrimary,
                child: Text(
                  user?.email != null ? user!.email![0].toUpperCase() : "U",
                  style: context.heading4(color: context.colorOnPrimary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(user?.email ?? "Usuario", style: context.textSubtitle1())),
            ],
          ),
        ),
      ),

      /// Categorías
      _Section(
        title: "Categorías",
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

      /// Activos financieros
      _Section(
        title: "Activos financieros",
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

      /// Servicios de pago
      _Section(
        title: "Servicios de pago",
        items: [
          _MenuItem(
            icon: Icons.receipt_long,
            title: "Servicios vinculados",
            subtitle: "Yape, Plin y otros para escanear vouchers",
            onTap: () => _go(context, const PaymentServicesScreen()),
          ),
        ],
      ),

      /// Contactos
      _Section(
        title: "Contactos",
        items: [
          _MenuItem(
            icon: Icons.people,
            title: "Mis contactos",
            subtitle: "Gestiona contactos para gastos compartidos",
            onTap: () => _go(context, const ContactsScreen()),
          ),
          _MenuItem(
            icon: Icons.handshake_outlined,
            title: "Gastos compartidos",
            subtitle: "Revisa deudas pendientes y liquidadas",
            onTap: () => _go(context, const SplitsScreen()),
          ),
        ],
      ),

      /// Cuenta
      _Section(
        title: "Cuenta",
        items: [_MenuItem(icon: Icons.logout, title: "Cerrar sesión", onTap: _logout)],
      ),
    ];

    return Scaffold(
      backgroundColor: context.colorBackground,
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 24),
          itemBuilder: (context, i) => StaggeredFadeIn(index: i, child: sections[i]),
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

/// Section title + menu card, reusable across the profile menu groups.
class _Section extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(title, style: context.textSubtitle1()),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: List.generate(items.length, (index) {
              return Column(
                children: [items[index], if (index != items.length - 1) const Divider(height: 1)],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.colorTextSecondary),
      title: Text(title, style: context.textBody1()),
      subtitle: subtitle != null ? Text(subtitle!, style: context.textCaption()) : null,
      onTap: onTap,
    );
  }
}
