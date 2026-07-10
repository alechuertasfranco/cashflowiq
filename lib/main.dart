import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/navigation/navigator_key.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'package:cashflowiq/features/auth/presentation/auth_gate.dart';
import 'package:cashflowiq/features/transactions/presentation/recurring/recurring_execution_form_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/.env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register the navigation callback before init so onDidReceiveNotificationResponse
  // can route to the variable-amount form if a notification fires early.
  NotificationService.onVariableAmountTap = (rule) async {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => RecurringExecutionFormScreen(rule: rule),
      ),
    );
  };

  await NotificationService.instance.init();

  // Handle notification taps that launched the app from a terminated state.
  final launchDetails = await FlutterLocalNotificationsPlugin()
      .getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp == true &&
      launchDetails?.notificationResponse?.payload != null) {
    Future.microtask(() => NotificationService.handlePayload(
          launchDetails!.notificationResponse!.payload,
        ));
  }

  runApp(const CashFlowIQApp());
}

class CashFlowIQApp extends StatelessWidget {
  const CashFlowIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CashFlowIQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      navigatorKey: navigatorKey,
      home: const AuthGate(),
    );
  }
}
