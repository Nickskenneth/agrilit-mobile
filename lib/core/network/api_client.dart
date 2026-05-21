import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'package:flutter/foundation.dart';

/// Wrapper HTTP client dengan auto-inject Authorization header
/// dan error handling terpusat
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyToken);
  }

  Map<String, String> _headers({bool withAuth = true, String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final t = token;
    if (withAuth && t != null) {
      headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  // ============================================================
  // GET
  // ============================================================
  Future<ApiResponse> get(String url, {bool withAuth = true}) async {
    try {
      final token = withAuth ? await _getToken() : null;
      final response = await http
          .get(Uri.parse(url),
              headers: _headers(withAuth: withAuth, token: token))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.networkError();
    } on HttpException {
      return ApiResponse.networkError();
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  // ============================================================
  // POST JSON
  // ============================================================
  Future<ApiResponse> post(
    String url, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    try {
      final token = withAuth ? await _getToken() : null;
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers(withAuth: withAuth, token: token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.networkError();
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  // ============================================================
  // POST MULTIPART — Untuk upload gambar (disease scan)
  // ============================================================
  Future<ApiResponse> postMultipart(
    String url, {
    required Map<String, String> fields,
    required File imageFile,
    String fileField = 'file',
  }) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      // PENTING: Tambahkan semua fields (termasuk commodity)
      request.fields.addAll(fields);

      // Log untuk debugging
      debugPrint('=== MULTIPART REQUEST ===');
      debugPrint('URL: $url');
      debugPrint('Fields: ${request.fields}');
      debugPrint('File field: $fileField');
      debugPrint('File path: ${imageFile.path}');

      request.files.add(
        await http.MultipartFile.fromPath(fileField, imageFile.path),
      );

      final streamed =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      debugPrint('=== MULTIPART RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint(
          'Body: ${response.body.substring(0, response.body.length.clamp(0, 500))}');

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.networkError();
    } catch (e) {
      debugPrint('Multipart error: $e');
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  // ============================================================
  // PATCH
  // ============================================================
  Future<ApiResponse> patch(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final token = await _getToken();
      final response = await http
          .patch(
            Uri.parse(url),
            headers: _headers(token: token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.networkError();
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  // ============================================================
  // HANDLE RESPONSE — Parse JSON & tangani error HTTP
  // ============================================================
  ApiResponse _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    dynamic data;
    try {
      data = jsonDecode(body);
    } catch (_) {
      data = {'message': body};
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return ApiResponse.success(data);
      case 401:
        return ApiResponse.unauthorized();
      case 403:
        return ApiResponse.error('Akses ditolak.', statusCode: 403);
      case 422:
        final errors = data['errors'] as Map<String, dynamic>?;
        final firstError = errors?.values.first;
        final msg = firstError is List ? firstError.first : data['message'];
        return ApiResponse.error(msg ?? 'Data tidak valid.', statusCode: 422);
      case 404:
        return ApiResponse.error('Data tidak ditemukan.', statusCode: 404);
      case 500:
        return ApiResponse.error('Kesalahan server.', statusCode: 500);
      default:
        return ApiResponse.error(
          data['message'] ?? 'Error ${response.statusCode}',
          statusCode: response.statusCode,
        );
    }
  }
}

// ============================================================
// ApiResponse — Wrapper hasil request
// ============================================================
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int? statusCode;
  final bool isNetworkError;
  final bool isUnauthorized;

  ApiResponse._({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.isNetworkError = false,
    this.isUnauthorized = false,
  });

  factory ApiResponse.success(dynamic data) =>
      ApiResponse._(success: true, data: data, statusCode: 200);

  factory ApiResponse.error(String message, {int? statusCode}) =>
      ApiResponse._(success: false, message: message, statusCode: statusCode);

  factory ApiResponse.networkError() => ApiResponse._(
        success: false,
        message: 'Tidak ada koneksi internet.',
        isNetworkError: true,
      );

  factory ApiResponse.unauthorized() => ApiResponse._(
        success: false,
        message: 'Sesi berakhir. Silakan login kembali.',
        isUnauthorized: true,
        statusCode: 401,
      );
}
