import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ===== ARTICLES =====
    await db.execute('''
      CREATE TABLE articles (
        id            INTEGER PRIMARY KEY,
        title         TEXT NOT NULL,
        slug          TEXT,
        excerpt       TEXT,
        content       TEXT,
        thumbnail_url TEXT,
        commodity     TEXT,
        category      TEXT,
        views         INTEGER DEFAULT 0,
        author_name   TEXT,
        author_role   TEXT,
        published_at  TEXT,
        updated_at    TEXT NOT NULL,
        is_read       INTEGER DEFAULT 0,
        cached_at     TEXT
      )
    ''');

    // ===== SOPS =====
    await db.execute('''
      CREATE TABLE sops (
        id               INTEGER PRIMARY KEY,
        title            TEXT NOT NULL,
        slug             TEXT,
        commodity        TEXT,
        description      TEXT,
        duration_days    INTEGER,
        monthly_calendar TEXT,
        inputs_needed    TEXT,
        thumbnail_url    TEXT,
        author_name      TEXT,
        updated_at       TEXT NOT NULL,
        cached_at        TEXT
      )
    ''');

    // ===== DISEASE SCANS (offline queue) =====
    await db.execute('''
      CREATE TABLE disease_scans_offline (
        local_id          INTEGER PRIMARY KEY AUTOINCREMENT,
        commodity         TEXT NOT NULL,
        image_path        TEXT,
        result_label      TEXT,
        result_label_id   TEXT,
        confidence_score  REAL,
        latitude          REAL,
        longitude         REAL,
        scanned_at        TEXT NOT NULL,
        notes             TEXT,
        synced            INTEGER DEFAULT 0
      )
    ''');
  }

  // ============================================================
  // ARTICLE METHODS
  // ============================================================

  Future<void> upsertArticles(List<Map<String, dynamic>> articles) async {
    final db = await database;
    final batch = db.batch();
    for (final article in articles) {
      batch.insert(
        'articles',
        {...article, 'cached_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getArticles({
    String? commodity,
    String? category,
    String? search,
  }) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];

    if (commodity != null && commodity.isNotEmpty) {
      where += ' AND commodity = ?';
      args.add(commodity);
    }
    if (category != null && category.isNotEmpty) {
      where += ' AND category = ?';
      args.add(category);
    }
    if (search != null && search.isNotEmpty) {
      where += ' AND (title LIKE ? OR excerpt LIKE ?)';
      args.addAll(['%$search%', '%$search%']);
    }

    return db.query(
      'articles',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'published_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getArticleById(int id) async {
    final db = await database;
    final result = await db.query(
      'articles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }

  // ============================================================
  // SOP METHODS
  // ============================================================

  Future<void> upsertSops(List<Map<String, dynamic>> sops) async {
    final db = await database;
    final batch = db.batch();
    for (final sop in sops) {
      batch.insert(
        'sops',
        {...sop, 'cached_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getSops({String? commodity}) async {
    final db = await database;
    return db.query(
      'sops',
      where: commodity != null ? 'commodity = ?' : null,
      whereArgs: commodity != null ? [commodity] : null,
      orderBy: 'commodity ASC',
    );
  }

  Future<Map<String, dynamic>?> getSopById(int id) async {
    final db = await database;
    final result = await db.query(
      'sops',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }

  // ============================================================
  // OFFLINE SCAN METHODS
  // ============================================================

  Future<int> insertOfflineScan(Map<String, dynamic> scan) async {
    final db = await database;
    return db.insert('disease_scans_offline', scan);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedScans() async {
    final db = await database;
    return db.query(
      'disease_scans_offline',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markScanSynced(int localId) async {
    final db = await database;
    await db.update(
      'disease_scans_offline',
      {'synced': 1},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM disease_scans_offline WHERE synced = 0',
    );
    return result.first['count'] as int;
  }
}
