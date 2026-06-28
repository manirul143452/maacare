// ============================================================
//  NotificationService – MaaCare v2.0
//  Local (device-level) scheduled notifications using
//  flutter_local_notifications. Works on Android & iOS.
//  Web (PWA) calls are no-ops – handled by OneSignal.
// ============================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// ── Notification Channel IDs ──────────────────────────────────
const _chPregnancy = 'pregnancy_milestone_v2';
const _chChild = 'child_growth_v2';
const _chVaccination = 'vaccinations_v2';
const _chDoctor = 'doctor_consult_v2';
const _chNutrition = 'nutrition_daily_v2';
const _chSelfCare = 'self_care_daily_v2';
const _chSymptom = 'symptom_check_v2';
const _chTracker = 'tracker_sync_v2';
const _chCommunity = 'community_updates_v2';
const _chSafety = 'safety_alerts_v2';
const _chGeneral = 'maacare_general_v2';

// ── MaaCare brand color ──────────────────────────────────────
const _maaColor = Color(0xFFFF69B4); // MaaColors.pink

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ============================================================
  //  Initialization
  // ============================================================
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    tz_data.initializeTimeZones();
    // Set IST timezone as default
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

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

    await _plugin.initialize(
      initSettings,
      // Handle notification tap when app is in foreground
      onDidReceiveNotificationResponse: (details) {
        // payload is the route string
        // Deep linking is handled in main.dart via PushNotificationService
      },
    );

    // Create all notification channels (Android 8+)
    await _createAndroidChannels();
    _initialized = true;
  }

  Future<void> _createAndroidChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    final channels = [
      const AndroidNotificationChannel(
        _chPregnancy,
        'Pregnancy Milestones',
        description: 'Weekly pregnancy progress and milestones',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      const AndroidNotificationChannel(
        _chChild,
        'Child Growth & Milestones',
        description: "Baby's age-based growth and development alerts",
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      const AndroidNotificationChannel(
        _chVaccination,
        'Vaccination Reminders',
        description: 'Indian UIP/NIS vaccination schedule reminders',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      const AndroidNotificationChannel(
        _chDoctor,
        'Doctor Consultations',
        description: 'Appointment reminders and consultation updates',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      const AndroidNotificationChannel(
        _chNutrition,
        'Nutrition & Diet Tips',
        description: 'Daily personalized nutrition tips and meal plans',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      const AndroidNotificationChannel(
        _chSelfCare,
        'Yoga & Self-Care',
        description: 'Daily yoga and self-care session reminders',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      const AndroidNotificationChannel(
        _chSymptom,
        'Symptom Checker',
        description: 'AI-powered symptom monitoring reminders',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      const AndroidNotificationChannel(
        _chTracker,
        'Tracker Reminders',
        description: 'Pregnancy & health tracker update reminders',
        importance: Importance.defaultImportance,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      const AndroidNotificationChannel(
        _chCommunity,
        'Community Updates',
        description: 'Parents Park posts, replies and connections',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      const AndroidNotificationChannel(
        _chSafety,
        'Safety & Urgent Alerts',
        description: 'Critical health alerts and security notices',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableLights: true,
      ),
      const AndroidNotificationChannel(
        _chGeneral,
        'MaaCare General',
        description: 'App updates and general notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
    ];

    for (final ch in channels) {
      await androidPlugin.createNotificationChannel(ch);
    }
  }

  // ============================================================
  //  Notification Detail Builders
  // ============================================================
  NotificationDetails _buildDetails({
    required String channelId,
    required String channelName,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
    bool isUrgent = false,
  }) {
    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: isUrgent ? Importance.max : importance,
      priority: isUrgent ? Priority.max : priority,
      color: _maaColor,
      enableLights: isUrgent,
      ledColor: _maaColor,
      ledOnMs: 1000,
      ledOffMs: 500,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.wav',
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  // ============================================================
  //  Show Instant Notification
  // ============================================================
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String channelId = _chGeneral,
    String channelName = 'MaaCare General',
    String? payload, // route for deep link
    bool isUrgent = false,
  }) async {
    if (kIsWeb) return;
    await _plugin.show(
      id,
      title,
      body,
      _buildDetails(
          channelId: channelId, channelName: channelName, isUrgent: isUrgent),
      payload: payload,
    );
  }

  // ============================================================
  //  Pregnancy Milestone – scheduled at computed week date
  // ============================================================
  Future<void> schedulePregnancyWeekReminder({
    required int week,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb) return;

    final titles = {
      4: '🌱 Week 4 Shuru!',
      8: '🫐 Week 8 – Baby Ka Dil!',
      12: '🍋 Pehla Trimester Complete!',
      16: '🥑 Week 16 – Pehli Kick?',
      20: '🍌 Week 20 – Aadha Safar!',
      24: '🌽 Week 24 – Baby Sun Raha Hai!',
      28: '🍆 Teesra Trimester Shuru!',
      32: '🥥 Week 32 Milestone!',
      36: '🍈 Almost There – Week 36!',
      40: '🍉 Due Date Week!',
    };
    final bodies = {
      4: 'Pehla appointment book karo – pehle 3 months most important hote hain 💕',
      8: 'Baby ki heartbeat check karwao! Yeh magical moment miss mat karna 💗',
      12: 'Pehla trimester poora! NT scan aur blood tests schedule karo 🌟',
      16: 'Shayad pehli kicks mehsoos hon – baby flutter feel karo! 💝',
      20: 'Anatomy scan ka time! Baby ab banana jitna bada hai 🎉',
      24: 'Baby ab awaazein sun sakta hai – usse lori sunao! 🎵',
      28: 'Teesra trimester! Hospital bag list banao aur birth plan socho 🏥',
      32: 'Baby ab ulta ho raha hai – breathing exercises karo 🧘',
      36: 'Sirf 4 hafte! Hospital bag pack karo Mama 💪',
      40: 'Aap itni brave ho! Doctor se connected raho 💕',
    };

    final id = 1000 + week; // Unique ID per week
    await _plugin.zonedSchedule(
      id,
      titles[week] ?? '🤰 Week $week Milestone!',
      bodies[week] ?? 'Aapka baby is hafte naya vikas kar raha hai 💗',
      tz.TZDateTime.from(scheduledDate, tz.local),
      _buildDetails(
          channelId: _chPregnancy, channelName: 'Pregnancy Milestones'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/tracker',
    );
  }

  // ============================================================
  //  Child Growth Milestone – scheduled by DOB + age
  // ============================================================
  Future<void> scheduleChildMilestoneReminder({
    required int ageInMonths,
    required DateTime scheduledDate,
    required String childName,
  }) async {
    if (kIsWeb) return;

    final id = 2000 + ageInMonths;
    final name = childName.isEmpty ? 'Baby' : childName;

    final Map<int, String> titles = {
      1: '🎉 $name Ka Pehla Mahina!',
      2: '😊 2 Maheene – Pehli Muskaan!',
      4: '🦷 $name 4 Maheene Ka!',
      6: '🥣 6 Maheene – Solid Foods!',
      9: '🚶 $name 9 Maheene Ka!',
      12: '🎂 Pehla Birthday!',
      15: '💬 $name 15 Maheene Ka!',
      18: '🗣️ 18 Maheene – Baat Karna!',
      24: '🎒 2 Saal!',
      36: '🎨 3 Saal!',
      48: '📚 4 Saal!',
      60: '🏫 5 Saal – School Ready!',
    };
    final Map<int, String> bodies = {
      1: 'Pehla mahina! Doctor se routine checkup schedule karein 👶',
      2: 'Baby ab social smile deta hai! Camera ready rakho 📸',
      4: '4 maheene! Baby ab awaazein recognise karta hai 🎵',
      6: 'Solid foods shuru karo – rice cereal ya banana try karo 🍌',
      9: '9 maheene! Baby ab crawl karne ki koshish kar raha hai 🚀',
      12: 'Pehla birthday! Pehle kadam ka wait karo 🎉',
      15: 'Baby ab zyada words bol raha hai – encourage karo 📢',
      18: '18 maheene – baby ab 10-20 words bol sakta hai 🗣️',
      24: '2 saal! Preschool ki taiyaari shuru karo 🌈',
      36: '3 saal! Independence aur curiosity badh rahi hai 🌟',
      48: '4 saal! Reading aur writing ki preparation 📖',
      60: 'School time! $name ki school readiness check karo 🎒',
    };

    await _plugin.zonedSchedule(
      id,
      titles[ageInMonths] ?? '👶 $name Ka $ageInMonths Maheene Milestone!',
      bodies[ageInMonths] ??
          '$name ka growth check karein aur doctor se milein 💕',
      tz.TZDateTime.from(scheduledDate, tz.local),
      _buildDetails(
          channelId: _chChild, channelName: 'Child Growth & Milestones'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/child-growth',
    );
  }

  // ============================================================
  //  Doctor Appointment – 48h, 24h, 15min reminders
  // ============================================================
  Future<void> scheduleDoctorAppointmentReminder({
    required int baseId, // Use appointment_id hash
    required String doctorName,
    required DateTime appointmentTime,
  }) async {
    if (kIsWeb) return;

    final reminders = [
      {
        'offset': const Duration(hours: -48),
        'id': baseId + 1,
        'title': '📅 Kal Consultation Hai!',
        'body':
            'Dr. $doctorName ke saath kal appointment hai. Questions tayaar karo 📋',
      },
      {
        'offset': const Duration(hours: -24),
        'id': baseId + 2,
        'title': '⏰ Kal Subah Appointment!',
        'body': 'Dr. $doctorName – kal appointment hai. Symptom list ready? 💙',
      },
      {
        'offset': const Duration(minutes: -15),
        'id': baseId + 3,
        'title': '🚀 15 Min Mein Consult!',
        'body':
            'Dr. $doctorName aapka intezaar kar rahe hain! Abhi join karo 👩‍⚕️',
      },
    ];

    final details = _buildDetails(
        channelId: _chDoctor,
        channelName: 'Doctor Consultations',
        importance: Importance.max,
        isUrgent: true);

    for (final r in reminders) {
      final scheduled = appointmentTime.add(r['offset'] as Duration);
      if (scheduled.isAfter(DateTime.now())) {
        await _plugin.zonedSchedule(
          r['id'] as int,
          r['title'] as String,
          r['body'] as String,
          tz.TZDateTime.from(scheduled, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: '/consult',
        );
      }
    }
  }

  // ============================================================
  //  Vaccination Reminder – 7d, 1d, day-of, overdue
  // ============================================================
  Future<void> scheduleVaccinationReminder({
    required int id,
    required String vaccineName,
    required DateTime dueDate,
  }) async {
    if (kIsWeb) return;

    final details = _buildDetails(
        channelId: _chVaccination,
        channelName: 'Vaccination Reminders',
        isUrgent: true);

    final reminders = [
      {
        'offset': const Duration(days: -7),
        'id': id * 10 + 1,
        'title': '💉 $vaccineName – 7 Din Mein!',
        'body':
            'Baby ki $vaccineName 7 din baad due hai. Nearest center book karein 🏥',
      },
      {
        'offset': const Duration(days: -1),
        'id': id * 10 + 2,
        'title': '⚠️ $vaccineName – Kal Due!',
        'body':
            'Kal baby ki $vaccineName hai! Center ki location confirm karo 📍',
      },
      {
        'offset': Duration.zero,
        'id': id * 10 + 3,
        'title': '🔴 $vaccineName – Aaj Due!',
        'body':
            'Baby ki $vaccineName aaj due hai! Vaccinations screen se center dekho 🏥',
      },
    ];

    for (final r in reminders) {
      final scheduled = dueDate.add(r['offset'] as Duration);
      if (scheduled.isAfter(DateTime.now())) {
        await _plugin.zonedSchedule(
          r['id'] as int,
          r['title'] as String,
          r['body'] as String,
          tz.TZDateTime.from(scheduled, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: '/vaccinations',
        );
      }
    }
  }

  // ============================================================
  //  Daily Nutrition Tip – 9 AM IST every day
  // ============================================================
  Future<void> scheduleDailyNutritionTip() async {
    if (kIsWeb) return;
    await _plugin.periodicallyShow(
      5001,
      '🥗 Aaj Ka Poshan Tip!',
      'Aaj ka personalized nutrition plan ready hai. Healthy mama = healthy baby! 💚',
      RepeatInterval.daily,
      _buildDetails(
          channelId: _chNutrition,
          channelName: 'Nutrition & Diet Tips',
          importance: Importance.defaultImportance),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '/nutrition',
    );
  }

  // ============================================================
  //  Daily Self-Care – 7 PM IST every day
  // ============================================================
  Future<void> scheduleDailySelfCareReminder() async {
    if (kIsWeb) return;
    await _plugin.periodicallyShow(
      5002,
      '🧘 Shaam Ki Self-Care!',
      'Aaj 10 min yoga ya meditation karo. Mama ki care zaroori hai! 💕',
      RepeatInterval.daily,
      _buildDetails(
          channelId: _chSelfCare,
          channelName: 'Yoga & Self-Care',
          importance: Importance.defaultImportance),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '/self-care',
    );
  }

  // ============================================================
  //  Daily Mood Check – engagement hook
  // ============================================================
  Future<void> scheduleDailyMoodCheck() async {
    if (kIsWeb) return;
    await _plugin.periodicallyShow(
      1,
      '✨ Guess What Your Baby Is Doing Today?',
      'Open MaaCare to see baby\'s latest progress and tell us how you feel! 💕',
      RepeatInterval.daily,
      _buildDetails(
          channelId: _chGeneral,
          channelName: 'MaaCare General',
          importance: Importance.defaultImportance),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '/tracker',
    );
  }

  // ============================================================
  //  Tracker Sync Reminder – scheduled once in future
  // ============================================================
  Future<void> scheduleTrackerSyncReminder({
    required int id,
    required DateTime scheduledTime,
  }) async {
    if (kIsWeb) return;
    await _plugin.zonedSchedule(
      id,
      '📈 Tracker Update Karo!',
      'Kaafi din ho gaye update kiye bina! Aapki progress track karna zaruri hai 💕',
      tz.TZDateTime.from(scheduledTime, tz.local),
      _buildDetails(
          channelId: _chTracker,
          channelName: 'Tracker Reminders',
          importance: Importance.low),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/tracker',
    );
  }

  // ============================================================
  //  Unmarried Girl Pad Change Timer (Every 4 Hours)
  // ============================================================
  Future<void> schedulePadChangeTimer() async {
    if (kIsWeb) return;
    await _plugin.periodicallyShow(
      5005,
      '🩸 Sanitary Pad Change Reminder 🌸',
      'Hey Sakhi, it\'s time to change or check your pad for comfort and hygiene! Stay fresh and healthy. 💕',
      RepeatInterval.daily, // Use daily as fallback periodic reminder
      _buildDetails(
        channelId: _chSelfCare,
        channelName: 'Yoga & Self-Care',
        importance: Importance.high,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '/self-care',
    );
  }

  // ============================================================
  //  Pregnant Mother Vaccination Check (Daily)
  // ============================================================
  Future<void> scheduleDailyVaccinationCheck() async {
    if (kIsWeb) return;
    await _plugin.periodicallyShow(
      5006,
      '💉 Vaccination Calendar Update!',
      'Aapki vaccination calendar update ho chuki hai. Check upcoming vaccines to stay safe! 🏥',
      RepeatInterval.daily,
      _buildDetails(
        channelId: _chVaccination,
        channelName: 'Vaccination Reminders',
        importance: Importance.defaultImportance,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '/vaccinations',
    );
  }

  // ============================================================
  //  Safety Alert – ignores quiet hours, max priority
  // ============================================================
  Future<void> showSafetyAlert({
    required String title,
    required String body,
    int id = 9999,
  }) async {
    if (kIsWeb) return;
    await _plugin.show(
      id,
      title,
      body,
      _buildDetails(
          channelId: _chSafety,
          channelName: 'Safety & Urgent Alerts',
          isUrgent: true),
      payload: '/symptoms',
    );
  }

  // ============================================================
  //  Daily Pill Reminder
  // ============================================================
  Future<void> scheduleDailyPillReminder({
    required int id,
    required String pillName,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;

    final now = DateTime.now();
    var scheduledDateTime = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      '💊 Pill Reminder 🌸',
      'Hey Sakhi, it\'s time to take your daily pill: $pillName.',
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      _buildDetails(
        channelId: _chSelfCare,
        channelName: 'Yoga & Self-Care',
        importance: Importance.high,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/contraception_tracker',
    );
  }

  // ============================================================
  //  Hygiene Pad/Cup Change Reminders
  //  flutter_local_notifications doesn't support custom intervals,
  //  so we schedule individual notifications for the next 24 hours.
  // ============================================================
  Future<void> scheduleHygieneReminders({required int intervalHours}) async {
    if (kIsWeb) return;

    // Cancel any existing hygiene reminders first (IDs 9000–9023)
    await cancelHygieneReminders();

    final now = DateTime.now();
    int notifIndex = 0;

    for (int hoursFromNow = intervalHours;
        hoursFromNow <= 24;
        hoursFromNow += intervalHours) {
      final scheduledTime = now.add(Duration(hours: hoursFromNow));
      final id = 9000 + notifIndex;

      await _plugin.zonedSchedule(
        id,
        '🩸 Pad/Cup Change Reminder',
        'Hey! It\'s been $intervalHours hours. Time to change your pad or menstrual cup 🌸',
        tz.TZDateTime.from(scheduledTime, tz.local),
        _buildDetails(
          channelId: _chSelfCare,
          channelName: 'Yoga & Self-Care',
          importance: Importance.high,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '/period_dashboard',
      );
      notifIndex++;
    }
  }

  Future<void> cancelHygieneReminders() async {
    if (kIsWeb) return;
    // Cancel all hygiene reminder IDs (9000–9023)
    for (int i = 9000; i < 9024; i++) {
      await _plugin.cancel(i);
    }
  }

  // ============================================================
  //  Cancel & Clear
  // ============================================================
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}

