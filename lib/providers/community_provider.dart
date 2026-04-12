// ============================================================
//  CommunityProvider – MaaCare (InsForge)
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/insforge_service.dart';
import '../services/realtime_client.dart';

class CommunityProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  List<UserModel> _suggestedMamas = [];
  bool _isLoading = false;
  String? _error;
  int? _weekFilter;

  List<PostModel> get posts => _posts;
  List<UserModel> get suggestedMamas => _suggestedMamas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get weekFilter => _weekFilter;

  Future<void> fetchPosts({int? weekTag}) async {
    _weekFilter = weekTag;
    _setLoading(true);
    try {
      _posts = await InsForgeService.instance.fetchPosts(weekTag: weekTag);
      _suggestedMamas = await InsForgeService.instance.fetchUsers(limit: 8);
      _suggestedMamas.shuffle();
      if (_suggestedMamas.length > 5) {
         _suggestedMamas = _suggestedMamas.sublist(0, 5);
      }
      _error = null;

      InsForgeRealtimeClient.instance.subscribe('posts:all', (payload) {
        if (payload['event'] == 'INSERT_post') {
          final newPost = PostModel.fromMap(payload['record']);
          if (!_posts.any((p) => p.id == newPost.id)) {
             if (_weekFilter == null || _weekFilter == newPost.weekTag) {
                 _posts.insert(0, newPost);
                 notifyListeners();
             }
          }
        }
      });
      
    } catch (e) {
      _error = 'Could not load posts. Check your connection.';
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> uploadMedia(String fileName, List<int> bytes, {String bucket = 'community_media'}) async {
    return await InsForgeService.instance.uploadFile(
      bucket: bucket,
      fileName: fileName,
      bytes: bytes,
    );
  }

  Future<bool> createPost(PostModel post) async {
    try {
      final created = await InsForgeService.instance.createPost(post);
      if (created != null) {
        _posts.insert(0, created);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> likePost(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    if (post.isLikedByMe) return;

    _posts[index]
      ..likes += 1
      ..isLikedByMe = true;
    notifyListeners();

    try {
      await InsForgeService.instance.likePost(postId, post.likes);
    } catch (_) {
      // Revert on failure
      _posts[index]
        ..likes -= 1
        ..isLikedByMe = false;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
