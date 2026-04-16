// ============================================================
//  AutoSyncService – MaaCare 24/7 Automation
//  Background sync, auto-refresh, notifications, data sync
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/user_provider.dart';
import '../providers/community_provider.dart';
import '../services/notification_service.dart';

class AutoSyncService {
  AutoSyncService._();
  static final AutoSyncService instance = AutoSyncService._();

  Timer? _syncTimer;
  Timer? _refreshTimer;
  bool _isInitialized = false;
  
  // Sync intervals
  static const Duration _syncInterval = Duration(minutes: 2);
  static const Duration _refreshInterval = Duration(seconds: 30);

  // Providers
  UserProvider? _userProvider;
  CommunityProvider? _communityProvider;

  // Stream controllers for sync events
  final _syncController = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get syncEvents => _syncController.stream;

  bool get isInitialized => _isInitialized;

  // ─────────────────── Initialization ───────────────────

  Future<void> initialize({
    UserProvider? userProvider,
    CommunityProvider? communityProvider,
  }) async {
    if (_isInitialized) return;

    debugPrint('AUTOSYNC_DEBUG: Initializing auto-sync service...');
    
    _userProvider = userProvider;
    _communityProvider = communityProvider;

    // Start periodic sync
    _startAutoSync();
    _startAutoRefresh();

    _isInitialized = true;
    debugPrint('AUTOSYNC_DEBUG: Auto-sync service initialized');
  }

  // ─────────────────── Auto Sync ───────────────────

  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) async {
      await _performSync();
    });
    debugPrint('AUTOSYNC_DEBUG: Auto-sync started (interval: ${_syncInterval.inMinutes}min)');
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      await _performRefresh();
    });
    debugPrint('AUTOSYNC_DEBUG: Auto-refresh started (interval: ${_refreshInterval.inSeconds}sec)');
  }

  Future<void> _performSync() async {
    debugPrint('AUTOSYNC_DEBUG: Performing auto-sync...');
    
    try {
      // Sync user data
      if (_userProvider != null) {
        await _userProvider!.loadUser();
      }

      // Sync community posts
      if (_communityProvider != null && !_communityProvider!.isLoading) {
        await _communityProvider!.fetchPosts();
      }

      _syncController.add(SyncEvent(type: SyncEventType.syncCompleted));
      debugPrint('AUTOSYNC_DEBUG: Auto-sync completed');
    } catch (e) {
      debugPrint('AUTOSYNC_DEBUG: Auto-sync error: $e');
      _syncController.add(SyncEvent(type: SyncEventType.syncError, error: e.toString()));
    }
  }

  Future<void> _performRefresh() async {
    try {
      // Quick refresh of posts (if not currently loading)
      if (_communityProvider != null && !_communityProvider!.isLoading) {
        await _communityProvider!.fetchPosts(limit: 10);
      }

      _syncController.add(SyncEvent(type: SyncEventType.refreshCompleted));
    } catch (e) {
      debugPrint('AUTOSYNC_DEBUG: Auto-refresh error: $e');
    }
  }

  // ─────────────────── Manual Sync ───────────────────

  Future<void> syncAll() async {
    debugPrint('AUTOSYNC_DEBUG: Manual sync triggered');
    await _performSync();
  }

  Future<void> refreshData() async {
    debugPrint('AUTOSYNC_DEBUG: Manual refresh triggered');
    await _performRefresh();
  }

  // ─────────────────── Background Sync ───────────────────

  Future<void> enableBackgroundSync() async {
    debugPrint('AUTOSYNC_DEBUG: Enabling background sync...');
    
    // Schedule daily notifications
    await NotificationService.instance.scheduleDailyMoodCheck();
    
    // Additional background tasks can be added here
    debugPrint('AUTOSYNC_DEBUG: Background sync enabled');
  }

  // ─────────────────── Smart Sync ───────────────────

  Future<void> smartSync() async {
    debugPrint('AUTOSYNC_DEBUG: Smart sync triggered');
    
    // Only sync if needed based on last sync time
    await _performSync();
  }

  // ─────────────────── Cleanup ───────────────────

  void dispose() {
    _syncTimer?.cancel();
    _refreshTimer?.cancel();
    _syncController.close();
    _isInitialized = false;
    debugPrint('AUTOSYNC_DEBUG: Auto-sync service disposed');
  }

  void pause() {
    _syncTimer?.cancel();
    _refreshTimer?.cancel();
    debugPrint('AUTOSYNC_DEBUG: Auto-sync paused');
  }

  void resume() {
    if (_isInitialized) {
      _startAutoSync();
      _startAutoRefresh();
      debugPrint('AUTOSYNC_DEBUG: Auto-sync resumed');
    }
  }
}

// ─────────────────── Sync Event Classes ───────────────────

enum SyncEventType {
  syncCompleted,
  syncError,
  refreshCompleted,
  dataUpdated,
}

class SyncEvent {
  final SyncEventType type;
  final String? error;
  final DateTime timestamp;

  SyncEvent({
    required this.type,
    this.error,
  }) : timestamp = DateTime.now();
}
