import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'package:cashflowiq/features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/.env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CashFlowIQApp());
}

class CashFlowIQApp extends StatelessWidget {
  const CashFlowIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'CashFlowIQ', debugShowCheckedModeBanner: false, theme: AppTheme.light, home: const AuthGate());
  }
}
