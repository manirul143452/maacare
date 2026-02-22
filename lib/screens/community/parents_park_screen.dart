// ============================================================
//  Parents Park – Community Screen – MaaCare
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../app_theme.dart';
import '../../models/post_model.dart';
import '../../providers/community_provider.dart';
import '../../providers/user_provider.dart';
import '../../constants.dart';

class ParentsParkScreen extends StatefulWidget {
  const ParentsParkScreen({super.key});

  @override
  State<ParentsParkScreen> createState() => _ParentsParkScreenState();
}

class _ParentsParkScreenState extends State<ParentsParkScreen> {
  final _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final week = context.read<UserProvider>().user?.pregnancyWeek;
      context.read<CommunityProvider>().fetchPosts(weekTag: week);
    });
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void _showNewPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewPostSheet(onPost: _submitPost),
    );
  }

  Future<void> _submitPost(String content, bool anonymous, {String? imageUrl, String? videoUrl}) async {
    final user = context.read<UserProvider>().user;
    if (user == null || content.trim().isEmpty) return;

    final post = PostModel(
      id: const Uuid().v4(),
      userId: user.id,
      content: content.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared! 🌸 Stay positive!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // Algorithm: Refresh feed on back navigation from a sub-screen
        context.read<CommunityProvider>().fetchPosts();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Parents Park 🌳'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: _showFilterSheet,
            ),
          ],
        ),
        body: Column(
          children: [
            // Social proof header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: MaaColors.pink.withAlpha(30),
              child: Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    '${AppConstants.momsOnline} Mamas sharing their journey',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: MaaColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<CommunityProvider>(
                builder: (ctx, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: MaaColors.deepPink),
                    );
                  }
                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('😔', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(provider.error!),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => provider.fetchPosts(),
                            child: const Text('Try again 💕'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (provider.posts.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🌸', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('Be the first to share, Mama!'),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _PostCard(
                      post: provider.posts[i],
                      onLike: () => provider.likePost(provider.posts[i].id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showNewPostSheet,
          backgroundColor: MaaColors.deepPink,
          icon: const Icon(Icons.edit_rounded, color: MaaColors.white),
          label: const Text('Share', style: TextStyle(color: MaaColors.white)),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final user = context.read<UserProvider>().user;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Posts',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Mamas'),
              leading: const Text('🌍', style: TextStyle(fontSize: 24)),
              onTap: () {
                context.read<CommunityProvider>().fetchPosts();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Week ${user?.pregnancyWeek ?? 0} Mamas'),
              leading: const Text('👶', style: TextStyle(fontSize: 24)),
              onTap: () {
                context
                    .read<CommunityProvider>()
                    .fetchPosts(weekTag: user?.pregnancyWeek);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  const _PostCard({required this.post, required this.onLike});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: MaaColors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: MaaColors.pink,
                child: const Text('🌸', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (post.weekTag > 0)
                    Text('Week ${post.weekTag}',
                        style: const TextStyle(
                            fontSize: 11, color: MaaColors.textGrey)),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MaaColors.pink.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🤍 Anonymous',
                    style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.content,
              style: const TextStyle(
                  fontSize: 14,
                  color: MaaColors.textDark,
                  height: 1.5)),
          const SizedBox(height: 12),
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: MaaColors.offWhite,
                    child: const Icon(Icons.broken_image_rounded, color: MaaColors.textGrey),
                  ),
                ),
              ),
            ),
          if (post.videoUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _VideoPlayerWidget(url: post.videoUrl!),
            ),
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: post.isLikedByMe
                        ? MaaColors.deepPink.withAlpha(30)
                        : MaaColors.offWhite,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        post.isLikedByMe ? '❤️' : '🤍',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text('${post.likes}',
                          style: TextStyle(
                            fontSize: 13,
                            color: post.isLikedByMe
                                ? MaaColors.deepPink
                                : MaaColors.textGrey,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewPostSheet extends StatefulWidget {
  final Future<void> Function(String content, bool anonymous, {String? imageUrl, String? videoUrl}) onPost;
  const _NewPostSheet({required this.onPost});

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
      decoration: const BoxDecoration(
        color: MaaColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Share with the community 🌸',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'AI moderation ensures a positive, supportive space 💕',
            style: TextStyle(fontSize: 12, color: MaaColors.textGrey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Share your thoughts, ask questions, celebrate wins... 💕',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          if (_mediaFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Stack(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: MaaColors.offWhite,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _isVideo 
                          ? const Center(child: Icon(Icons.video_library_rounded, color: MaaColors.deepPink))
                          : Image.network(_mediaFile!.path, fit: BoxFit.cover), // path works as local file on most platforms
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => setState(() => _mediaFile = null),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined, color: MaaColors.deepPink),
                onPressed: () => _pickMedia(false),
              ),
              IconButton(
                icon: const Icon(Icons.videocam_outlined, color: MaaColors.deepPink),
                onPressed: () => _pickMedia(true),
              ),
              const Spacer(),
              Switch(
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v),
                activeColor: MaaColors.deepPink,
              ),
              const Text('Post anonymously',
                  style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _posting
                  ? null
                  : () async {
                      setState(() => _posting = true);
                      
                      String? imgUrl;
                      String? vidUrl;

                      if (_mediaFile != null) {
                        final bytes = await _mediaFile!.readAsBytes();
                        final ext = _mediaFile!.path.split('.').last;
                        final fileName = 'media_${DateTime.now().millisecondsSinceEpoch}.$ext';
                        final url = await context.read<CommunityProvider>().uploadMedia(fileName, bytes);
                        if (_isVideo) vidUrl = url; else imgUrl = url;
                      }

                      await widget.onPost(_controller.text, _anonymous, imageUrl: imgUrl, videoUrl: vidUrl);
                      if (mounted) Navigator.pop(context);
                    },
              child: _posting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MaaColors.white))
                  : const Text('Share Post 🌸'),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container(
        height: 200,
        color: MaaColors.offWhite,
        child: const Center(child: CircularProgressIndicator(color: MaaColors.deepPink)),
      );
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          IconButton(
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 50,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
          ),
        ],
      ),
    );
  }
}
