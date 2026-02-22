// ============================================================
//  NotificationService – MaaCare
// ============================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:ui' show Color;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);
  }

  Future<void> scheduleDailyMoodCheck() async {
    const androidDetails = AndroidNotificationDetails(
      'mood_check',
      'Daily Check-in',
      channelDescription: 'Remind you to check in with Maa and your baby',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFFB6C1),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Using a curiosity hook for the notification
    await _plugin.periodicallyShow(
      1,
      '✨ Guess what your baby is doing today?',
      'Open MaaCare to see your baby\'s latest progress and tell us how you feel! 💕',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'maacare_general',
      'MaaCare Notifications',
      channelDescription: 'General MaaCare notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details);
  }

  Future<void> scheduleVaccinationReminder({
    required int id,
    required String vaccineName,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'vaccinations',
      'Vaccination Reminders',
      channelDescription: 'Vaccination schedule reminders for your baby',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id,
      '💉 Vaccination Due: $vaccineName',
      'Your baby\'s $vaccineName is due today. Stay on schedule! 🌟',
      details,
    );
  }

  Future<void> cancelAll() async => await _plugin.cancelAll();
}
