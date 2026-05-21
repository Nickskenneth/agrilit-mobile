// Default stub — sama seperti web stub (no-op)
// Dipakai bila tidak ada platform yang spesifik cocok
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<void> upsertArticles(List<Map<String, dynamic>> articles) async {}
  Future<List<Map<String, dynamic>>> getArticles({String? commodity, String? category, String? search}) async => [];
  Future<Map<String, dynamic>?> getArticleById(int id) async => null;
  Future<void> upsertSops(List<Map<String, dynamic>> sops) async {}
  Future<List<Map<String, dynamic>>> getSops({String? commodity}) async => [];
  Future<Map<String, dynamic>?> getSopById(int id) async => null;
  Future<int> insertOfflineScan(Map<String, dynamic> scan) async => 0;
  Future<List<Map<String, dynamic>>> getUnsyncedScans() async => [];
  Future<void> markScanSynced(int localId) async {}
  Future<int> getUnsyncedCount() async => 0;
}
