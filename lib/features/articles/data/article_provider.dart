import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/database_helper.dart';
import 'article_model.dart';

class ArticleProvider extends ChangeNotifier {
  List<ArticleModel> _articles = [];
  ArticleModel? _selected;
  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<ArticleModel> get articles => _articles;
  ArticleModel? get selected => _selected;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get error => _error;
  bool get hasMore => _hasMore;

  final _api = ApiClient();
  final _db = DatabaseHelper();

  // ============================================================
  // FETCH — Online pertama, fallback ke SQLite jika offline
  // ============================================================
  Future<void> fetchArticles({
    String? commodity,
    String? category,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      _articles = [];
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Build URL dengan query params
    String url = '${ApiConstants.articles}?page=$_currentPage';
    if (commodity != null && commodity.isNotEmpty)
      url += '&commodity=$commodity';
    if (category != null && category.isNotEmpty) url += '&category=$category';
    if (search != null && search.isNotEmpty) url += '&search=$search';

    final response = await _api.get(url);

    if (response.success) {
      _isOffline = false;
      final data = response.data as Map<String, dynamic>;
      final rawList = data['data'] as List<dynamic>;
      final meta = data['meta'] as Map<String, dynamic>;

      final newArticles = rawList
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Cache ke SQLite untuk offline
      await _db.upsertArticles(newArticles.map((a) => a.toLocalDb()).toList());

      _articles.addAll(newArticles);
      _currentPage++;
      _hasMore = _currentPage <= (meta['last_page'] as int);
    } else if (response.isNetworkError) {
      // Fallback ke SQLite
      _isOffline = true;
      final localData = await _db.getArticles(
        commodity: commodity,
        category: category,
        search: search,
      );
      _articles = localData.map((m) => ArticleModel.fromLocalDb(m)).toList();
      _hasMore = false;
    } else {
      _error = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============================================================
  // FETCH DETAIL — Online atau SQLite
  // ============================================================
  Future<void> fetchArticleDetail(int id) async {
    _isLoading = true;
    _selected = null;
    _error = null;
    notifyListeners();

    final response = await _api.get(ApiConstants.article(id));

    if (response.success) {
      final data = response.data as Map<String, dynamic>;
      _selected = ArticleModel.fromJson(data['data'] as Map<String, dynamic>);
      // Update cache
      await _db.upsertArticles([_selected!.toLocalDb()]);
    } else if (response.isNetworkError) {
      final local = await _db.getArticleById(id);
      if (local != null) {
        _selected = ArticleModel.fromLocalDb(local);
        _isOffline = true;
      } else {
        _error = 'Artikel tidak tersedia secara offline.';
      }
    } else {
      _error = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }
}
