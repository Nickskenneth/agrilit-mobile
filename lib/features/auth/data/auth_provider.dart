import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/auth_storage.dart';
import 'user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _api = ApiClient();
  final _storage = AuthStorage();

  // Cek status login saat app pertama dibuka
  Future<void> checkLoginStatus() async {
    _isLoggedIn = await _storage.isLoggedIn();
    if (_isLoggedIn) {
      final userData = await _storage.getUser();
      if (userData != null) _user = UserModel.fromJson(userData);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
      withAuth: false,
    );

    _isLoading = false;

    if (response.success) {
      final data = response.data as Map<String, dynamic>;
      await _storage.saveToken(data['token'] as String);
      await _storage.saveUser(data['user'] as Map<String, dynamic>);
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }

    _error = response.message;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? region,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.post(
      ApiConstants.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (phone != null) 'phone': phone,
        if (region != null) 'region': region,
      },
      withAuth: false,
    );

    _isLoading = false;

    if (response.success) {
      final data = response.data as Map<String, dynamic>;
      await _storage.saveToken(data['token'] as String);
      await _storage.saveUser(data['user'] as Map<String, dynamic>);
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }

    _error = response.message;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _api.post(ApiConstants.logout);
    await _storage.clear();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
