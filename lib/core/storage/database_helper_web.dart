// Stub DatabaseHelper untuk Flutter Web
// SQLite (sqflite) tidak digunakan di web — semua data diambil dari API online.
// File ini menggantikan database_helper.dart saat dikompilasi untuk web.

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // ============================================================
  // ARTICLE STUBS — No-op, data dari API online
  // ============================================================
  Future<void> upsertArticles(List<Map<String, dynamic>> articles) async {}

  Future<List<Map<String, dynamic>>> getArticles({
    String? commodity,
    String? category,
    String? search,
  }) async => [];

  Future<Map<String, dynamic>?> getArticleById(int id) async => null;

  // ============================================================
  // SOP STUBS
  // ============================================================
  Future<void> upsertSops(List<Map<String, dynamic>> sops) async {}

  Future<List<Map<String, dynamic>>> getSops({String? commodity}) async => [];

  Future<Map<String, dynamic>?> getSopById(int id) async => null;

  // ============================================================
  // OFFLINE SCAN STUBS
  // ============================================================
  Future<int> insertOfflineScan(Map<String, dynamic> scan) async => 0;

  Future<List<Map<String, dynamic>>> getUnsyncedScans() async => [];

  Future<void> markScanSynced(int localId) async {}

  Future<int> getUnsyncedCount() async => 0;
}
