// Conditional export: gunakan stub untuk web, implementasi sqflite untuk mobile
export 'database_helper_stub.dart'
    if (dart.library.io) 'database_helper_io.dart'
    if (dart.library.html) 'database_helper_web.dart';
