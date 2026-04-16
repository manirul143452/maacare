// ============================================================
//  PushNotificationService – MaaCare OneSignal Integration
//  Complete push notification system with InsForge backend
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'secure_storage_service.dart';

// OneSignal App ID - Replace with your actual OneSignal App ID
// Get this from OneSignal Dashboard: https://app.onesignal.com
const String kOneSignalAppId = 'YOUR_ONESIGNAL_APP_ID_HERE';

// Notification Categories for user preferences
enum NotificationCategory {
  vaccination('vaccination', 'Vaccination Reminders', '💉'),
  nutrition('nutrition', 'Daily Nutrition Tips', '🥗'),
  selfCare('self_care', 'Self-Care Suggestions', '🧘'),
  symptomCheck('symptom_check', 'Symptom Check Reminders', '🩺'),
  pregnancyMilestone('pregnancy_milestone', 'Pregnancy Milestones', '🤰'),
  community('community', 'Parents Park Updates', '💬'),
  healthNews('health_news', 'Health News & Articles', '📰'),
  trackerSync('tracker_sync', 'Tracker Sync Reminders', '📊'),
  general('general', 'General Updates', '🔔');

  final String key;
  final String label;
  final String emoji;
  
  const NotificationCategory(this.key, this.label, this.emoji);
}

// Notification payload for deep linking
class NotificationPayload {
  final String type;
  final String? route;
  final Map<String, dynamic>? data;
  final String? title;
  final String? body;

  NotificationPayload({
    required this.type,
    this.route,
    this.data,
    this.title,
    this.body,
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPayload(
      type: map['type'] ?? 'general',
      route: map['route'],
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      title: map['title'],
      body: map['body'],
    );
  }
}

// Notification item for notification center
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
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      imageUrl: json['imageUrl'],
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
    );
  }
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  // Streams
  final _notificationController = StreamController<NotificationPayload>.broadcast();
  final _badgeCountController = StreamController<int>.broadcast();
  final _permissionController = StreamController<bool>.broadcast();

  Stream<NotificationPayload> get onNotificationReceived => _notificationController.stream;
  Stream<int> get onBadgeCountChanged => _badgeCountController.stream;
  Stream<bool> get onPermissionChanged => _permissionController.stream;

  // State
  String? _playerId;
  String? _subscriptionId;
  bool _isInitialized = false;
  int _unreadCount = 0;
  List<NotificationItem> _notifications = [];
  Map<String, bool> _categorySettings = {};

  // Getters
  String? get playerId => _playerId;
  String? get subscriptionId => _subscriptionId;
  bool get isInitialized => _isInitialized;
  int get unreadCount => _unreadCount;
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  // ============================================================
  //  Initialization
  // ============================================================

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      debugPrint('PUSH_NOTIFICATION: Web platform - OneSignal not initialized');
      return;
    }

    debugPrint('PUSH_NOTIFICATION: Initializing OneSignal...');

    // Set log level for debugging (remove in production)
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize OneSignal
    OneSignal.initialize(kOneSignalAppId);

    // Request permission with fallbackToSettings
    await OneSignal.Notifications.requestPermission(true);

    // Set up notification handlers
    _setupNotificationHandlers();

    // Get Player ID
    await _getPlayerId();

    // Load saved notifications and settings
    await _loadNotifications();
    await _loadCategorySettings();

    // Listen for permission changes
    OneSignal.Notifications.addPermissionObserver((state) {
      _permissionController.add(state);
      debugPrint('PUSH_NOTIFICATION: Permission changed: $state');
    });

    // Listen for subscription changes
    OneSignal.User.addObserver((state) {
      debugPrint('PUSH_NOTIFICATION: User state changed');
      _getPlayerId();
    });

    _isInitialized = true;
    debugPrint('PUSH_NOTIFICATION: OneSignal initialized successfully');
    debugPrint('PUSH_NOTIFICATION: Player ID: $_playerId');
  }

  void _setupNotificationHandlers() {
    // Foreground notification received
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('PUSH_NOTIFICATION: Foreground notification received');
      
      final payload = _extractPayload(event.notification);
      _notificationController.add(payload);
      
      // Add to notification center
      _addNotificationFromPayload(payload);
      
      // Update badge count
      _updateBadgeCount();
      
      // Show local notification if enabled for this category
      if (_isCategoryEnabled(payload.type)) {
        event.notification.display();
      }
    });

    // Notification opened (background or terminated)
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('PUSH_NOTIFICATION: Notification clicked');
      
      final payload = _extractPayload(event.notification);
      _notificationController.add(payload);
      
      // Mark as read
      _markNotificationRead(payload.type);
    });

    // In-app message clicked
    OneSignal.InAppMessages.addClickListener((event) {
      debugPrint('PUSH_NOTIFICATION: In-app message clicked');
    });
  }

  NotificationPayload _extractPayload(OSNotification notification) {
    final additionalData = notification.additionalData ?? {};
    
    return NotificationPayload(
      type: additionalData['type'] ?? 'general',
      route: additionalData['route'],
      data: additionalData['data'] != null 
          ? Map<String, dynamic>.from(additionalData['data']) 
          : null,
      title: notification.title,
      body: notification.body,
    );
  }

  // ============================================================
  //  Player ID & Backend Sync
  // ============================================================

  Future<void> _getPlayerId() async {
    try {
      _playerId = OneSignal.User.pushSubscription.id;
      _subscriptionId = OneSignal.User.pushSubscription.token;
      
      debugPrint('PUSH_NOTIFICATION: Player ID: $_playerId');
      debugPrint('PUSH_NOTIFICATION: Token: $_subscriptionId');
      
      // Store in backend if user is logged in
      await _syncPlayerIdToBackend();
    } catch (e) {
      debugPrint('PUSH_NOTIFICATION: Error getting Player ID: $e');
    }
  }

  /// Sync Player ID to InsForge backend
  /// Call this after user login
  Future<void> syncPlayerIdToBackend(String userId) async {
    if (_playerId == null) {
      debugPrint('PUSH_NOTIFICATION: No Player ID available');
      return;
    }

    try {
      debugPrint('PUSH_NOTIFICATION: Syncing Player ID to InsForge...');
      
      // Store in SecureStorage for persistence
      await SecureStorageService.instance.write('onesignal_player_id', _playerId!);

      // Send to InsForge backend
      // Using the user profile endpoint to update push token
      final url = Uri.parse(
        '${AppConstants.insForgeUrl}/api/database/records/users/$userId',
      );

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apikey': AppConstants.insForgeAnonKey,
        },
        body: jsonEncode({
          'onesignal_player_id': _playerId,
          'push_token_updated_at': DateTime.now().toIso8601String(),
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('PUSH_NOTIFICATION: Player ID synced to InsForge successfully');
      } else {
        debugPrint('PUSH_NOTIFICATION: Failed to sync Player ID: ${response.statusCode}');
        debugPrint('PUSH_NOTIFICATION: Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('PUSH_NOTIFICATION: Error syncing Player ID: $e');
    }
  }

  Future<void> _syncPlayerIdToBackend() async {
    // Get current user ID from secure storage
    final userId = await SecureStorageService.instance.read('user_id');
    if (userId != null) {
      await syncPlayerIdToBackend(userId);
    }
  }

  // ============================================================
  //  Notification Center
  // ============================================================

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      
      _notifications = notificationsJson
          .map((json) => NotificationItem.fromJson(jsonDecode(json)))
          .toList();
      
      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _updateBadgeCount();
      debugPrint('PUSH_NOTIFICATION: Loaded ${_notifications.length} notifications');
    } catch (e) {
      debugPrint('PUSH_NOTIFICATION: Error loading notifications: $e');
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((n) => jsonEncode(n.toJson()))
          .toList();
      
      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      debugPrint('PUSH_NOTIFICATION: Error saving notifications: $e');
    }
  }

  void _addNotificationFromPayload(NotificationPayload payload) {
    final category = NotificationCategory.values.firstWhere(
      (c) => c.key == payload.type,
      orElse: () => NotificationCategory.general,
    );

    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: payload.title ?? 'MaaCare',
      body: payload.body ?? '',
      category: category,
      timestamp: DateTime.now(),
      route: payload.route,
      data: payload.data,
    );

    _notifications.insert(0, notification);
    
    // Keep only last 100 notifications
    if (_notifications.length > 100) {
      _notifications = _notifications.sublist(0, 100);
    }
    
    _saveNotifications();
  }

  void _updateBadgeCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    _badgeCountController.add(_unreadCount);
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      _updateBadgeCount();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
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

  void _markNotificationRead(String type) {
    // Find most recent notification of this type and mark as read
    final index = _notifications.indexWhere((n) => n.category.key == type && !n.isRead);
    if (index != -1) {
      markAsRead(_notifications[index].id);
    }
  }

  // ============================================================
  //  Category Settings
  // ============================================================

  Future<void> _loadCategorySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('notification_settings');
      
      if (settingsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(settingsJson);
        _categorySettings = Map<String, bool>.from(decoded);
      } else {
        // Default: all enabled
        for (final category in NotificationCategory.values) {
          _categorySettings[category.key] = true;
        }
      }
    } catch (e) {
      debugPrint('PUSH_NOTIFICATION: Error loading settings: $e');
      // Default: all enabled
      for (final category in NotificationCategory.values) {
        _categorySettings[category.key] = true;
      }
    }
  }

  Future<void> _saveCategorySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_settings', jsonEncode(_categorySettings));
    } catch (e) {
      debugPrint('PUSH_NOTIFICATION: Error saving settings: $e');
    }
  }

  bool isCategoryEnabled(NotificationCategory category) {
    return _categorySettings[category.key] ?? true;
  }

  bool _isCategoryEnabled(String categoryKey) {
    return _categorySettings[categoryKey] ?? true;
  }

  Future<void> setCategoryEnabled(NotificationCategory category, bool enabled) async {
    _categorySettings[category.key] = enabled;
    await _saveCategorySettings();
    
    // Update OneSignal tags for backend filtering
    await OneSignal.User.addTagWithKey(category.key, enabled ? 'enabled' : 'disabled');
    
    debugPrint('PUSH_NOTIFICATION: Category ${category.key} set to $enabled');
  }

  Map<NotificationCategory, bool> getAllCategorySettings() {
    return {
      for (final category in NotificationCategory.values)
        category: _categorySettings[category.key] ?? true,
    };
  }

  // ============================================================
  //  Permission Management
  // ============================================================

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    
    final granted = await OneSignal.Notifications.requestPermission(true);
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
  //  Local Scheduling (kept from existing NotificationService)
  // ============================================================

  // Note: Local notifications are handled separately by NotificationService
  // This class focuses on remote push notifications via OneSignal

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
//  Deep Link Helper
// ============================================================

class NotificationDeepLinkHelper {
  /// Get the route from notification payload
  static String? getRouteFromPayload(NotificationPayload payload) {
    return payload.route;
  }

  /// Build full route with arguments
  static String buildRoute(String? baseRoute, Map<String, dynamic>? data) {
    if (baseRoute == null) return '/home';
    if (data == null || data.isEmpty) return baseRoute;
    
    // Build query parameters
    final params = data.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    
    return params.isNotEmpty ? '$baseRoute?$params' : baseRoute;
  }

  /// Navigate to screen from notification
  static void navigateFromNotification(
    BuildContext context, 
    NotificationPayload payload,
  ) {
    final route = getRouteFromPayload(payload);
    if (route != null) {
      Navigator.of(context).pushNamed(route, arguments: payload.data);
    }
  }

  // Route mappings for notification types
  static const Map<String, String> notificationRoutes = {
    'vaccination': '/vaccinations',
    'nutrition': '/nutrition',
    'self_care': '/selfcare',
    'symptom_check': '/symptoms',
    'pregnancy_milestone': '/tracker',
    'community': '/community',
    'health_news': '/nutrition',
    'tracker_sync': '/tracker',
    'general': '/home',
  };

  static String getRouteForType(String type) {
    return notificationRoutes[type] ?? '/home';
  }
}

// ============================================================
//  Backend API Helper for InsForge
// ============================================================

/// These are the InsForge serverless function endpoints that should be implemented
/// on the backend to send push notifications

/*

INSFORGE BACKEND ENDPOINTS FOR PUSH NOTIFICATIONS:

1. POST /api/functions/send-notification
   Send notification to specific user
   {
     "player_id": "xxx",
     "title": "Vaccination Due",
     "body": "Your baby's DTP vaccine is due today",
     "type": "vaccination",
     "route": "/vaccinations",
     "data": { "vaccine_id": "dtp", "due_date": "2025-01-15" }
   }

2. POST /api/functions/broadcast-notification
   Send to all users matching criteria
   {
     "title": "New Article",
     "body": "Check out our new nutrition guide",
     "type": "health_news",
     "filters": { "category": "nutrition" }
   }

3. POST /api/functions/schedule-vaccination-reminders
   Auto-schedule reminders based on baby age
   {
     "user_id": "xxx",
     "baby_birth_date": "2024-06-01",
     "upcoming_vaccines": [...]
   }

4. POST /api/functions/daily-tips-cron
   Daily scheduled tips based on pregnancy week
   {
     "week": 24,
     "tip_type": "nutrition"
   }

5. POST /api/functions/community-activity
   Notify on new posts/replies in Parents Park
   {
     "post_id": "xxx",
     "author_id": "xxx",
     "action": "reply",
     "recipient_player_ids": ["xxx", "yyy"]
   }

6. GET /api/database/records/users?onesignal_player_id=not.null
   Get all users with push tokens for batch sending

*/
