import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

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
                        child: Text(user?.email != null ? user!.email![0].toUpperCase() : "U", style: AppTextStyles.h400(context).copyWith(color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text(user?.email ?? "Usuario", style: AppTextStyles.subtitle1(context))),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// Actions
              Text("Cuenta", style: AppTextStyles.subtitle1(context)),
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
