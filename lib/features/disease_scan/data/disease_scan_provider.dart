import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/database_helper.dart';
import 'disease_scan_model.dart';

class DiseaseScanProvider extends ChangeNotifier {
  DiseaseScanModel? _lastResult;
  List<DiseaseScanModel> _history = [];
  bool _isScanning = false;
  bool _isLoading = false;
  String? _error;
  int _unsyncedCount = 0;

  DiseaseScanModel? get lastResult => _lastResult;
  List<DiseaseScanModel> get history => _history;
  bool get isScanning => _isScanning;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unsyncedCount => _unsyncedCount;

  final _api = ApiClient();
  final _db = DatabaseHelper();

  // ============================================================
  // COMPRESS IMAGE — Kurangi ukuran sebelum upload
  // ============================================================
  Future<File> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final origin = img.decodeImage(bytes);
    if (origin == null) return file;

    final resized = img.copyResize(
      origin,
      width: AppConstants.imageMaxWidth,
      height: AppConstants.imageMaxHeight,
      maintainAspect: true,
    );

    final compressed =
        img.encodeJpg(resized, quality: AppConstants.imageQuality);

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final out = File(path);
    await out.writeAsBytes(compressed);
    return out;
  }

  // ============================================================
  // GET GPS — Ambil koordinat dengan permission check
  // ============================================================
  Future<Position?> _getPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // SCAN — Upload ke Laravel → FastAPI
  // ============================================================
  Future<bool> scanImage({
    required File imageFile,
    required String commodity,
  }) async {
    _isScanning = true;
    _error = null;
    _lastResult = null;
    notifyListeners();

    // 1. Kompres gambar
    final compressed = await _compressImage(imageFile);

    // 2. Ambil GPS
    final position = await _getPosition();

    // 3. Build form fields
    // PENTING: 'commodity' WAJIB ada di fields karena Laravel
    // membaca $request->commodity lalu forward ke FastAPI /predict/{commodity}
    final fields = <String, String>{
      'commodity': commodity, // ← Ini yang menentukan filter di FastAPI
      'scanned_at': DateTime.now().toIso8601String(),
      if (position != null) ...{
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
      },
    };

    // Log untuk debugging
    debugPrint('=== SCAN REQUEST ===');
    debugPrint('Commodity: $commodity');
    debugPrint('Fields: $fields');
    debugPrint('Image path: ${compressed.path}');

    // 4. Upload ke Laravel
    final response = await _api.postMultipart(
      ApiConstants.scans, // → POST /api/scans
      fields: fields,
      imageFile: compressed,
      fileField: 'image', // ← field name harus 'image' sesuai validasi Laravel
    );

    _isScanning = false;

    debugPrint('=== SCAN RESPONSE ===');
    debugPrint('Success: ${response.success}');
    debugPrint('Data: ${response.data}');

    if (response.success) {
      final data = response.data as Map<String, dynamic>;
      _lastResult =
          DiseaseScanModel.fromJson(data['data'] as Map<String, dynamic>);
      notifyListeners();
      return true;
    }

    if (response.isNetworkError) {
      await _saveOfflineScan(
        imageFile: compressed,
        commodity: commodity,
        position: position,
      );
      _error = 'Tidak ada koneksi. Hasil scan disimpan untuk sinkronisasi.';
      await _updateUnsyncedCount();
    } else {
      _error = response.message;
      debugPrint('Scan error: ${response.message}');
    }

    notifyListeners();
    return false;
  }

  // ============================================================
  // SIMPAN OFFLINE — Ke SQLite saat tidak ada koneksi
  // ============================================================
  Future<void> _saveOfflineScan({
    required File imageFile,
    required String commodity,
    Position? position,
  }) async {
    await _db.insertOfflineScan({
      'commodity': commodity,
      'image_path': imageFile.path,
      'latitude': position?.latitude,
      'longitude': position?.longitude,
      'scanned_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  // ============================================================
  // SYNC OFFLINE SCANS — Kirim batch data dari SQLite ke server
  // ============================================================
  Future<Map<String, int>> syncOfflineScans() async {
    final unsynced = await _db.getUnsyncedScans();
    if (unsynced.isEmpty) return {'saved': 0, 'failed': 0};

    int saved = 0, failed = 0;

    for (final scan in unsynced) {
      final localId = scan['local_id'] as int;

      // Coba re-scan jika ada gambar
      final imagePath = scan['image_path'] as String?;
      bool success = false;

      if (imagePath != null && File(imagePath).existsSync()) {
        final response = await _api.postMultipart(
          ApiConstants.scans,
          fields: {
            'commodity': scan['commodity'] as String,
            'scanned_at': scan['scanned_at'] as String,
            if (scan['latitude'] != null)
              'latitude': scan['latitude'].toString(),
            if (scan['longitude'] != null)
              'longitude': scan['longitude'].toString(),
          },
          imageFile: File(imagePath),
          fileField: 'image',
        );
        success = response.success;
      } else {
        // Gambar tidak ada, kirim metadata saja
        final response = await _api.post(
          ApiConstants.scansSync,
          body: {
            'scans': [
              {
                'commodity': scan['commodity'],
                'latitude': scan['latitude'],
                'longitude': scan['longitude'],
                'scanned_at': scan['scanned_at'],
              }
            ]
          },
        );
        success = response.success;
      }

      if (success) {
        await _db.markScanSynced(localId);
        saved++;
      } else {
        failed++;
      }
    }

    await _updateUnsyncedCount();
    notifyListeners();
    return {'saved': saved, 'failed': failed};
  }

  // ============================================================
  // HISTORY — Riwayat scan dari server
  // ============================================================
  Future<void> fetchHistory({String? commodity}) async {
    _isLoading = true;
    notifyListeners();

    String url = ApiConstants.scans;
    if (commodity != null && commodity.isNotEmpty) {
      url += '?commodity=$commodity';
    }

    final response = await _api.get(url);

    if (response.success) {
      final data = response.data as Map<String, dynamic>;
      final rawList = data['data'] as List<dynamic>;
      _history = rawList
          .map((e) => DiseaseScanModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _error = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _updateUnsyncedCount() async {
    _unsyncedCount = await _db.getUnsyncedCount();
  }

  Future<void> loadUnsyncedCount() async {
    await _updateUnsyncedCount();
    notifyListeners();
  }
}
