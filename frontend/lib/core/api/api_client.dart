import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({required this.baseUrl, TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  final String baseUrl;
  final TokenStorage _tokenStorage;

  // ✅ keep an in-memory token to avoid async races
  String? _token;

  /// Call once at app start (or from AuthProvider.init)
  Future<void> initTokenFromStorage() async {
    _token = await _tokenStorage.getToken();
  }

  /// Call on login/logout to instantly update token used by requests
  Future<void> setToken(String? token) async {
    _token = token;
    if (token == null || token.isEmpty) {
      await _tokenStorage.clearToken();
    } else {
      await _tokenStorage.saveToken(token);
    }
  }

  Map<String, String> _headers({required bool auth}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    if (auth) {
      final t = _token;
      if (t != null && t.isNotEmpty) {
        headers['Authorization'] = 'Bearer $t';
      }
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final res = await http.get(
      _uri(path, query),
      headers: _headers(auth: auth),
    );
    return _handle(res);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final res = await http.post(
      _uri(path),
      headers: _headers(auth: auth),
      body: jsonEncode(body ?? {}),
    );
    return _handle(res);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final res = await http.put(
      _uri(path),
      headers: _headers(auth: auth),
      body: jsonEncode(body ?? {}),
    );
    return _handle(res);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final res = await http.delete(_uri(path), headers: _headers(auth: auth));
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      data = res.body;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    String msg = 'Request failed';
    if (data is Map && data['message'] != null) {
      msg = data['message'].toString();
    }
    throw ApiException(msg, statusCode: res.statusCode);
  }
}
