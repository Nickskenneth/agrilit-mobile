import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'forum_models.dart';

class ForumProvider extends ChangeNotifier {
  List<ForumPostModel> _posts = [];
  ForumPostModel? _selected;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<ForumPostModel> get posts => _posts;
  ForumPostModel? get selected => _selected;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get hasMore => _hasMore;

  final _api = ApiClient();

  Future<void> fetchPosts({
    String? commodity,
    String? filter,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      _posts = [];
      _currentPage = 1;
      _hasMore = true;
    }
    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    String url = '${ApiConstants.forum}?page=$_currentPage';
    if (commodity != null && commodity.isNotEmpty)
      url += '&commodity=$commodity';
    if (filter != null && filter.isNotEmpty) url += '&filter=$filter';
    if (search != null && search.isNotEmpty) url += '&search=$search';

    final response = await _api.get(url);

    if (response.success) {
      final data = response.data as Map<String, dynamic>;
      final rawList = data['data'] as List<dynamic>;
      final meta = data['meta'] as Map<String, dynamic>;

      final newPosts = rawList
          .map((e) => ForumPostModel.fromJson(e as Map<String, dynamic>))
          .toList();

      _posts.addAll(newPosts);
      _currentPage++;
      _hasMore = _currentPage <= (meta['last_page'] as int);
    } else {
      _error = response.isNetworkError
          ? 'Forum membutuhkan koneksi internet.'
          : response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPostDetail(int id) async {
    _isLoading = true;
    _selected = null;
    _error = null;
    notifyListeners();

    final response = await _api.get(ApiConstants.forumDetail(id));

    if (response.success) {
      final data = response.data as Map<String, dynamic>;
      _selected = ForumPostModel.fromJson(data['data'] as Map<String, dynamic>);
    } else {
      _error = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPost({
    required String title,
    required String content,
    required String commodity,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    final response = await _api.post(
      ApiConstants.forum,
      body: {
        'title': title,
        'content': content,
        'commodity': commodity,
      },
    );

    _isSubmitting = false;

    if (response.success) {
      notifyListeners();
      return true;
    }

    _error = response.message;
    notifyListeners();
    return false;
  }

  Future<bool> replyPost(int postId, String content) async {
    _isSubmitting = true;
    notifyListeners();

    final response = await _api.post(
      ApiConstants.forumReplies(postId),
      body: {'content': content},
    );

    _isSubmitting = false;

    if (response.success) {
      // Refresh detail agar reply baru muncul
      await fetchPostDetail(postId);
      return true;
    }

    _error = response.message;
    notifyListeners();
    return false;
  }

  Future<void> upvoteReply(int replyId, int postId) async {
    await _api.post(ApiConstants.replyUpvote(replyId));
    // Refresh agar upvote count terupdate
    await fetchPostDetail(postId);
  }
}
