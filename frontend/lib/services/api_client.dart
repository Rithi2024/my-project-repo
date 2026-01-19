import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiClient {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token");
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = <String, String>{"Content-Type": "application/json"};

    if (auth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        h["Authorization"] = "Bearer $token";
      }
    }
    return h;
  }

  Future<http.Response> get(String path, {bool auth = false}) async {
    final url = Uri.parse(AppConfig.baseUrl + path);
    return http.get(url, headers: await _headers(auth: auth));
  }

  Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final url = Uri.parse(AppConfig.baseUrl + path);
    return http.post(
      url,
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final url = Uri.parse(AppConfig.baseUrl + path);
    return http.put(
      url,
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path, {bool auth = false}) async {
    final url = Uri.parse(AppConfig.baseUrl + path);
    return http.delete(url, headers: await _headers(auth: auth));
  }
}
