// lib/core/services/notification_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _investmentChannelId = 'investment_reminders';
  static const _investmentChannelName = 'Recordatorios de inversiones';
  static const _monthlyNotificationId = 1001;

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleMonthlyInvestmentReminder() async {
    await _plugin.cancel(_monthlyNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    // Fire on the 1st of next month at 09:00
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, 1, 9, 0);
    if (scheduled.isBefore(now)) {
      final next = DateTime(now.year, now.month + 1, 1);
      scheduled = tz.TZDateTime(tz.local, next.year, next.month, 1, 9, 0);
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _investmentChannelId,
        _investmentChannelName,
        channelDescription: 'Recordatorio mensual para registrar el balance de tus inversiones',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _monthlyNotificationId,
      'Registra el balance de tus inversiones',
      '¿Cuánto vale tu portafolio este mes?',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    debugPrint('Monthly investment reminder scheduled for $scheduled');
  }

  Future<void> cancelMonthlyInvestmentReminder() async {
    await _plugin.cancel(_monthlyNotificationId);
  }
}
