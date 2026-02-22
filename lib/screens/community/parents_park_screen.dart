// ============================================================
//  Parents Park – Community Screen – MaaCare Premium Dark
//  Dark feed with infinite scroll, hover glow, heartbeat likes
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../models/post_model.dart';
import '../../providers/community_provider.dart';
import '../../providers/user_provider.dart';
import '../../constants.dart';
import '../../services/insforge_service.dart';

class ParentsParkScreen extends StatefulWidget {
  const ParentsParkScreen({super.key});

  @override
  State<ParentsParkScreen> createState() => _ParentsParkScreenState();
}

class _ParentsParkScreenState extends State<ParentsParkScreen>
    with TickerProviderStateMixin {
  final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 2),
  );
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 6, end: 12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchPosts();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showNewPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewPostSheet(
        onPost: _submitPost,
        confetti: _confetti,
      ),
    );
  }

  String _moderateContent(String content) {
    final negativeWords = [
      'hate', 'kill', 'die', 'stupid', 'ugly', 'worst', 'terrible',
      'disgusting', 'horrible', 'pathetic', 'loser', 'dumb', 'useless',
    ];
    final lower = content.toLowerCase();
    for (final word in negativeWords) {
      if (lower.contains(word)) {
        return '🌸 Sending love and positivity to all mamas! Every day is a new blessing. You are strong, beautiful, and never alone. 💕';
      }
    }
    return content;
  }

  Future<void> _submitPost(String content, bool anonymous,
      {String? imageUrl, String? videoUrl}) async {
    final user = context.read<UserProvider>().user;
    if (user == null || content.trim().isEmpty) return;

    final moderatedContent = _moderateContent(content.trim());

    final post = PostModel(
      id: const Uuid().v4(),
      userId: user.id,
      content: moderatedContent,
      weekTag: user.pregnancyWeek,
      anonymous: anonymous,
      authorName: user.name,
      createdAt: DateTime.now(),
      imageUrl: imageUrl,
      videoUrl: videoUrl,
    );

    final success =
        await context.read<CommunityProvider>().createPost(post);
    if (success && mounted) {
      _confetti.play();
      context.read<UserProvider>().addPoints(AppConstants.pointsPerPost);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post shared! 🌸 +10 MaaPoints! Stay positive!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: MaaColors.cardLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Particle background
          ...List.generate(15, (index) {
            final random = index * 37 % 100;
            final size = 1.5 + (index % 3);
            return Positioned(
              left: (random * 3.6) % MediaQuery.of(context).size.width,
              top: (random * 5.2) % MediaQuery.of(context).size.height,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index % 3 == 0
                      ? MaaColors.pink.withAlpha(25)
                      : index % 3 == 1
                          ? MaaColors.gold.withAlpha(20)
                          : MaaColors.softPurple.withAlpha(25),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).moveY(
                  begin: 0,
                  end: -20,
                  duration: Duration(seconds: 3 + (index % 4)),
                  curve: Curves.easeInOut,
                );
          }),
          Column(
            children: [
              _buildSocialProofHeader(),
              Expanded(
                child: Consumer<CommunityProvider>(
                  builder: (ctx, provider, _) {
                    if (provider.isLoading) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: MaaColors.glassBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: MaaColors.pink, strokeWidth: 2),
                              SizedBox(height: 16),
                              Text('Loading stories from mamas... 🌸',
                                  style: TextStyle(
                                      color: MaaColors.textSecondary,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }
                    if (provider.error != null) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: MaaColors.cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: MaaColors.glassBorder),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('😔', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                provider.error!,
                                style: const TextStyle(color: MaaColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              NeonButton(
                                label: 'Try again 💕',
                                onPressed: () => provider.fetchPosts(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (provider.posts.isEmpty) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: MaaColors.cardDark,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: MaaColors.glassBorder),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🌸', style: TextStyle(fontSize: 64))
                                  .animate(onPlay: (c) => c.repeat())
                                  .scale(
                                      begin: const Offset(1, 1),
                                      end: const Offset(1.1, 1.1),
                                      duration: 1.seconds),
                              const SizedBox(height: 16),
                              Text(
                                'Be the first to share, Mama!',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: MaaColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your story could inspire thousands 💕',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: MaaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => provider.fetchPosts(),
                      color: MaaColors.pink,
                      backgroundColor: MaaColors.cardDark,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.posts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) => _PostCard(
                          post: provider.posts[i],
                          onLike: () => provider.likePost(provider.posts[i].id),
                        ).animate().fadeIn(delay: (i * 60).ms).moveY(begin: 20, end: 0),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                MaaColors.pink,
                MaaColors.softPurple,
                MaaColors.gold,
              ],
              numberOfParticles: 25,
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: MaaColors.background,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MaaColors.glassBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: MaaColors.textPrimary, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌳', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            'Parents Park',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MaaColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MaaColors.glassBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.filter_list_rounded, color: MaaColors.textPrimary, size: 20),
          ),
          onPressed: _showFilterSheet,
        ),
      ],
    );
  }

  Widget _buildSocialProofHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MaaColors.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaaColors.glassBorder),
      ),
      child: Row(
        children: [
          const Text('💬', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${AppConstants.momsOnline} Mamas sharing their journey',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: MaaColors.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: MaaColors.success.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MaaColors.success.withAlpha(50)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: MaaColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: MaaColors.success.withAlpha(150),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ).animate(onPlay: (c) => c.repeat()).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.3, 1.3),
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(width: 6),
                Text(
                  'Live',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: MaaColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: MaaColors.pink.withAlpha(150),
                blurRadius: _pulseAnimation.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _showNewPostSheet,
            backgroundColor: MaaColors.pink,
            icon: const Icon(Icons.edit_rounded, color: MaaColors.white),
            label: Text(
              'Share',
              style: GoogleFonts.poppins(
                color: MaaColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    final user = context.read<UserProvider>().user;
    showModalBottomSheet(
      context: context,
      backgroundColor: MaaColors.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MaaColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Filter Posts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MaaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterOption('🌍', 'All Mamas', () {
              context.read<CommunityProvider>().fetchPosts();
              Navigator.pop(context);
            }),
            _buildFilterOption('👶', 'Week ${user?.pregnancyWeek ?? 0} Mamas', () {
              context
                  .read<CommunityProvider>()
                  .fetchPosts(weekTag: user?.pregnancyWeek);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String emoji, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MaaColors.glassBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          color: MaaColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Post Card with Like, Reply, Anonymous badge - Dark Premium
// ═══════════════════════════════════════════════════════════════

class _PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onLike;
  const _PostCard({required this.post, required this.onLike});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  bool _showReplies = false;
  List<Map<String, dynamic>> _replies = [];
  bool _loadingReplies = false;
  final _replyController = TextEditingController();
  bool _postingReply = false;
  bool _isHovered = false;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    setState(() => _loadingReplies = true);
    try {
      _replies = await InsForgeService.instance.fetchReplies(widget.post.id);
    } catch (_) {}
    if (mounted) setState(() => _loadingReplies = false);
  }

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() => _postingReply = true);
    try {
      final reply = await InsForgeService.instance.createReply(
        postId: widget.post.id,
        userId: user.id,
        content: text,
        authorName: user.name,
        anonymous: true,
      );
      if (reply != null) {
        _replies.add(reply);
        _replyController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Reply sent! 💕 You\'re supporting a mama!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: MaaColors.cardLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _postingReply = false);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  void _handleLike() {
    _heartController.forward().then((_) => _heartController.reverse());
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: MaaColors.cardDark,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _isHovered
                ? MaaColors.pink.withAlpha(80)
                : MaaColors.glassBorder,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: MaaColors.pink.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: MaaColors.darkShadow,
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: post.anonymous
                        ? MaaColors.primaryGradient
                        : null,
                    shape: BoxShape.circle,
                    color: post.anonymous ? null : MaaColors.pink.withAlpha(50),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: MaaColors.cardLight,
                    child: Text(
                      post.anonymous
                          ? '🌸'
                          : (post.authorName?.isNotEmpty == true
                              ? post.authorName![0].toUpperCase()
                              : 'M'),
                      style: TextStyle(
                        fontSize: 18,
                        color: post.anonymous
                            ? MaaColors.textPrimary
                            : MaaColors.pink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.displayName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: MaaColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          if (post.weekTag > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: MaaColors.pink.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Week ${post.weekTag}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: MaaColors.pink,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (post.weekTag > 0) const SizedBox(width: 8),
                          Text(
                            _timeAgo(post.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: MaaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (post.anonymous)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: MaaColors.softPurple.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MaaColors.softPurple.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        const Text('🎭', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          'Anon',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: MaaColors.softPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Content
            Text(
              post.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: MaaColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),

            // Media
            if (post.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: MaaColors.cardLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded,
                            color: MaaColors.textMuted),
                      ),
                    ),
                  ),
                ),
              ),

            // Action Buttons
            Row(
              children: [
                // Like button with heartbeat
                AnimatedBuilder(
                  animation: _heartAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _heartAnimation.value,
                      child: GestureDetector(
                        onTap: _handleLike,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: post.isLikedByMe
                                ? MaaColors.pink.withAlpha(30)
                                : MaaColors.cardLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: post.isLikedByMe
                                  ? MaaColors.pink.withAlpha(100)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                post.isLikedByMe ? '❤️' : '🤍',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${post.likes}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: post.isLikedByMe
                                      ? MaaColors.pink
                                      : MaaColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                // Reply button
                GestureDetector(
                  onTap: () {
                    setState(() => _showReplies = !_showReplies);
                    if (_showReplies && _replies.isEmpty) _loadReplies();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: MaaColors.cardLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          _showReplies ? 'Hide' : 'Reply',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: MaaColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Replies Section
            if (_showReplies) ...[
              const SizedBox(height: 14),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      MaaColors.glassBorder,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_loadingReplies)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MaaColors.pink),
                    ),
                  ),
                )
              else ...[
                if (_replies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No replies yet. Be the first! 🌸',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: MaaColors.textMuted,
                      ),
                    ),
                  ),
                ..._replies.map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: MaaColors.softPurple.withAlpha(30),
                            child: Text(
                              (r['anonymous'] == true)
                                  ? '🌸'
                                  : ((r['author_name'] as String?)?.isNotEmpty == true
                                      ? (r['author_name'] as String)[0].toUpperCase()
                                      : 'M'),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: MaaColors.cardLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (r['anonymous'] == true)
                                        ? 'Mama 🌸'
                                        : (r['author_name'] as String? ?? 'Mama'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: MaaColors.pink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    r['content'] as String? ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: MaaColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 10),
              // Reply input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      style: GoogleFonts.poppins(fontSize: 13, color: MaaColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Write a supportive reply... 💕',
                        hintStyle: GoogleFonts.poppins(fontSize: 12, color: MaaColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: MaaColors.cardLight,
                      ),
                      onSubmitted: (_) => _submitReply(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _postingReply ? null : _submitReply,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: MaaColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: MaaColors.pink.withAlpha(80),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: _postingReply
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: MaaColors.white))
                          : const Icon(Icons.send_rounded,
                              color: MaaColors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  New Post Sheet - Dark Premium
// ═══════════════════════════════════════════════════════════════

class _NewPostSheet extends StatefulWidget {
  final Future<void> Function(String content, bool anonymous,
      {String? imageUrl, String? videoUrl}) onPost;
  final ConfettiController confetti;
  const _NewPostSheet({required this.onPost, required this.confetti});

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _controller = TextEditingController();
  bool _anonymous = true;
  bool _posting = false;
  XFile? _mediaFile;
  bool _isVideo = false;

  Future<void> _pickMedia(bool video) async {
    final picker = ImagePicker();
    final file = video
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() {
        _mediaFile = file;
        _isVideo = video;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: MaaColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MaaColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: MaaColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🌸', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share with the community',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: MaaColors.textPrimary,
                      ),
                    ),
                    Text(
                      'AI moderation keeps this a safe space 💕',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: MaaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            maxLines: 4,
            style: GoogleFonts.poppins(color: MaaColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Share your thoughts, ask questions, celebrate wins... 💕',
              hintStyle: GoogleFonts.poppins(color: MaaColors.textMuted),
              filled: true,
              fillColor: MaaColors.cardLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 14),
          if (_mediaFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Stack(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: MaaColors.cardLight,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: Icon(
                          _isVideo ? Icons.video_library_rounded : Icons.image_rounded,
                          color: MaaColors.pink,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: GestureDetector(
                      onTap: () => setState(() => _mediaFile = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: MaaColors.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: MaaColors.error.withAlpha(100),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close, color: MaaColors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MaaColors.pink.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image_outlined, color: MaaColors.pink, size: 20),
                ),
                onPressed: () => _pickMedia(false),
                tooltip: 'Add photo',
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MaaColors.softPurple.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.videocam_outlined, color: MaaColors.softPurple, size: 20),
                ),
                onPressed: () => _pickMedia(true),
                tooltip: 'Add video',
              ),
              const Spacer(),
              // Anonymous toggle with mask icon
              GestureDetector(
                onTap: () => setState(() => _anonymous = !_anonymous),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _anonymous
                        ? MaaColors.softPurple.withAlpha(30)
                        : MaaColors.pink.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _anonymous
                          ? MaaColors.softPurple.withAlpha(50)
                          : MaaColors.pink.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _anonymous ? '🎭' : '👤',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _anonymous ? 'Anonymous' : 'Public',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _anonymous
                              ? MaaColors.softPurple
                              : MaaColors.pink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: NeonButton(
              label: 'Share Post 🌸',
              isLoading: _posting,
              onPressed: _controller.text.trim().isEmpty
                  ? null
                  : () async {
                      setState(() => _posting = true);

                      String? imgUrl;
                      String? vidUrl;

                      if (_mediaFile != null) {
                        final bytes = await _mediaFile!.readAsBytes();
                        final ext = _mediaFile!.path.split('.').last;
                        final fileName = 'media_${DateTime.now().millisecondsSinceEpoch}.$ext';
                        final url = await context
                            .read<CommunityProvider>()
                            .uploadMedia(fileName, bytes);
                        if (_isVideo) {
                          vidUrl = url;
                        } else {
                          imgUrl = url;
                        }
                      }

                      await widget.onPost(
                        _controller.text,
                        _anonymous,
                        imageUrl: imgUrl,
                        videoUrl: vidUrl,
                      );
                      if (mounted) Navigator.pop(context);
                    },
            ),
          ),
        ],
      ),
    );
  }
}