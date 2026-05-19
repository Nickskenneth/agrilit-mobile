class AppConstants {
  // App info
  static const String appName = 'AgriLit';
  static const String appVersion = '1.0.0';

  // Komoditas
  static const List<String> commodities = ['cabai', 'kentang', 'jagung'];

  static const Map<String, String> commodityEmoji = {
    'cabai': '🌶️',
    'kentang': '🥔',
    'jagung': '🌽',
    'umum': '🌱',
  };

  static const Map<String, String> commodityLabel = {
    'cabai': 'Cabai',
    'kentang': 'Kentang',
    'jagung': 'Jagung',
    'umum': 'Umum',
  };

  // Kategori artikel
  static const Map<String, String> categoryLabel = {
    'budidaya': 'Budidaya',
    'pemupukan': 'Pemupukan',
    'pengendalian': 'Pengendalian OPT',
    'pascapanen': 'Pasca Panen',
    'umum': 'Umum',
  };

  // SQLite
  static const String dbName = 'agrilit.db';
  static const int dbVersion = 1;

  // SharedPreferences keys
  static const String keyToken = 'auth_token';
  static const String keyUser = 'auth_user';
  static const String keyLastSync = 'last_sync_at';

  // Image compression
  static const int imageMaxWidth = 800;
  static const int imageMaxHeight = 800;
  static const int imageQuality = 75;
}
