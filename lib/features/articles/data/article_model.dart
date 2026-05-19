class ArticleModel {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? content;
  final String? thumbnailUrl;
  final String commodity;
  final String category;
  final int views;
  final String? authorName;
  final String? authorRole;
  final String? publishedAt;
  final String updatedAt;
  bool isRead;

  ArticleModel({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.content,
    this.thumbnailUrl,
    required this.commodity,
    required this.category,
    required this.views,
    this.authorName,
    this.authorRole,
    this.publishedAt,
    required this.updatedAt,
    this.isRead = false,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) => ArticleModel(
        id: json['id'] as int,
        title: json['title'] as String,
        slug: json['slug'] as String? ?? '',
        excerpt: json['excerpt'] as String?,
        content: json['content'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        commodity: json['commodity'] as String? ?? 'umum',
        category: json['category'] as String? ?? 'umum',
        views: json['views'] as int? ?? 0,
        authorName:
            (json['author'] as Map<String, dynamic>?)?['name'] as String?,
        authorRole:
            (json['author'] as Map<String, dynamic>?)?['role'] as String?,
        publishedAt: json['published_at'] as String?,
        updatedAt: json['updated_at'] as String,
      );

  // Untuk simpan ke & baca dari SQLite
  Map<String, dynamic> toLocalDb() => {
        'id': id,
        'title': title,
        'slug': slug,
        'excerpt': excerpt,
        'content': content,
        'thumbnail_url': thumbnailUrl,
        'commodity': commodity,
        'category': category,
        'views': views,
        'author_name': authorName,
        'author_role': authorRole,
        'published_at': publishedAt,
        'updated_at': updatedAt,
        'is_read': isRead ? 1 : 0,
      };

  factory ArticleModel.fromLocalDb(Map<String, dynamic> map) => ArticleModel(
        id: map['id'] as int,
        title: map['title'] as String,
        slug: map['slug'] as String? ?? '',
        excerpt: map['excerpt'] as String?,
        content: map['content'] as String?,
        thumbnailUrl: map['thumbnail_url'] as String?,
        commodity: map['commodity'] as String? ?? 'umum',
        category: map['category'] as String? ?? 'umum',
        views: map['views'] as int? ?? 0,
        authorName: map['author_name'] as String?,
        authorRole: map['author_role'] as String?,
        publishedAt: map['published_at'] as String?,
        updatedAt: map['updated_at'] as String,
        isRead: (map['is_read'] as int? ?? 0) == 1,
      );
}
