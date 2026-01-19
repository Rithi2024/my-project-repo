import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required ApiClient api, TokenStorage? tokenStorage})
    : _api = api,
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  bool isLoading = false;
  String? error;
  String? token;
  User? user;

  Future<void> init() async {
    token = await _tokenStorage.getToken();
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _api.post(
        '/auth/login',
        auth: false,
        body: {"email": email, "password": password},
      );

      final t = (res['token'] ?? '') as String;
      if (t.isEmpty) throw ApiException('Token missing from response');

      token = t;
      await _tokenStorage.saveToken(t);

      if (res['user'] is Map<String, dynamic>) {
        user = User.fromJson(res['user']);
      }

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String email,
    String? username,
    required String password,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _api.post(
        '/auth/signup',
        auth: false,
        body: {'email': email, 'username': username, 'password': password},
      );

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _api.post(
        '/auth/forgot-password',
        auth: false,
        body: {'email': email},
      );
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _api.post(
        '/auth/reset-password',
        auth: false,
        body: {'email': email, 'otp': otp, 'new_password': newPassword},
      );
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
    token = null;
    user = null;
    notifyListeners();
  }

  bool get isLoggedIn => token != null && token!.isNotEmpty;
}
