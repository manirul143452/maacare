// ============================================================
//  Notification Center – MaaCare v2.0
//  Category filter chips • Action buttons • Swipe gestures
//  Supports all 14 notification categories
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../services/push_notification_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<NotificationItem> _notifications = [];
  List<NotificationItem> _filtered = [];
  bool _isLoading = true;
  NotificationCategory? _activeFilter; // null = All

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    // Listen for new notifications in real time
    PushNotificationService.instance.onNotificationReceived.listen((_) {
      if (mounted) _loadNotifications();
    });
  }

  void _loadNotifications() {
    final all = PushNotificationService.instance.notifications;
    setState(() {
      _notifications = all;
      _applyFilter(_activeFilter);
      _isLoading = false;
    });
  }

  void _applyFilter(NotificationCategory? category) {
    _activeFilter = category;
    _filtered = category == null
        ? List.from(_notifications)
        : _notifications.where((n) => n.category == category).toList();
  }

  Future<void> _markAsRead(String id) async {
    await PushNotificationService.instance.markAsRead(id);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await PushNotificationService.instance.markAllAsRead();
    _loadNotifications();
  }

  Future<void> _delete(String id) async {
    await PushNotificationService.instance.deleteNotification(id);
    _loadNotifications();
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MaaColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sab Clear Karein?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: MaaColors.textPrimary)),
        content: Text(
          'Saari notifications permanently delete ho jaayengi.',
          style: GoogleFonts.poppins(color: MaaColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: MaaColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MaaColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Clear',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await PushNotificationService.instance.clearAllNotifications();
      _loadNotifications();
    }
  }

  void _onTap(NotificationItem n) {
    if (!n.isRead) _markAsRead(n.id);
    if (n.route != null) {
      Navigator.pushNamed(context, n.route!, arguments: n.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: MaaColors.cardDark,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: MaaColors.textPrimary),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: MaaColors.pink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unread',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ],
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
                if (unread > 0)
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
                onPressed: () =>
                    Navigator.pushNamed(context, '/notification-settings'),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Stats Row ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                _buildStat('Total', _notifications.length,
                    Icons.notifications_rounded, MaaColors.pink),
                const SizedBox(width: 10),
                _buildStat('Unread', unread, Icons.mark_email_unread_rounded,
                    MaaColors.warning),
                const SizedBox(width: 10),
                _buildStat('Read', _notifications.length - unread,
                    Icons.mark_email_read_rounded, MaaColors.success),
              ]),
            ),
          ),

          // ── Filter Chips ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildFilterChips(),
          ),

          // ── Notifications List ───────────────────────────────
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? SliverFillRemaining(child: _buildEmpty())
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _buildCard(_filtered[i], i),
                          childCount: _filtered.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  // ── Stats badge ───────────────────────────────────────────
  Widget _buildStat(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            color.withAlpha(30),
            color.withAlpha(15),
          ]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text('$value',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: MaaColors.textSecondary)),
        ]),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────
  Widget _buildFilterChips() {
    // Group chips – show only categories that have notifications
    final presentCategories =
        _notifications.map((n) => n.category).toSet().toList();

    if (presentCategories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        children: [
          // All chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('All',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _activeFilter == null
                          ? Colors.white
                          : MaaColors.textSecondary)),
              selected: _activeFilter == null,
              onSelected: (_) => setState(() => _applyFilter(null)),
              backgroundColor: MaaColors.glassBackground,
              selectedColor: MaaColors.pink,
              checkmarkColor: Colors.white,
              side: BorderSide(
                  color: _activeFilter == null
                      ? MaaColors.pink
                      : MaaColors.glassBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
          // Category chips
          ...presentCategories.map((cat) {
            final isSelected = _activeFilter == cat;
            final color = _getCategoryColor(cat);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${cat.emoji} ${cat.label}',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : MaaColors.textSecondary)),
                selected: isSelected,
                onSelected: (_) =>
                    setState(() => _applyFilter(isSelected ? null : cat)),
                backgroundColor: MaaColors.glassBackground,
                selectedColor: color,
                checkmarkColor: Colors.white,
                side: BorderSide(
                    color: isSelected ? color : MaaColors.glassBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Notification card ─────────────────────────────────────
  Widget _buildCard(NotificationItem n, int index) {
    final color = _getCategoryColor(n.category);
    final isUnread = !n.isRead;

    return Dismissible(
      key: Key(n.id),
      // Swipe right → Mark read
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: MaaColors.success.withAlpha(30),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(children: [
          const Icon(Icons.done_all_rounded, color: MaaColors.success),
          const SizedBox(width: 6),
          Text('Read',
              style: GoogleFonts.poppins(
                  color: MaaColors.success, fontWeight: FontWeight.w600)),
        ]),
      ),
      // Swipe left → Delete
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: MaaColors.warning.withAlpha(30),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: MaaColors.warning),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await _markAsRead(n.id);
          return false; // don't remove from list – just update
        }
        return true; // delete on swipe left
      },
      onDismissed: (_) => _delete(n.id),
      child: GestureDetector(
        onTap: () => _onTap(n),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isUnread ? color.withAlpha(18) : MaaColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUnread ? color.withAlpha(60) : MaaColors.glassBorder,
            ),
            boxShadow: isUnread
                ? [BoxShadow(color: color.withAlpha(20), blurRadius: 8)]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(children: [
                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        color.withAlpha(100),
                        color.withAlpha(50),
                      ]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(n.category.emoji,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(n.category.label,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color)),
                    ]),
                  ),
                  const Spacer(),
                  // Unread dot
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(_formatTime(n.timestamp),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: MaaColors.textSecondary)),
                ]),
              ),
              // Content
              Padding(
                padding: EdgeInsets.fromLTRB(
                    14, 10, 14, n.actionButton1Label != null ? 6 : 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w500,
                              color: MaaColors.textPrimary)),
                      const SizedBox(height: 5),
                      Text(n.body,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: MaaColors.textSecondary,
                              height: 1.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ]),
              ),
              // Action buttons
              if (n.actionButton1Label != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _markAsRead(n.id);
                          if (n.actionButton1Route != null) {
                            Navigator.pushNamed(context, n.actionButton1Route!,
                                arguments: n.data);
                          } else if (n.route != null) {
                            Navigator.pushNamed(context, n.route!,
                                arguments: n.data);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              color.withAlpha(180),
                              color.withAlpha(120),
                            ]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            n.actionButton1Label!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    if (n.actionButton2Label != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _markAsRead(n.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: MaaColors.glassBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: MaaColors.glassBorder),
                            ),
                            child: Text(
                              n.actionButton2Label!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: MaaColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (40 * index).ms).slideX(begin: 0.08, end: 0);
  }

  // ── Empty State ───────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              MaaColors.pink.withAlpha(30),
              MaaColors.softPurple.withAlpha(20),
            ]),
            shape: BoxShape.circle,
          ),
          child:
              const Center(child: Text('🔔', style: TextStyle(fontSize: 48))),
        ),
        const SizedBox(height: 20),
        Text(
          _activeFilter == null
              ? 'Koi Notification Nahi!'
              : '${_activeFilter!.emoji} Koi notification nahi',
          style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: MaaColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          _activeFilter == null
              ? 'Vaccination reminders, daily tips\naur community updates aane waale hain!'
              : 'Is category mein abhi koi notification nahi hai',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 13, color: MaaColors.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, '/notification-settings'),
          icon: const Icon(Icons.settings_rounded, size: 18),
          label: Text('Notification Settings',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: MaaColors.pink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ]),
    );
  }

  Color _getCategoryColor(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.pregnancyMilestone:
        return MaaColors.pink;
      case NotificationCategory.childGrowth:
        return MaaColors.lightBlue;
      case NotificationCategory.vaccination:
        return MaaColors.warning;
      case NotificationCategory.doctorConsult:
        return MaaColors.softPurple;
      case NotificationCategory.symptomCheck:
        return MaaColors.peach;
      case NotificationCategory.healthInsights:
        return MaaColors.gold;
      case NotificationCategory.safetyAlert:
        return Colors.redAccent;
      case NotificationCategory.nutrition:
        return MaaColors.success;
      case NotificationCategory.selfCare:
        return MaaColors.softGreen;
      case NotificationCategory.trackerSync:
        return MaaColors.lightBlue;
      case NotificationCategory.community:
        return MaaColors.softPurple;
      case NotificationCategory.friendRequest:
        return MaaColors.pink;
      case NotificationCategory.healthNews:
        return MaaColors.peach;
      case NotificationCategory.general:
        return MaaColors.textSecondary;
    }
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Abhi';
    if (diff.inHours < 1) return '${diff.inMinutes}m pehle';
    if (diff.inDays < 1) return '${diff.inHours}h pehle';
    if (diff.inDays < 7) return '${diff.inDays}d pehle';
    return '${t.day}/${t.month}/${t.year}';
  }
}
