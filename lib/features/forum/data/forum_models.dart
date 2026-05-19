class ForumPostModel {
  final int id;
  final String title;
  final String content;
  final String commodity;
  final String? imageUrl;
  final String status;
  final bool isAnswered;
  final int views;
  final int replyCount;
  final String? userName;
  final String? userRole;
  final String createdAt;
  final ForumReplyModel? expertReply;
  final List<ForumReplyModel> replies;

  ForumPostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.commodity,
    this.imageUrl,
    required this.status,
    required this.isAnswered,
    required this.views,
    required this.replyCount,
    this.userName,
    this.userRole,
    required this.createdAt,
    this.expertReply,
    this.replies = const [],
  });

  factory ForumPostModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final expertData = json['expert_reply'] as Map<String, dynamic>?;
    final repliesRaw = json['replies'] as List<dynamic>?;

    return ForumPostModel(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      commodity: json['commodity'] as String,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      isAnswered: json['is_answered'] as bool? ?? false,
      views: json['views'] as int? ?? 0,
      replyCount: json['reply_count'] as int? ?? 0,
      userName: user?['name'] as String?,
      userRole: user?['role'] as String?,
      createdAt: json['created_at'] as String,
      expertReply:
          expertData != null ? ForumReplyModel.fromJson(expertData) : null,
      replies: repliesRaw
              ?.map((e) => ForumReplyModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ForumReplyModel {
  final int? id;
  final String content;
  final String? imageUrl;
  final bool isExpertAnswer;
  final int upvotes;
  final String? userName;
  final String? userRole;
  final String? avatarUrl;
  final String? createdAt;

  ForumReplyModel({
    this.id,
    required this.content,
    this.imageUrl,
    required this.isExpertAnswer,
    required this.upvotes,
    this.userName,
    this.userRole,
    this.avatarUrl,
    this.createdAt,
  });

  factory ForumReplyModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return ForumReplyModel(
      id: json['id'] as int?,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      isExpertAnswer: json['is_expert_answer'] as bool? ?? false,
      upvotes: json['upvotes'] as int? ?? 0,
      userName: user?['name'] as String?,
      userRole: user?['role'] as String?,
      avatarUrl: user?['avatar_url'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
