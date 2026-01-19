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

  final String baseUrl; // ex: http://10.60.135.185:3000/api
  final TokenStorage _tokenStorage;

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: await _headers(auth: auth));
    return _handle(res);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.post(
      uri,
      headers: await _headers(auth: auth),
      body: jsonEncode(body ?? {}),
    );
    return _handle(res);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.put(
      uri,
      headers: await _headers(auth: auth),
      body: jsonEncode(body ?? {}),
    );
    return _handle(res);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.delete(uri, headers: await _headers(auth: auth));
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
    if (data is Map && data['message'] != null)
      msg = data['message'].toString();
    throw ApiException(msg, statusCode: res.statusCode);
  }
}
