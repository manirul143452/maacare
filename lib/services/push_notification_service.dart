// ============================================================
//  PushNotificationService – MaaCare v2.0
//  Complete push notification system with OneSignal + InsForge
//  Supports 14 notification categories across all app features
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'secure_storage_service.dart';
import 'auth_service.dart';

// OneSignal App ID – Replace with your actual OneSignal App ID
// Get this from OneSignal Dashboard: https://app.onesignal.com
const String kOneSignalAppId = 'YOUR_ONESIGNAL_APP_ID_HERE';

// ============================================================
//  Notification Categories – 14 total (Indian Mama focused)
// ============================================================
enum NotificationCategory {
  // ── Baby & Pregnancy ──
  pregnancyMilestone('pregnancy_milestone', 'Pregnancy Milestones', '🤰',
      'Baby & Pregnancy'),
  childGrowth('child_growth', 'Child Growth & Milestones', '👶',
      'Baby & Pregnancy'),
  vaccination(
      'vaccination', 'Vaccination Reminders', '💉', 'Health & Medical'),

  // ── Health & Medical ──
  doctorConsult(
      'doctor_consult', 'Doctor Consultations', '👩‍⚕️', 'Health & Medical'),
  symptomCheck(
      'symptom_check', 'Symptom Checker', '🩺', 'Health & Medical'),
  healthInsights(
      'health_insights', 'Health Insights', '📊', 'Health & Medical'),
  safetyAlert(
      'safety_alert', 'Safety & Urgent Alerts', '🚨', 'Health & Medical'),

  // ── Wellness & Nutrition ──
  nutrition('nutrition', 'Nutrition & Diet Tips', '🥗',
      'Wellness & Nutrition'),
  selfCare('self_care', 'Yoga & Self-Care', '🧘', 'Wellness & Nutrition'),
  trackerSync(
      'tracker_sync', 'Tracker Reminders', '📈', 'Wellness & Nutrition'),

  // ── Community & Social ──
  community('community', 'Parents Park Updates', '💬', 'Community & Social'),
  friendRequest(
      'friend_request', 'Friend Requests', '🤝', 'Community & Social'),

  // ── System ──
  healthNews('health_news', 'Health News & Articles', '📰', 'System'),
  general('general', 'General Updates', '🔔', 'System');

  final String key;
  final String label;
  final String emoji;
  final String group; // UI grouping

  const NotificationCategory(this.key, this.label, this.emoji, this.group);
}

// ============================================================
//  Notification Payload – standardized across all features
// ============================================================
class NotificationPayload {
  final String type;
  final String? route;
  final Map<String, dynamic>? data;
  final String? title;
  final String? body;
  final String? actionButton1Label;
  final String? actionButton1Route;
  final String? actionButton2Label;
  final String? imageUrl;

  NotificationPayload({
    required this.type,
    this.route,
    this.data,
    this.title,
    this.body,
    this.actionButton1Label,
    this.actionButton1Route,
    this.actionButton2Label,
    this.imageUrl,
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPayload(
      type: map['type'] ?? 'general',
      route: map['route'],
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      title: map['title'],
      body: map['body'],
      actionButton1Label: map['action1_label'],
      actionButton1Route: map['action1_route'],
      actionButton2Label: map['action2_label'],
      imageUrl: map['image_url'],
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        if (route != null) 'route': route,
        if (data != null) 'data': data,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (actionButton1Label != null) 'action1_label': actionButton1Label,
        if (actionButton1Route != null) 'action1_route': actionButton1Route,
        if (actionButton2Label != null) 'action2_label': actionButton2Label,
        if (imageUrl != null) 'image_url': imageUrl,
      };
}

// ============================================================
//  Notification Item – for in-app Notification Center
// ============================================================
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final String? route;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? actionButton1Label;
  final String? actionButton1Route;
  final String? actionButton2Label;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.route,
    this.data,
    this.imageUrl,
    this.actionButton1Label,
    this.actionButton1Route,
    this.actionButton2Label,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category.key,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'route': route,
        'data': data,
        'imageUrl': imageUrl,
        'action1_label': actionButton1Label,
        'action1_route': actionButton1Route,
        'action2_label': actionButton2Label,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      category: NotificationCategory.values.firstWhere(
        (c) => c.key == json['category'],
        orElse: () => NotificationCategory.general,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      route: json['route'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      imageUrl: json['imageUrl'],
      actionButton1Label: json['action1_label'],
      actionButton1Route: json['action1_route'],
      actionButton2Label: json['action2_label'],
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      category: category,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      route: route,
      data: data,
      imageUrl: imageUrl,
      actionButton1Label: actionButton1Label,
      actionButton1Route: actionButton1Route,
      actionButton2Label: actionButton2Label,
    );
  }
}

// ============================================================
//  Quiet Hours Settings
// ============================================================
class QuietHoursSettings {
  final bool enabled;
  final int startHour; // 0–23
  final int endHour; // 0–23

  const QuietHoursSettings({
    this.enabled = true,
    this.startHour = 22, // 10 PM
    this.endHour = 7, // 7 AM
  });

  bool get isCurrentlyQuiet {
    if (!enabled) return false;
    final now = DateTime.now();
    final hour = now.hour;
    if (startHour > endHour) {
      // Spans midnight (e.g. 22–7)
      return hour >= startHour || hour < endHour;
    }
    return hour >= startHour && hour < endHour;
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'start': startHour,
        'end': endHour,
      };

  factory QuietHoursSettings.fromJson(Map<String, dynamic> json) {
    return QuietHoursSettings(
      enabled: json['enabled'] ?? true,
      startHour: json['start'] ?? 22,
      endHour: json['end'] ?? 7,
    );
  }
}

// ============================================================
//  PushNotificationService – Main Service Class
// ============================================================
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  // ── Streams ──
  final _notificationController =
      StreamController<NotificationPayload>.broadcast();
  final _badgeCountController = StreamController<int>.broadcast();
  final _permissionController = StreamController<bool>.broadcast();

  Stream<NotificationPayload> get onNotificationReceived =>
      _notificationController.stream;
  Stream<int> get onBadgeCountChanged => _badgeCountController.stream;
  Stream<bool> get onPermissionChanged => _permissionController.stream;

  // ── State ──
  String? _playerId;
  String? _subscriptionId;
  String? _fcmToken;
  bool _isInitialized = false;
  int _unreadCount = 0;
  List<NotificationItem> _notifications = [];
  Map<String, bool> _categorySettings = {};
  QuietHoursSettings _quietHours = const QuietHoursSettings();
  String _notificationFrequency = 'smart'; // 'daily', 'weekly', 'smart'

  // ── Getters ──
  String? get playerId => _playerId;
  String? get subscriptionId => _subscriptionId;
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
  int get unreadCount => _unreadCount;
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  QuietHoursSettings get quietHours => _quietHours;
  String get notificationFrequency => _notificationFrequency;

  // ============================================================
  //  Initialization
  // ============================================================
  Future<void> initialize() async {
    if (_isInitialized) return;
    _fcmToken = 'mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
    if (kIsWeb) {
      debugPrint(
          'PUSH_NOTIFICATION: Web platform – OneSignal skipped (PWA mode)');
      await _loadNotifications();
      await _loadCategorySettings();
      _isInitialized = true;
      return;
    }

    debugPrint('PUSH_NOTIFICATION: Initializing OneSignal v5...');

    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(kOneSignalAppId);

    await OneSignal.Notifications.requestPermission(true);
    _setupNotificationHandlers();
    await _getPlayerId();
    await _loadNotifications();
    await _loadCategorySettings();
    _isInitialized = true;

    // Observe permission changes
    OneSignal.Notifications.addPermissionObserver((state) {
      _permissionController.add(state);
    });

    // Observe subscription changes
    OneSignal.User.addObserver((state) => _getPlayerId());

    _isInitialized = true;
    debugPrint('PUSH_NOTIFICATION: Initialized ✅ | Player ID: $_playerId');
  }

  void _setupNotificationHandlers() {
    // ── Foreground received ──
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      final payload = _extractPayload(event.notification);
      _notificationController.add(payload);
      addNotificationFromPayload(payload);
      _updateBadgeCount();

      // Respect quiet hours & category settings
      if (_isCategoryEnabled(payload.type) && !_quietHours.isCurrentlyQuiet) {
        event.notification.display();
      }
    });

    // ── Notification tapped (background / terminated) ──
    OneSignal.Notifications.addClickListener((event) {
      final payload = _extractPayload(event.notification);
      _notificationController.add(payload);
      _markNotificationRead(payload.type);
    });

    // ── In-app message clicked ──
    OneSignal.InAppMessages.addClickListener((event) {
      debugPrint('PUSH_NOTIFICATION: In-app message clicked action: '
          '${event.result.actionId}');
    });
  }

  NotificationPayload _extractPayload(OSNotification notification) {
    final d = notification.additionalData ?? {};
    return NotificationPayload(
      type: d['type'] ?? 'general',
      route: d['route'],
      data: d['data'] != null ? Map<String, dynamic>.from(d['data']) : null,
      title: notification.title,
      body: notification.body,
      actionButton1Label: d['action1_label'],
      actionButton1Route: d['action1_route'],
      actionButton2Label: d['action2_label'],
      imageUrl: notification.bigPicture,
    );
  }

  // ============================================================
  //  Backend Sync – Player ID to InsForge
  // ============================================================
  Future<void> _getPlayerId() async {
    try {
      _playerId = OneSignal.User.pushSubscription.id;
      _subscriptionId = OneSignal.User.pushSubscription.token;
      await _syncPlayerIdToBackend();
    } catch (e) {
      debugPrint('PUSH_NOTIFICATION: Error getting Player ID: $e');
    }
  }

  /// Call after user login/register to associate push token with user account
  Future<void> syncPlayerIdToBackend(String userId) async {
    if (_playerId == null && _fcmToken == null) return;
    try {
      if (_playerId != null) {
        await SecureStorageService.instance
            .write('onesignal_player_id', _playerId!);
      }
      if (_fcmToken != null) {
        await SecureStorageService.instance
            .write('fcm_token', _fcmToken!);
      }

      final url = Uri.parse(
        '${AppConstants.backendUrl}/api/database/records/users?id=eq.$userId',
      );
      await http.patch(
        url,
        headers: AuthService.instance.getAuthHeaders(),
        body: jsonEncode({
          if (_playerId != null) 'onesignal_player_id': _playerId,
          if (_fcmToken != null) 'fcm_token': _fcmToken,
          'push_token_updated_at': DateTime.now().toIso8601String(),
          'platform': kIsWeb
              ? 'web'
              : (defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'android'),
        }),
      );
      debugPrint('PUSH_NOTIFICATION: Push tokens synced to backend ✅');
    } catch (e) {
      debugPrint('PUSH_NOTIFICATION: Sync error: $e');
    }
  }

  Future<void> _syncPlayerIdToBackend() async {
    final userId = AuthService.instance.getCurrentUserId();
    if (userId != null) await syncPlayerIdToBackend(userId);
  }

  // ============================================================
  //  Notification Center – Storage & Management
  // ============================================================
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('maacare_notifications') ?? [];
      _notifications = raw
          .map((s) => NotificationItem.fromJson(jsonDecode(s)))
          .toList();
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _updateBadgeCount();
    } catch (e) {
      debugPrint('PUSH_NOTIFICATION: Load error: $e');
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'maacare_notifications',
        _notifications.map((n) => jsonEncode(n.toJson())).toList(),
      );
    } catch (e) {
      debugPrint('PUSH_NOTIFICATION: Save error: $e');
    }
  }

  /// Add a notification from a received push payload
  void addNotificationFromPayload(NotificationPayload payload) {
    final category = NotificationCategory.values.firstWhere(
      (c) => c.key == payload.type,
      orElse: () => NotificationCategory.general,
    );
    final notification = NotificationItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${category.key}',
      title: payload.title ?? 'MaaCare',
      body: payload.body ?? '',
      category: category,
      timestamp: DateTime.now(),
      route: payload.route,
      data: payload.data,
      imageUrl: payload.imageUrl,
      actionButton1Label: payload.actionButton1Label,
      actionButton1Route: payload.actionButton1Route,
      actionButton2Label: payload.actionButton2Label,
    );
    _notifications.insert(0, notification);
    if (_notifications.length > 150) {
      _notifications = _notifications.sublist(0, 150);
    }
    _saveNotifications();
  }

  /// Add a notification directly (used by local/in-app triggers)
  Future<void> addLocalNotification({
    required String title,
    required String body,
    required NotificationCategory category,
    String? route,
    Map<String, dynamic>? data,
    String? actionButton1Label,
    String? actionButton1Route,
    String? actionButton2Label,
  }) async {
    final item = NotificationItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${category.key}',
      title: title,
      body: body,
      category: category,
      timestamp: DateTime.now(),
      route: route,
      data: data,
      actionButton1Label: actionButton1Label,
      actionButton1Route: actionButton1Route,
      actionButton2Label: actionButton2Label,
    );
    _notifications.insert(0, item);
    if (_notifications.length > 150) {
      _notifications = _notifications.sublist(0, 150);
    }
    await _saveNotifications();
    _updateBadgeCount();
  }

  void _updateBadgeCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    _badgeCountController.add(_unreadCount);
  }

  Future<void> markAsRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      await _saveNotifications();
      _updateBadgeCount();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _saveNotifications();
    _updateBadgeCount();
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    _updateBadgeCount();
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    _updateBadgeCount();
  }

  /// Returns notifications filtered by category
  List<NotificationItem> getByCategory(NotificationCategory? category) {
    if (category == null) return notifications;
    return _notifications.where((n) => n.category == category).toList();
  }

  void _markNotificationRead(String type) {
    final idx = _notifications
        .indexWhere((n) => n.category.key == type && !n.isRead);
    if (idx != -1) markAsRead(_notifications[idx].id);
  }

  // ============================================================
  //  Category Settings
  // ============================================================
  Future<void> _loadCategorySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('maacare_notification_settings');
      if (raw != null) {
        _categorySettings =
            Map<String, bool>.from(jsonDecode(raw));
      } else {
        _resetCategoryDefaults();
      }
      // Load quiet hours
      final qhRaw = prefs.getString('maacare_quiet_hours');
      if (qhRaw != null) {
        _quietHours =
            QuietHoursSettings.fromJson(jsonDecode(qhRaw));
      }
      // Load frequency
      _notificationFrequency =
          prefs.getString('maacare_notif_frequency') ?? 'smart';
    } catch (e) {
      _resetCategoryDefaults();
    }
  }

  void _resetCategoryDefaults() {
    for (final cat in NotificationCategory.values) {
      _categorySettings[cat.key] = true;
    }
  }

  Future<void> _saveCategorySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'maacare_notification_settings', jsonEncode(_categorySettings));
  }

  bool isCategoryEnabled(NotificationCategory category) =>
      _categorySettings[category.key] ?? true;

  bool _isCategoryEnabled(String key) => _categorySettings[key] ?? true;

  Future<void> setCategoryEnabled(
      NotificationCategory category, bool enabled) async {
    _categorySettings[category.key] = enabled;
    await _saveCategorySettings();
    if (!kIsWeb) {
      await OneSignal.User.addTagWithKey(
          category.key, enabled ? 'enabled' : 'disabled');
    }
  }

  Map<NotificationCategory, bool> getAllCategorySettings() => {
        for (final c in NotificationCategory.values)
          c: _categorySettings[c.key] ?? true,
      };

  Future<void> setQuietHours(QuietHoursSettings settings) async {
    _quietHours = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'maacare_quiet_hours', jsonEncode(settings.toJson()));
  }

  Future<void> setNotificationFrequency(String frequency) async {
    _notificationFrequency = frequency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('maacare_notif_frequency', frequency);
  }

  // ============================================================
  //  Permission Management
  // ============================================================
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final granted =
        await OneSignal.Notifications.requestPermission(true);
    _permissionController.add(granted);
    return granted;
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    return OneSignal.Notifications.permission;
  }

  void openSettings() {
    if (!kIsWeb) {
      OneSignal.Notifications.requestPermission(true);
    }
  }

  // ============================================================
  //  Feature-Specific Trigger Helpers
  //  These call the InsForge edge function: /functions/send-notification
  //  AND add to in-app notification center
  // ============================================================

  /// Pregnancy milestone (week 4,8,12,16,20,24,28,32,36,40)
  Future<void> triggerPregnancyMilestone({
    required int week,
    required String userName,
  }) async {
    if (!isCategoryEnabled(NotificationCategory.pregnancyMilestone)) return;
    if (_quietHours.isCurrentlyQuiet) return;

    final content = _getPregnancyMilestoneContent(week, userName);
    await addLocalNotification(
      title: content['title']!,
      body: content['body']!,
      category: NotificationCategory.pregnancyMilestone,
      route: '/tracker',
      data: {'week': week},
      actionButton1Label: 'Tracker Dekho',
      actionButton1Route: '/tracker',
    );
  }

  /// Child growth milestone (age in months)
  Future<void> triggerChildGrowthMilestone({
    required int ageInMonths,
    required String childName,
  }) async {
    if (!isCategoryEnabled(NotificationCategory.childGrowth)) return;
    if (_quietHours.isCurrentlyQuiet) return;

    final content = _getChildGrowthContent(ageInMonths, childName);
    await addLocalNotification(
      title: content['title']!,
      body: content['body']!,
      category: NotificationCategory.childGrowth,
      route: '/child-growth',
      data: {'age_months': ageInMonths, 'child_name': childName},
      actionButton1Label: 'Milestones Dekho',
    );
  }

  /// Doctor consultation reminder
  Future<void> triggerDoctorConsultReminder({
    required String appointmentId,
    required String doctorName,
    required DateTime appointmentTime,
    required String reminderType, // '48h', '24h', '15min', 'post'
  }) async {
    if (!isCategoryEnabled(NotificationCategory.doctorConsult)) return;

    final content =
        _getDoctorConsultContent(doctorName, appointmentTime, reminderType);
    await addLocalNotification(
      title: content['title']!,
      body: content['body']!,
      category: NotificationCategory.doctorConsult,
      route: '/consult',
      data: {'appointment_id': appointmentId, 'doctor_name': doctorName},
      actionButton1Label: reminderType == 'post' ? 'Summary Dekho' : 'Join Karo',
      actionButton1Route: '/consult',
      actionButton2Label: reminderType == 'post' ? null : 'Reschedule',
    );
  }

  /// Vaccination reminder
  Future<void> triggerVaccinationReminder({
    required String vaccineName,
    required DateTime dueDate,
    required String reminderType, // '7d', '1d', 'today', 'overdue'
    required String vaccinationId,
  }) async {
    if (!isCategoryEnabled(NotificationCategory.vaccination)) return;

    final content =
        _getVaccinationContent(vaccineName, dueDate, reminderType);
    await addLocalNotification(
      title: content['title']!,
      body: content['body']!,
      category: NotificationCategory.vaccination,
      route: '/vaccinations',
      data: {'vaccination_id': vaccinationId, 'vaccine_name': vaccineName},
      actionButton1Label: 'Schedule Karo',
      actionButton1Route: '/vaccinations',
    );
  }

  /// Symptom checker alert (AI-powered urgency)
  Future<void> triggerSymptomAlert({
    required String riskLevel, // 'low', 'medium', 'high'
    required String symptomSummary,
  }) async {
    if (!isCategoryEnabled(NotificationCategory.symptomCheck)) return;

    final isUrgent = riskLevel == 'high';
    final category = isUrgent
        ? NotificationCategory.safetyAlert
        : NotificationCategory.symptomCheck;
    if (!isCategoryEnabled(category)) return;

    await addLocalNotification(
      title: isUrgent
          ? '🚨 URGENT: Doctor Se Milein!'
          : '🩺 Symptom Check-In',
      body: isUrgent
          ? 'Aapke symptoms serious hain. Abhi doctor ko call karein ya hospital jaayein. Emergency: 108'
          : 'Aapke symptoms log kiye gaye. AI analysis ready hai – ek nazar dalein.',
      category: category,
      route: '/symptoms',
      data: {'risk_level': riskLevel, 'summary': symptomSummary},
      actionButton1Label: isUrgent ? 'Call 108' : 'Analysis Dekho',
      actionButton1Route: '/symptoms',
    );
  }

  /// Daily nutrition tip
  Future<void> triggerNutritionTip({
    required int pregnancyWeek,
    required String tipTitle,
    required String tipBody,
  }) async {
    if (!isCategoryEnabled(NotificationCategory.nutrition)) return;
    if (_quietHours.isCurrentlyQuiet) return;

    await addLocalNotification(
      title: '🥗 $tipTitle',
      body: tipBody,
      category: NotificationCategory.nutrition,
      route: '/nutrition',
      data: {'week': pregnancyWeek},
      actionButton1Label: 'Recipe Dekho',
      actionButton1Route: '/nutrition',
    );
  }

  /// Yoga & self-care reminder
  Future<void> triggerSelfCareReminder({
    required String sessionTitle,
    required String sessionDescription,
    required int pregnancyWeek,
  }) async {
    if (!isCategoryEnabled(NotificationCategory.selfCare)) return;
    if (_quietHours.isCurrentlyQuiet) return;

    await addLocalNotification(
      title: '🧘 $sessionTitle',
      body: sessionDescription,
      category: NotificationCategory.selfCare,
      route: '/self-care',
      data: {'week': pregnancyWeek},
      actionButton1Label: 'Session Shuru Karo',
      actionButton1Route: '/self-care',
    );
  }

  /// Friend request received
  Future<void> triggerFriendRequest({
    required String fromUserId,
    required String fromName,
    required String fromAvatarUrl,
    required int fromPregnancyWeek,
  }) async {
    if (!isCategoryEnabled(NotificationCategory.friendRequest)) return;

    await addLocalNotification(
      title: '🤝 Friend Request Aaya!',
      body: '$fromName (Week $fromPregnancyWeek ki Mama) ne connect karna chahti hai! Accept karo?',
      category: NotificationCategory.friendRequest,
      route: '/community',
      data: {
        'from_user_id': fromUserId,
        'from_name': fromName,
        'from_avatar': fromAvatarUrl,
        'from_week': fromPregnancyWeek,
      },
      actionButton1Label: 'Accept Karo ✅',
      actionButton2Label: 'Decline',
    );
  }

  /// Community post reply / new post
  Future<void> triggerCommunityNotification({
    required String type, // 'reply', 'new_post', 'like', 'achievement'
    required String postId,
    required String fromName,
    String? postPreview,
  }) async {
    if (!isCategoryEnabled(NotificationCategory.community)) return;
    if (_quietHours.isCurrentlyQuiet) return;

    String title, body;
    switch (type) {
      case 'reply':
        title = '💬 Aapke Post Pe Reply Aaya!';
        body = '$fromName ne reply kiya: "${postPreview ?? ''}"';
        break;
      case 'like':
        title = '❤️ Kisi Ko Aapka Post Pasand Aaya!';
        body = '$fromName ne aapka post like kiya. Community mein check karo!';
        break;
      case 'achievement':
        title = '🏆 Achievement Unlock!';
        body = postPreview ?? 'Badhaaiyan! Ek naya badge mila hai!';
        break;
      default:
        title = '👥 Parents Park Mein Kuch Naya!';
        body = '$fromName ne kuch share kiya hai. Dekho!';
    }

    await addLocalNotification(
      title: title,
      body: body,
      category: NotificationCategory.community,
      route: '/community',
      data: {'post_id': postId, 'type': type, 'from': fromName},
      actionButton1Label: 'Dekho',
      actionButton1Route: '/community',
    );
  }

  /// Health insights alert
  Future<void> triggerHealthInsight({
    required String insightType, // 'weight', 'bmi', 'risk', 'weekly_report'
    required String message,
    bool isUrgent = false,
  }) async {
    if (!isCategoryEnabled(NotificationCategory.healthInsights)) return;

    await addLocalNotification(
      title: isUrgent ? '🔴 Health Alert!' : '📊 Health Insight Ready!',
      body: message,
      category: NotificationCategory.healthInsights,
      route: '/health-insights',
      data: {'insight_type': insightType},
      actionButton1Label: 'Report Dekho',
    );
  }

  /// Tracker sync reminder
  Future<void> triggerTrackerSyncReminder({int daysSinceLastUpdate = 2}) async {
    if (!isCategoryEnabled(NotificationCategory.trackerSync)) return;
    if (_quietHours.isCurrentlyQuiet) return;

    await addLocalNotification(
      title: '📈 Tracker Update Karo!',
      body: '$daysSinceLastUpdate din ho gaye update kiye bina. Aapki progress track karte rehna zaroori hai Mama 💕',
      category: NotificationCategory.trackerSync,
      route: '/tracker',
      actionButton1Label: 'Abhi Update Karo',
    );
  }

  /// Safety / critical alert (highest priority)
  Future<void> triggerSafetyAlert({
    required String alertType, // 'security', 'critical_health', 'emergency'
    required String message,
  }) async {
    // Safety alerts ignore quiet hours and category settings
    await addLocalNotification(
      title: '🚨 Important Alert – MaaCare',
      body: message,
      category: NotificationCategory.safetyAlert,
      route: '/symptoms',
      data: {'alert_type': alertType},
      actionButton1Label: alertType == 'security' ? 'Settings Dekho' : 'Call 108',
    );
  }

  // ============================================================
  //  Backend API – Send via InsForge Edge Function
  // ============================================================

  /// Send push notification via InsForge edge function to one/many users
  Future<bool> sendPushViaBackend({
    required List<String> playerIds,
    required String title,
    required String body,
    required String type,
    String? route,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? action1Label,
    String? action1Route,
  }) async {
    try {
      final url = Uri.parse(
          '${AppConstants.backendUrl}/functions/send-notification');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apikey': AppConstants.backendAnonKey,
        },
        body: jsonEncode({
          'player_ids': playerIds,
          'title': title,
          'body': body,
          'type': type,
          'route': route,
          'data': data,
          'image_url': imageUrl,
          'action1_label': action1Label,
          'action1_route': action1Route,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('PUSH_NOTIFICATION: Backend send error: $e');
      return false;
    }
  }

  /// Send FCM push notification via InsForge edge function
  Future<bool> sendFcmPushViaBackend({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final url = Uri.parse(
          '${AppConstants.backendUrl}/functions/send_push_notification');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apikey': AppConstants.backendAnonKey,
        },
        body: jsonEncode({
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('PUSH_NOTIFICATION: FCM Backend send error: $e');
      return false;
    }
  }

  // ============================================================
  //  Rate Limiting – prevent notification spam
  // ============================================================

  /// Track last notification times per category
  Future<bool> canSendCategory(NotificationCategory category,
      {Duration minInterval = const Duration(hours: 12)}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'last_notif_${category.key}';
    final lastStr = prefs.getString(key);
    if (lastStr != null) {
      final last = DateTime.parse(lastStr);
      if (DateTime.now().difference(last) < minInterval) {
        debugPrint(
            'PUSH_NOTIFICATION: Rate limited – ${category.key}');
        return false;
      }
    }
    await prefs.setString(key, DateTime.now().toIso8601String());
    return true;
  }

  // ============================================================
  //  Content Generators – Hinglish + Hindi warm tone
  // ============================================================

  Map<String, String> _getPregnancyMilestoneContent(
      int week, String userName) {
    final firstName = userName.split(' ').first;
    switch (week) {
      case 4:
        return {
          'title': '🌱 Week 4 – Safar Shuru!',
          'body': 'Badhaaiyan $firstName! Aapki pregnancy confirm hui. Pehla appointment book karein 💕',
        };
      case 8:
        return {
          'title': '🫐 Week 8 – Baby Ka Dil Dhak Dhak!',
          'body': 'Baby ki heartbeat sunai de sakti hai ab! Yeh magical moment miss mat karna 💗',
        };
      case 12:
        return {
          'title': '🍋 Week 12 – Pehla Trimester Complete!',
          'body': 'Shaabaash $firstName! Baby ke fingers aur toes ban gaye. NT scan schedule karein 🌟',
        };
      case 16:
        return {
          'title': '🥑 Week 16 – Baby Hil Raha Hai!',
          'body': 'Shayad aapko pehli kicks mehsoos hon ab! Yeh flutter – aapka baby hai 💝',
        };
      case 20:
        return {
          'title': '🍌 Week 20 – Aadha Safar Poora!',
          'body': 'Anatomy scan ka waqt aa gaya! Baby ab banana jitna bada hai 🎉',
        };
      case 24:
        return {
          'title': '🌽 Week 24 – Baby Sun Sakta Hai!',
          'body': 'Baby ab awaazein sun sakta hai. Usse lori sunao, kahaniyan sunao 🎵',
        };
      case 28:
        return {
          'title': '🍆 Week 28 – Teesra Trimester!',
          'body': 'Badhaayi $firstName! Teesra trimester shuru. Hospital bag ki list tayaar karo 🏥',
        };
      case 32:
        return {
          'title': '🥥 Week 32 – Baby Ulta Ho Raha Hai!',
          'body': 'Baby delivery ke liye position le raha hai. Breathing exercises shuru karo 🧘',
        };
      case 36:
        return {
          'title': '🍈 Week 36 – Almost There!',
          'body': 'Sirf 4 hafte baaki! Hospital bag pack kiya? Birth plan discuss kiya doctor se? 💪',
        };
      case 40:
        return {
          'title': '🍉 Week 40 – Due Date Aa Gaya!',
          'body': '$firstName, aap itni brave ho! Doctor ke saath connected raho. Hamari duaye hain 💕',
        };
      default:
        return {
          'title': '🤰 Week $week Milestone!',
          'body': 'Aapka baby is hafte naya vikas kar raha hai. Tracker mein details dekho 💗',
        };
    }
  }

  Map<String, String> _getChildGrowthContent(int months, String childName) {
    final name = childName.isEmpty ? 'Baby' : childName;
    if (months == 1) {
      return {
        'title': '🎂 $name Ka Ek Mahina!',
        'body': 'Pehla mahina! $name ab chehra track karne laga hai. Pediatrician visit schedule karein',
      };
    } else if (months == 2) {
      return {
        'title': '😊 2 Maheene – Pehli Muskaan!',
        'body': '$name abhi social smile dene laga hai! Yeh moment camera mein capture karo 📸',
      };
    } else if (months == 6) {
      return {
        'title': '🥣 6 Maheene – Solid Foods Time!',
        'body': '$name ab solid foods ke liye ready hai! Pehle try karein: rice cereal ya banana 🍌',
      };
    } else if (months == 12) {
      return {
        'title': '🎂 Happy Birthday Little One!',
        'body': '$name ka pehla birthday! Pehle kadam aur pehli baat ka wait karo 🎉',
      };
    } else if (months == 24) {
      return {
        'title': '🗣️ 2 Saal – Baat Karne Ka Time!',
        'body': '$name ab 50+ words bol sakta hai! Language development ke tips dekho 💬',
      };
    } else if (months == 36) {
      return {
        'title': '🎒 3 Saal – Preschool Ready!',
        'body': '$name preschool ke liye ready ho raha hai! Readiness checklist dekho 📚',
      };
    }
    return {
      'title': '👶 $name Ka ${months < 24 ? "$months Mahina" : "${months ~/ 12} Saal"} Milestone!',
      'body': 'Aaj ek khaas din hai! $name ka growth chart update karo aur doctor se milein 💕',
    };
  }

  Map<String, String> _getDoctorConsultContent(
      String doctorName, DateTime time, String type) {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    switch (type) {
      case '48h':
        return {
          'title': '📅 Kal Consultation Hai – Yaad Rakhna!',
          'body': 'Dr. $doctorName ke saath kal $timeStr baje appointment hai. Questions tayaar karo 📋',
        };
      case '24h':
        return {
          'title': '⏰ Kal Subah Appointment!',
          'body': 'Dr. $doctorName – kal $timeStr baje. Symptom list ready hai? 💙',
        };
      case '15min':
        return {
          'title': '🚀 15 Min Mein Consult Shuru!',
          'body': 'Dr. $doctorName aapka intezaar kar rahe hain! Abhi join karo 👩‍⚕️',
        };
      case 'post':
        return {
          'title': '✅ Consultation Complete!',
          'body': 'Dr. $doctorName ki appointment khatam hui. Summary aur prescription dekho 📄',
        };
      default:
        return {
          'title': '👩‍⚕️ Doctor Appointment Reminder',
          'body': 'Dr. $doctorName ke saath $timeStr baje appointment hai 💙',
        };
    }
  }

  Map<String, String> _getVaccinationContent(
      String vaccineName, DateTime dueDate, String type) {
    switch (type) {
      case '7d':
        return {
          'title': '💉 $vaccineName – 7 Din Mein Due!',
          'body': 'Baby ki $vaccineName vaccine 7 din baad due hai. Nearest center book karein 🏥',
        };
      case '1d':
        return {
          'title': '⚠️ $vaccineName – Kal Due Hai!',
          'body': 'Kal baby ki $vaccineName vaccine hai! Center ki location confirm karo 📍',
        };
      case 'today':
        return {
          'title': '🔴 $vaccineName – Aaj Due!',
          'body': 'Baby ki $vaccineName vaccine aaj hai! Vaccinations screen se center dekho 🏥',
        };
      case 'overdue':
        return {
          'title': '❗ $vaccineName – Overdue!',
          'body': '$vaccineName pending hai! Baby ki immunity ke liye aaj hi schedule karein ⚠️',
        };
      default:
        return {
          'title': '💉 Vaccination Reminder',
          'body': 'Baby ki $vaccineName vaccine due hai. Abhi schedule karein!',
        };
    }
  }

  // ============================================================
  //  Cleanup
  // ============================================================
  void dispose() {
    _notificationController.close();
    _badgeCountController.close();
    _permissionController.close();
  }
}

// ============================================================
//  Deep Link Helper – All 14 categories mapped
// ============================================================
class NotificationDeepLinkHelper {
  static const Map<String, String> notificationRoutes = {
    'pregnancy_milestone': '/tracker',
    'child_growth': '/child-growth',
    'vaccination': '/vaccinations',
    'doctor_consult': '/consult',
    'symptom_check': '/symptoms',
    'health_insights': '/health-insights',
    'safety_alert': '/symptoms',
    'nutrition': '/nutrition',
    'self_care': '/self-care',
    'tracker_sync': '/tracker',
    'community': '/community',
    'friend_request': '/community',
    'health_news': '/nutrition',
    'general': '/home',
  };

  static String getRouteForType(String type) =>
      notificationRoutes[type] ?? '/home';

  static String? getRouteFromPayload(NotificationPayload payload) {
    return payload.route ?? notificationRoutes[payload.type];
  }

  static void navigateFromNotification(
    BuildContext context,
    NotificationPayload payload,
  ) {
    final route = getRouteFromPayload(payload);
    if (route != null) {
      Navigator.of(context).pushNamed(route, arguments: payload.data);
    }
  }
}
