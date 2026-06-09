// lib/core/services/notification_service.dart

import 'dart:convert';
import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/features/transactions/data/recurring_transaction_service.dart';
import 'package:cashflowiq/shared/models/recurring_transaction.dart';
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

  static const _recurringChannelId = 'recurring_reminders';
  static const _recurringChannelName = 'Recordatorios recurrentes';
  static const int _recurringBaseId = 2000;

  /// Set from main.dart to navigate to the variable-amount entry form.
  /// Avoids a circular import between this service and the form screen.
  static Future<void> Function(RecurringTransaction rule)? onVariableAmountTap;

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
      onDidReceiveNotificationResponse: (r) => handlePayload(r.payload),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Create the recurring reminders channel on Android
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _recurringChannelId,
            _recurringChannelName,
            description: 'Recordatorios de transacciones recurrentes',
            importance: Importance.high,
          ),
        );
  }

  // -------------------------------------------------------------------------
  // Notification tap dispatch
  // -------------------------------------------------------------------------

  static Future<void> handlePayload(String? payload) async {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final ruleId = data['ruleId'] as int;
      final isFixed = data['isFixed'] as bool;

      final svc = RecurringTransactionService();
      final rules = await svc.fetchAll();
      final rule = rules.firstWhere((r) => r.id == ruleId);

      if (isFixed) {
        await instance.autoRegister(rule);
      } else {
        await onVariableAmountTap?.call(rule);
      }
    } catch (e) {
      debugPrint('Error handling notification payload: $e');
    }
  }

  Future<void> autoRegister(RecurringTransaction rule) async {
    try {
      final payload = <String, dynamic>{
        'type': rule.type,
        'amount': rule.amount,
        'description': rule.name,
        'date': rule.nextExecutionDate.toIso8601String(),
        'category_id': rule.categoryId,
        'currency_id': rule.currencyId,
        'is_recurring': true,
        'is_fixed': true,
        'recurring_transaction_id': rule.id,
        if (rule.type == 'INCOME') 'to_account_id': rule.accountId,
        if (rule.type == 'EXPENSE' && rule.creditCardId != null)
          'from_credit_card_id': rule.creditCardId,
        if (rule.type == 'EXPENSE' && rule.creditCardId == null)
          'from_account_id': rule.accountId,
      };
      await ApiClient.post('/transactions', body: payload);

      final svc = RecurringTransactionService();
      final updated = await svc.advance(rule.id);
      await scheduleRecurringNotification(updated);

      await showInstant(
        title: 'Transacción registrada',
        body: '${rule.name}: ${rule.currencySymbol ?? ''}${rule.amount!.toStringAsFixed(2)}',
      );
    } catch (e) {
      debugPrint('Auto-register failed: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Investment reminder (existing)
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Recurring transaction reminders
  // -------------------------------------------------------------------------

  Future<void> scheduleRecurringNotification(RecurringTransaction rule) async {
    if (rule.notificationDaysBefore == null || !rule.isActive) return;

    final scheduledDate = rule.nextExecutionDate.subtract(
      Duration(days: rule.notificationDaysBefore!),
    );
    if (scheduledDate.isBefore(DateTime.now())) return;

    final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

    final isFixed = rule.amount != null;
    final body = isFixed
        ? 'Tu transacción de ${rule.currencySymbol ?? ''}${rule.amount!.toStringAsFixed(2)} está lista para registrarse'
        : 'Ingresa el monto de ${rule.name}';

    await _plugin.zonedSchedule(
      _recurringBaseId + rule.id,
      'Recordatorio: ${rule.name}',
      body,
      tzScheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _recurringChannelId,
          _recurringChannelName,
          channelDescription: 'Recordatorios de transacciones recurrentes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'ruleId': rule.id, 'isFixed': isFixed}),
    );
  }

  Future<void> cancelRecurringNotification(int ruleId) async {
    await _plugin.cancel(_recurringBaseId + ruleId);
  }

  Future<void> rescheduleAllRecurringNotifications() async {
    try {
      final service = RecurringTransactionService();
      final rules = await service.fetchAll();
      for (final rule in rules) {
        if (rule.isActive) {
          await scheduleRecurringNotification(rule);
        }
      }
    } catch (e) {
      debugPrint('Failed to reschedule recurring notifications: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Instant notification
  // -------------------------------------------------------------------------

  Future<void> showInstant({required String title, required String body}) async {
    await _plugin.show(
      9999,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notifications',
          'Notificaciones',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
