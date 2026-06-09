import 'package:cashflowiq/core/services/notification_service.dart';
import 'package:cashflowiq/features/main/presentation/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          // Reschedule all recurring notifications each time the user is authenticated.
          // Uses fire-and-forget — failures are logged inside the method.
          NotificationService.instance.rescheduleAllRecurringNotifications();
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
