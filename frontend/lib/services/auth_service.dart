import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<String?> login(String email, String password) async {
    final res = await _api.post("/api/auth/login", {
      "email": email,
      "password": password,
    });

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data["token"] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("jwt_token", data["token"]);
      return null; // success
    }

    return data["message"] ?? "Login failed";
  }

  Future<String?> signup(String email, String password) async {
    final res = await _api.post("/api/auth/signup", {
      "email": email,
      "password": password,
    });

    final data = jsonDecode(res.body);
    if (res.statusCode == 201 || res.statusCode == 200) return null;

    return data["message"] ?? "Signup failed";
  }

  Future<String?> forgotPassword(String email) async {
    final res = await _api.post("/api/auth/forgot-password", {"email": email});

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return null;

    return data["message"] ?? "Request failed";
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt_token");
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");
    return token != null && token.isNotEmpty;
  }
}
