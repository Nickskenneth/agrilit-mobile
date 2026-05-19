import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  // Auth
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get logout => '$baseUrl/auth/logout';
  static String get me => '$baseUrl/auth/me';

  // Articles
  static String get articles => '$baseUrl/articles';
  static String get articlesSync => '$baseUrl/articles/sync';
  static String article(int id) => '$baseUrl/articles/$id';

  // SOPs
  static String get sops => '$baseUrl/sops';
  static String get sopsSync => '$baseUrl/sops/sync';
  static String sop(int id) => '$baseUrl/sops/$id';

  // Forum
  static String get forum => '$baseUrl/forum';
  static String get forumPending => '$baseUrl/forum/pending';
  static String get myPosts => '$baseUrl/forum/my-posts';
  static String forumDetail(int id) => '$baseUrl/forum/$id';
  static String forumReplies(int id) => '$baseUrl/forum/$id/replies';
  static String forumModerate(int id) => '$baseUrl/forum/$id/moderate';
  static String replyUpvote(int id) => '$baseUrl/forum/replies/$id/upvote';

  // Disease Scans
  static String get scans => '$baseUrl/scans';
  static String get scansSync => '$baseUrl/scans/sync';
  static String scanDetail(int id) => '$baseUrl/scans/$id';
}
