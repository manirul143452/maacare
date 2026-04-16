// ============================================================
//  Notification Center – MaaCare Premium
//  Beautiful in-app notification center with OneSignal integration
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../services/push_notification_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = PushNotificationService.instance.notifications;
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(String id) async {
    await PushNotificationService.instance.markAsRead(id);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await PushNotificationService.instance.markAllAsRead();
    _loadNotifications();
  }

  Future<void> _deleteNotification(String id) async {
    await PushNotificationService.instance.deleteNotification(id);
    _loadNotifications();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MaaColors.cardDark,
        title: Text(
          'Clear All Notifications?',
          style: GoogleFonts.poppins(color: MaaColors.textPrimary),
        ),
        content: Text(
          'This will delete all your notifications permanently.',
          style: GoogleFonts.poppins(color: MaaColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: MaaColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: GoogleFonts.poppins(color: MaaColors.pink)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PushNotificationService.instance.clearAllNotifications();
      _loadNotifications();
    }
  }

  void _onNotificationTap(NotificationItem notification) {
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    if (notification.route != null) {
      Navigator.pushNamed(context, notification.route!, arguments: notification.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: MaaColors.cardDark,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Notifications',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: MaaColors.textPrimary,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MaaColors.pink.withAlpha(60),
                      MaaColors.softPurple.withAlpha(40),
                      MaaColors.cardDark,
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MaaColors.glassBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: MaaColors.textPrimary, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_notifications.isNotEmpty) ...[
                // Mark all as read
                if (unreadCount > 0)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MaaColors.success.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.done_all_rounded,
                          color: MaaColors.success, size: 20),
                    ),
                    onPressed: _markAllAsRead,
                    tooltip: 'Mark all as read',
                  ),
                // Clear all
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MaaColors.warning.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: MaaColors.warning, size: 20),
                  ),
                  onPressed: _clearAll,
                  tooltip: 'Clear all',
                ),
              ],
              // Settings
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MaaColors.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_rounded,
                      color: MaaColors.textPrimary, size: 20),
                ),
                onPressed: () => Navigator.pushNamed(context, '/notification-settings'),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Stats Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildStatCard(
                    'Total',
                    _notifications.length.toString(),
                    Icons.notifications_rounded,
                    MaaColors.pink,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Unread',
                    unreadCount.toString(),
                    Icons.mark_email_unread_rounded,
                    MaaColors.warning,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Read',
                    (_notifications.length - unreadCount).toString(),
                    Icons.mark_email_read_rounded,
                    MaaColors.success,
                  ),
                ],
              ),
            ),
          ),

          // Notifications List
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _notifications.isEmpty
                  ? SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final notification = _notifications[index];
                            return _buildNotificationCard(notification, index);
                          },
                          childCount: _notifications.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withAlpha(30), color.withAlpha(15)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: MaaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, int index) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: MaaColors.warning.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: MaaColors.warning),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: GestureDetector(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? MaaColors.cardDark
                : MaaColors.pink.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: notification.isRead
                  ? MaaColors.glassBorder
                  : MaaColors.pink.withAlpha(50),
            ),
            boxShadow: notification.isRead
                ? null
                : [
                    BoxShadow(
                      color: MaaColors.pink.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and time
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(notification.category).withAlpha(100),
                            _getCategoryColor(notification.category).withAlpha(50),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notification.category.emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.category.label,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getCategoryColor(notification.category),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: MaaColors.pink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(notification.timestamp),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: MaaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: MaaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: MaaColors.textSecondary,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MaaColors.pink.withAlpha(30),
                  MaaColors.softPurple.withAlpha(20),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔔', style: TextStyle(fontSize: 50)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: MaaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stay tuned for vaccination reminders,\ndaily tips, and community updates!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: MaaColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/notification-settings'),
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Notification Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MaaColors.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.vaccination:
        return MaaColors.pink;
      case NotificationCategory.nutrition:
        return MaaColors.success;
      case NotificationCategory.selfCare:
        return MaaColors.softPurple;
      case NotificationCategory.symptomCheck:
        return MaaColors.warning;
      case NotificationCategory.pregnancyMilestone:
        return MaaColors.lightBlue;
      case NotificationCategory.community:
        return MaaColors.softGreen;
      case NotificationCategory.healthNews:
        return MaaColors.peach;
      case NotificationCategory.trackerSync:
        return MaaColors.gold;
      case NotificationCategory.general:
        return MaaColors.textPrimary;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
