// ============================================================
//  Parents Park – Community Screen – MaaCare Premium Dark
//  Dark feed with infinite scroll, hover glow, heartbeat likes
// ============================================================

// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../app_theme.dart';
import '../../models/post_model.dart';
import '../../providers/community_provider.dart';
import '../../providers/user_provider.dart';
import '../../constants.dart';
import '../../services/maacare_backend_service.dart';
import '../../services/push_notification_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/error_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/menstrual_medical_theme.dart';

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
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final provider = context.read<CommunityProvider>();
    await provider.fetchPosts();
    if (provider.error != null && mounted) {
      ErrorHelper.showError(context, provider.error!);
    }
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
      'hate',
      'kill',
      'die',
      'stupid',
      'ugly',
      'worst',
      'terrible',
      'disgusting',
      'horrible',
      'pathetic',
      'loser',
      'dumb',
      'useless',
    ];
    final lower = content.toLowerCase();
    final user = context.read<UserProvider>().user;
    final isUnmarried = user?.userRole == 'unmarried_girl';
    for (final word in negativeWords) {
      if (lower.contains(word)) {
        return isUnmarried
            ? '🌸 Sending love and positivity to all sakhis! Every day is a new blessing. You are strong, beautiful, and never alone. 💕'
            : '🌸 Sending love and positivity to all mamas! Every day is a new blessing. You are strong, beautiful, and never alone. 💕';
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

    final success = await context.read<CommunityProvider>().createPost(post);
    if (success && mounted) {
      _confetti.play();
      context.read<UserProvider>().addPoints(AppConstants.pointsPerPost);
      ErrorHelper.showSuccess(
          context, 'Post shared! 🌸 +10 MaaPoints! Stay positive!');
    } else if (mounted) {
      ErrorHelper.showError(context, 'Could not share post. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>().user;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Consumer<CommunityProvider>(
        builder: (ctx, provider, _) => LoadingOverlay(
          isLoading: provider.isLoading,
          child: Stack(
            children: [
              // Particle background — isolated widget with proper lifecycle
              const _CommunityParticles(),
              Column(
                children: [
                  _buildSocialProofHeader(),
                  // ── Suggested Mamas moved to bottom of feed ──
                  Expanded(
                    child: Builder(
                      builder: (ctx) {
                        if (!provider.isLoading &&
                            provider.error != null &&
                            provider.posts.isEmpty) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.all(24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: MaaColors.cardDark,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: MaaColors.glassBorder),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('😔',
                                      style: TextStyle(fontSize: 48)),
                                  const SizedBox(height: 12),
                                  Text(
                                    provider.error!,
                                    style: const TextStyle(
                                        color: MaaColors.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  NeonButton(
                                    label: 'Try again 💕',
                                    onPressed: _fetchData,
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
                                border:
                                    Border.all(color: MaaColors.glassBorder),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🌸',
                                          style: TextStyle(fontSize: 64))
                                      .animate(onPlay: (c) => c.repeat())
                                      .scale(
                                          begin: const Offset(1, 1),
                                          end: const Offset(1.1, 1.1),
                                          duration: 1.seconds),
                                  const SizedBox(height: 16),
                                  Text(
                                    user?.userRole == 'unmarried_girl' ? 'Be the first to share, Sakhi!' : 'Be the first to share, Mama!',
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

                        // Total items = posts + 1 (Suggested Mamas footer)
                        final totalItems = provider.posts.length + 1;

                        return RefreshIndicator(
                          onRefresh: _fetchData,
                          color: MaaColors.pink,
                          backgroundColor: MaaColors.cardDark,
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: totalItems,
                            separatorBuilder: (_, i) {
                              // No separator before the footer
                              if (i == provider.posts.length - 1) {
                                return const SizedBox(height: 28);
                              }
                              return const SizedBox(height: 14);
                            },
                            itemBuilder: (_, i) {
                              // Last item → Suggested Mamas section
                              if (i == provider.posts.length) {
                                return _buildSuggestedConnectionsFooter(
                                    provider);
                              }
                              return _PostCard(
                                post: provider.posts[i],
                                onLike: () =>
                                    provider.likePost(provider.posts[i].id),
                              )
                                  .animate()
                                  .fadeIn(delay: (i * 60).ms)
                                  .moveY(begin: 20, end: 0);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final user = context.read<UserProvider>().user;
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
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
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(user?.userRole == 'unmarried_girl' ? '🌸' : '🌳', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            user?.userRole == 'unmarried_girl' ? 'Sakhi Circle' : AppLocalizations.of(context).navCommunity,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
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
            child: const Icon(Icons.filter_list_rounded,
                color: MaaColors.textPrimary, size: 20),
          ),
          onPressed: _showFilterSheet,
        ),
      ],
    );
  }

  Widget _buildSocialProofHeader() {
    final user = context.read<UserProvider>().user;
    final isUnmarried = user?.userRole == 'unmarried_girl';
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
              isUnmarried
                  ? '${AppConstants.momsOnline} Sakhis sharing their journey'
                  : '${AppConstants.momsOnline} Mamas sharing their journey',
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



  // Footer version — rendered as last item inside the feed ListView
  Widget _buildSuggestedConnectionsFooter(CommunityProvider provider) {
    final user = context.read<UserProvider>().user;
    final isUnmarried = user?.userRole == 'unmarried_girl';
    final mamas = provider.suggestedMamas;
    if (mamas.isEmpty) return const SizedBox.shrink();

    const colors1 = [
      Color(0xFFE91E8C),
      Color(0xFF42A5F5),
      Color(0xFF4CAF50),
      Color(0xFFFF7043),
      Color(0xFFEC407A),
    ];
    const colors2 = [
      Color(0xFFAB47BC),
      Color(0xFF7E57C2),
      Color(0xFF26C6DA),
      Color(0xFFFFD600),
      Color(0xFFFF7043),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Divider with label ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Container(height: 1, color: MaaColors.glassBorder),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink).withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink).withAlpha(40)),
                ),
                child: Text(
                  isUnmarried ? "🌸 You've reached the end" : "🌸 You've reached the end",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink,
                  ),
                ),
              ),
              Expanded(
                child: Container(height: 1, color: MaaColors.glassBorder),
              ),
            ],
          ),
        ),

        // ── Section header ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUnmarried
                  ? [
                      MenstrualMedicalTheme.electricOrchid.withAlpha(18),
                      MenstrualMedicalTheme.darkSlate.withAlpha(18),
                    ]
                  : [
                      MaaColors.pink.withAlpha(18),
                      MaaColors.softPurple.withAlpha(18),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: MaaColors.glassBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUnmarried
                            ? [MenstrualMedicalTheme.electricOrchid, MenstrualMedicalTheme.darkSlate]
                            : [MaaColors.pink, MaaColors.softPurple],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.group_add_rounded,
                        color: MaaColors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUnmarried ? 'Suggested Sakhis' : 'Suggested Mamas',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: MaaColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        isUnmarried
                            ? 'Connect with friends on the same journey'
                            : 'Connect with mamas on the same journey',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: MaaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MaaColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
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
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${mamas.length} online',
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
        ),

        // ── Horizontal card list ────────────────────────────────────────────
        Container(
          height: 230,
          decoration: BoxDecoration(
            color: MaaColors.cardDark.withAlpha(60),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            border: Border(
              left: BorderSide(color: MaaColors.glassBorder),
              right: BorderSide(color: MaaColors.glassBorder),
              bottom: BorderSide(color: MaaColors.glassBorder),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            itemCount: mamas.length,
            itemBuilder: (ctx, index) {
              final m = mamas[index];
              final hash = m.id.hashCode.abs();
              final col1 = colors1[hash % colors1.length];
              final col2 = colors2[hash % colors2.length];
              final cardWeek =
                  m.pregnancyWeek > 0 ? 'Week ${m.pregnancyWeek}' : (isUnmarried ? 'Sakhi' : 'Mama');

              return GestureDetector(
                onTap: () => _showUserProfile(
                    context, m.name, cardWeek, 'India', col1, col2, m),
                child: _SuggestedConnectionCard(
                  name: m.name,
                  week: cardWeek,
                  location: 'India',
                  postCount: m.points.toString(),
                  gradientColor1: col1,
                  gradientColor2: col2,
                  avatarUrl: m.avatarUrl,
                )
                    .animate()
                    .fadeIn(delay: (index * 80).ms)
                    .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
              );
            },
          ),
        ),
        const SizedBox(height: 80), // space for FAB
      ],
    ).animate().fadeIn(delay: 200.ms).moveY(begin: 30, end: 0);
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
    final isUnmarried = user?.userRole == 'unmarried_girl';
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
            _buildFilterOption('🌍', isUnmarried ? 'All Sakhis' : 'All Mamas', () {
              _fetchData();
              Navigator.pop(context);
            }),
            if (!isUnmarried)
              _buildFilterOption('👶', 'Week ${user?.pregnancyWeek ?? 0} Mamas',
                  () {
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

  void _showUserProfile(
    BuildContext ctx,
    String name,
    String week,
    String location,
    Color col1,
    Color col2,
    dynamic user,
  ) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.65,
        decoration: BoxDecoration(
          color: MaaColors.cardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: MaaColors.glassBorder),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MaaColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [col1, col2]),
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: MaaColors.background),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: col1.withAlpha(30),
                  child: Text(
                    name
                        .trim()
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800, color: col1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(name,
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.textPrimary)),
            const SizedBox(height: 4),
            Text(week,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.pink,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 14, color: MaaColors.textMuted),
                Text(location,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: MaaColors.textMuted)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statChip('Week', week.replaceAll('Week ', ''), col1),
                _statChip('Points', user != null ? '${user.points ?? 0}' : '—',
                    const Color(0xFF4CAF50)),
                _statChip(
                    'Posts',
                    user != null ? '${(user.pregnancyWeek ?? 0) + 2}' : '—',
                    MaaColors.pink),
              ],
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [col1, col2]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: col1.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24))),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Connect with $name 💕',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: MaaColors.textSecondary)),
      ],
    );
  }
}

class _SuggestedConnectionCard extends StatefulWidget {
  final String name;
  final String week;
  final String location;
  final String postCount;
  final Color gradientColor1;
  final Color gradientColor2;
  final String? avatarUrl;

  const _SuggestedConnectionCard({
    required this.name,
    required this.week,
    required this.location,
    required this.postCount,
    required this.gradientColor1,
    required this.gradientColor2,
    this.avatarUrl,
  });

  @override
  State<_SuggestedConnectionCard> createState() =>
      _SuggestedConnectionCardState();
}

class _SuggestedConnectionCardState extends State<_SuggestedConnectionCard>
    with SingleTickerProviderStateMixin {
  bool _isConnected = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleConnect() {
    _animController.forward().then((_) {
      if (mounted) {
        setState(() => _isConnected = !_isConnected);
        _animController.reverse();

        if (_isConnected) {
          final payload = NotificationPayload(
            type: 'community',
            title: 'Friend Request',
            body: '${widget.name} wants to connect with you! 💕',
            route: '/community',
          );
          PushNotificationService.instance.addNotificationFromPayload(payload);
        }
      }
    });
  }

  String get _initials {
    final parts = widget.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color:
              _isConnected ? MaaColors.pink.withAlpha(15) : MaaColors.cardDark,
          border: Border.all(
            color: _isConnected
                ? MaaColors.pink.withAlpha(80)
                : MaaColors.glassBorder.withAlpha(80),
            width: _isConnected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isConnected
                  ? MaaColors.pink.withAlpha(25)
                  : MaaColors.darkShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar with online dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [widget.gradientColor1, widget.gradientColor2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: MaaColors.background,
                      ),
                      child: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: widget.avatarUrl!,
                                fit: BoxFit.cover,
                                width: 52,
                                height: 52,
                                memCacheWidth: 120,
                                placeholder: (context, url) => Center(
                                  child: Text(
                                    _initials,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: widget.gradientColor1,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Text(
                                    _initials,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: widget.gradientColor1,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 26,
                              backgroundColor: widget.gradientColor1.withAlpha(30),
                              child: Text(
                                _initials,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: widget.gradientColor1,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Online green dot
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: MaaColors.success,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: MaaColors.background, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Name
              Text(
                widget.name,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: MaaColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              // Week + Location
              Text(
                widget.week,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: MaaColors.pink,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 10, color: MaaColors.textMuted),
                  Text(
                    widget.location,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: MaaColors.textMuted,
                    ),
                  ),
                  Text(
                    '  •  ${widget.postCount} posts',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: MaaColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Connect button
              GestureDetector(
                onTap: _handleConnect,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    gradient: _isConnected ? null : MaaColors.primaryGradient,
                    color:
                        _isConnected ? MaaColors.success.withAlpha(30) : null,
                    borderRadius: BorderRadius.circular(12),
                    border: _isConnected
                        ? Border.all(color: MaaColors.success.withAlpha(80))
                        : null,
                    boxShadow: _isConnected
                        ? []
                        : [
                            BoxShadow(
                              color: MaaColors.pink.withAlpha(70),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isConnected)
                        const Icon(Icons.check_rounded,
                            size: 12, color: MaaColors.success)
                      else
                        const Icon(Icons.person_add_rounded,
                            size: 12, color: MaaColors.white),
                      const SizedBox(width: 4),
                      Text(
                        _isConnected ? 'Following ✓' : 'Follow',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isConnected
                              ? MaaColors.success
                              : MaaColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
  bool _isConnected = false;

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
      _replies = await MaaCareBackendService.instance.fetchReplies(widget.post.id);
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
      final reply = await MaaCareBackendService.instance.createReply(
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
              content: Text(
                user.userRole == 'unmarried_girl'
                    ? 'Reply sent! 💕 You\'re supporting a friend!'
                    : 'Reply sent! 💕 You\'re supporting a mama!',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: MaaColors.cardLight,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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

  Widget _buildPostImage(String url) {
    if (url.startsWith('data:')) {
      try {
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes,
            fit: BoxFit.fitWidth, width: double.infinity);
      } catch (_) {
        return const SizedBox();
      }
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.fitWidth,
      width: double.infinity,
      memCacheWidth: 600,
      placeholder: (context, url) => Container(
        height: 150,
        color: MaaColors.cardLight,
        child: const Center(
          child: CircularProgressIndicator(
            color: MaaColors.pink,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 100,
        color: MaaColors.cardLight,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: MaaColors.textMuted,
          ),
        ),
      ),
    );
  }

  void _handleLike() {
    _heartController.forward().then((_) => _heartController.reverse());
    widget.onLike();
  }

  void _sharePost(BuildContext ctx, PostModel post) {
    final text = '💕 From MaaCare Parents Park:\n\n"${post.content}"\n\n'
        '— ${post.displayName}\n\nJoin our community: https://maacare.app';
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: MaaColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Share Post 🌸',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: MaaColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MaaColors.glassBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MaaColors.glassBorder),
              ),
              child: Text(text,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: MaaColors.textSecondary,
                      height: 1.5)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: MaaColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MaaColors.pink,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: const Text('Post shared! 💕'),
                  backgroundColor: MaaColors.cardLight,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Text('Share 💕',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
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
            // Algorithmic Label
            if (post.likes >= 5)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text('Trending near you',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MaaColors.pink)),
                  ],
                ),
              )
            else if (!post.anonymous)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Text('💫', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text('Suggested connection',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MaaColors.softPurple)),
                  ],
                ),
              ),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: post.anonymous ? MaaColors.primaryGradient : null,
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: MaaColors.softPurple.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: MaaColors.softPurple.withAlpha(50)),
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
                  )
                else
                  GestureDetector(
                    onTap: () => setState(() => _isConnected = !_isConnected),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? MaaColors.pink.withAlpha(20)
                            : MaaColors.pink,
                        borderRadius: BorderRadius.circular(20),
                        border: _isConnected
                            ? Border.all(color: MaaColors.pink.withAlpha(50))
                            : null,
                      ),
                      child: Text(
                        _isConnected ? '✔️' : '➕ Connect',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              _isConnected ? MaaColors.pink : MaaColors.white,
                        ),
                      ),
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
                  child: _buildPostImage(post.imageUrl!),
                ),
              ),

            // Video
            if (post.videoUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: VideoPostPlayer(url: post.videoUrl!),
              ),

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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                const SizedBox(width: 10),
                // Share button
                GestureDetector(
                  onTap: () => _sharePost(context, post),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: MaaColors.pink.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: MaaColors.pink.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.share_rounded,
                            size: 14, color: MaaColors.pink),
                        const SizedBox(width: 6),
                        Text(
                          'Share',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: MaaColors.pink,
                            fontWeight: FontWeight.w600,
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
                                  : ((r['author_name'] as String?)
                                              ?.isNotEmpty ==
                                          true
                                      ? (r['author_name'] as String)[0]
                                          .toUpperCase()
                                      : 'M'),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: MaaColors.cardLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (r['anonymous'] == true)
                                        ? (user?.userRole == 'unmarried_girl' ? 'Sakhi 🌸' : 'Mama 🌸')
                                        : (r['author_name'] as String? ??
                                            (user?.userRole == 'unmarried_girl' ? 'Sakhi' : 'Mama')),
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
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: MaaColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Write a supportive reply... 💕',
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 12, color: MaaColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
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
  bool _uploading = false;
  XFile? _mediaFile;
  Uint8List? _mediaBytes;
  String? _videoBlobUrl; // Web only: blob URL for preview
  bool _isVideo = false;

  Future<void> _pickMedia(bool video) async {
    final picker = ImagePicker();
    final file = video
        ? await picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 3))
        : await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (file != null) {
      setState(() {
        _mediaFile = file;
        _isVideo = video;
        _mediaBytes = null;
        _videoBlobUrl = null;
      });
      if (video) {
        // On web, XFile.path returns the blob URL directly
        setState(() => _videoBlobUrl = file.path);
      } else {
        final bytes = await file.readAsBytes();
        setState(() => _mediaBytes = bytes);
      }
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
              hintText:
                  'Share your thoughts, ask questions, celebrate wins... 💕',
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
                clipBehavior: Clip.none,
                children: [
                  if (_isVideo)
                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            MaaColors.softPurple.withAlpha(40),
                            MaaColors.cardLight
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                            color: MaaColors.softPurple.withAlpha(60)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam_rounded,
                              color: MaaColors.softPurple, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'Video selected ✅',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: MaaColors.softPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _mediaFile!.name.length > 30
                                ? '...${_mediaFile!.name.substring(_mediaFile!.name.length - 28)}'
                                : _mediaFile!.name,
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: MaaColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: MaaColors.cardLight,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _mediaBytes != null
                            ? Image.memory(_mediaBytes!,
                                fit: BoxFit.cover, width: 120, height: 120)
                            : const Center(
                                child: Icon(Icons.image_rounded,
                                    color: MaaColors.pink, size: 36)),
                      ),
                    ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _mediaFile = null;
                        _mediaBytes = null;
                        _videoBlobUrl = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: MaaColors.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: MaaColors.error.withAlpha(100),
                                blurRadius: 6)
                          ],
                        ),
                        child: const Icon(Icons.close,
                            color: MaaColors.white, size: 13),
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
                  child: const Icon(Icons.image_outlined,
                      color: MaaColors.pink, size: 20),
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
                  child: const Icon(Icons.videocam_outlined,
                      color: MaaColors.softPurple, size: 20),
                ),
                onPressed: () => _pickMedia(true),
                tooltip: 'Add video',
              ),
              const Spacer(),
              // Anonymous toggle with mask icon
              GestureDetector(
                onTap: () => setState(() => _anonymous = !_anonymous),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              label: _uploading ? 'Uploading media... 📤' : 'Share Post 🌸',
              isLoading: _posting || _uploading,
              onPressed: (_posting ||
                      _uploading ||
                      _controller.text.trim().isEmpty)
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        setState(() {
                          _posting = true;
                          _uploading = false;
                        });

                        String? imgUrl;
                        String? vidUrl;

                        if (_mediaFile != null) {
                          final ext =
                              _mediaFile!.name.split('.').last.toLowerCase();
                          final fileName =
                              '${_isVideo ? 'vid' : 'img'}_${DateTime.now().millisecondsSinceEpoch}.$ext';

                          setState(() => _uploading = true);

                          final commProvider =
                              context.read<CommunityProvider>();
                          Uint8List? uploadBytes;
                          if (_isVideo) {
                            uploadBytes = await _mediaFile!.readAsBytes();
                          } else {
                            uploadBytes = _mediaBytes;
                          }

                          if (uploadBytes != null) {
                            try {
                              final url = await commProvider.uploadMedia(
                                  fileName, uploadBytes);
                              if (_isVideo) {
                                // Try server URL first, fallback to base64 for web persistence
                                if (url != null &&
                                    !url.contains('ui-avatars')) {
                                  vidUrl = url;
                                } else {
                                  // Encode video as base64 data URI so it persists
                                  final base64Str = base64Encode(uploadBytes);
                                  final mime = ext == 'mp4'
                                      ? 'video/mp4'
                                      : ext == 'mov'
                                          ? 'video/quicktime'
                                          : ext == 'webm'
                                              ? 'video/webm'
                                              : 'video/mp4';
                                  vidUrl = 'data:$mime;base64,$base64Str';
                                }
                              } else {
                                imgUrl = url;
                                if (imgUrl == null && _mediaBytes != null) {
                                  final base64Str = base64Encode(_mediaBytes!);
                                  final mimeType = ext == 'png'
                                      ? 'image/png'
                                      : ext == 'gif'
                                          ? 'image/gif'
                                          : 'image/jpeg';
                                  imgUrl = 'data:$mimeType;base64,$base64Str';
                                }
                              }
                            } catch (e) {
                              debugPrint('Upload error: $e');
                              if (_isVideo) vidUrl = _videoBlobUrl;
                            }
                          }
                          setState(() => _uploading = false);
                        }

                        await widget.onPost(
                          _controller.text,
                          _anonymous,
                          imageUrl: imgUrl,
                          videoUrl: vidUrl,
                        );

                        if (mounted) navigator.pop();
                      } catch (e) {
                        debugPrint('Post submission error: $e');
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Error sharing post. Please try again.')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _posting = false;
                            _uploading = false;
                          });
                        }
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Video Player Widget - Web-Compatible
// ═══════════════════════════════════════════════════════════════

class VideoPostPlayer extends StatefulWidget {
  final String url;
  const VideoPostPlayer({super.key, required this.url});

  @override
  State<VideoPostPlayer> createState() => _VideoPostPlayerState();
}

class _VideoPostPlayerState extends State<VideoPostPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;
  bool _isDataUri = false;

  @override
  void initState() {
    super.initState();
    _isDataUri =
        widget.url.startsWith('data:') || widget.url.startsWith('blob:');

    if (_isDataUri && !kIsWeb) {
      _initLocalDataUri();
      return;
    }

    // On Web, blob: and data: URIs can be played directly by the video element via networkUrl.
    _initNetworkUrl(widget.url);
  }

  Future<void> _initLocalDataUri() async {
    try {
      final base64Str = widget.url.split(',').last;
      final bytes = base64Decode(base64Str);
      final filename = 'temp_vid_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File('${Directory.systemTemp.path}/$filename');
      await file.writeAsBytes(bytes);

      _controller = VideoPlayerController.file(file);
      await _controller.initialize();
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      debugPrint('Video Base64 decode error: $e');
      if (mounted) setState(() => _error = true);
    }
  }

  void _initNetworkUrl(String url) {
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      }).catchError((e) {
        debugPrint('Video init error: $e');
        if (mounted) setState(() => _error = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: MaaColors.cardLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_camera_back_rounded,
                  color: MaaColors.textMuted, size: 32),
              SizedBox(height: 8),
              Text('Video unavailable',
                  style: TextStyle(color: MaaColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: MaaColors.cardLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child:
              CircularProgressIndicator(color: MaaColors.pink, strokeWidth: 2),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: !_controller.value.isPlaying
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: MaaColors.white.withAlpha(50)),
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: MaaColors.white, size: 40),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _controller.setVolume(_controller.value.volume == 0 ? 1 : 0);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _controller.value.volume == 0
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: MaaColors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Isolated community particle widget ───────────────────────────────────────
class _CommunityParticles extends StatefulWidget {
  const _CommunityParticles();
  @override
  State<_CommunityParticles> createState() => _CommunityParticlesState();
}

class _CommunityParticlesState extends State<_CommunityParticles>
    with TickerProviderStateMixin {
  static const int _count = 10;
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _count,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(seconds: 3 + (i % 4)),
      )..repeat(reverse: true),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -20)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          children: List.generate(_count, (i) {
            final random = i * 37 % 100;
            final dotSize = 1.5 + (i % 3).toDouble();
            final color = i % 3 == 0
                ? MaaColors.pink.withAlpha(25)
                : i % 3 == 1
                    ? MaaColors.gold.withAlpha(20)
                    : MaaColors.softPurple.withAlpha(25);
            return Positioned(
              left: (random * 3.6) % size.width,
              top: (random * 5.2) % size.height,
              child: AnimatedBuilder(
                animation: _animations[i],
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _animations[i].value),
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
