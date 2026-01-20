import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api/api_client.dart';
import '../core/constants.dart';
import '../core/storage/token_storage.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({required ApiClient api}) : _api = api;

  final ApiClient _api;
  final TokenStorage _tokenStorage = TokenStorage();

  // Paging / filter
  final int limit = 20;
  int page = 1;

  int total = 0; // from backend paging.total
  int get totalPages => (total <= 0) ? 1 : ((total + limit - 1) ~/ limit);

  bool get hasPrev => page > 1;
  bool get hasNext => page < totalPages;

  String search = '';
  int? categoryId;

  String sortBy = 'name'; // name | price
  String order = 'asc'; // asc | desc

  // State
  bool isLoading = false;
  String? error;

  List<Product> items = [];

  String _cleanError(Object e) {
    final s = e.toString();
    return s.replaceFirst(RegExp(r'^ApiException\(\d+\):\s*'), '');
  }

  // ----------------------------
  // LIST (BUTTON PAGINATION)
  // ----------------------------

  Future<void> fetch({int? pageOverride, bool resetPage = false}) async {
    if (isLoading) return;

    if (resetPage) page = 1;
    if (pageOverride != null) page = pageOverride;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final query = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort_by': sortBy,
        'order': order,
      };

      if (search.trim().isNotEmpty) query['search'] = search.trim();
      if (categoryId != null) query['category_id'] = categoryId.toString();

      // backend returns { paging: { total }, data: [...] }
      final res = await _api.get('/products', query: query);

      final list = (res['data'] as List).cast<dynamic>();
      final paging = (res['paging'] as Map<String, dynamic>);
      total = (paging['total'] as int?) ?? 0;

      items = list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error = _cleanError(e);
      notifyListeners();
    }
  }

  Future<void> resetAndFetch() async {
    await fetch(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!hasNext) return;
    await fetch(pageOverride: page + 1);
  }

  Future<void> prevPage() async {
    if (!hasPrev) return;
    await fetch(pageOverride: page - 1);
  }

  // ----------------------------
  // CRUD
  // ----------------------------

  Future<bool> create({
    required String name,
    String? description,
    required int categoryId,
    required double price,
    String? imageFilename,
  }) async {
    error = null;
    notifyListeners();

    try {
      await _api.post(
        '/products',
        body: {
          'name': name.trim(),
          'description': (description ?? '').trim().isEmpty
              ? null
              : description!.trim(),
          'category_id': categoryId,
          'price': price,
          'image_url': (imageFilename ?? '').trim().isEmpty
              ? null
              : imageFilename!.trim(),
        },
      );

      // common UX: go back to page 1 after create
      await fetch(resetPage: true);
      return true;
    } catch (e) {
      error = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> update({
    required int id,
    String? name,
    String? description,
    double? price,
    int? categoryId,
    String? imageFilename,
  }) async {
    error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{};

      if (name != null) body['name'] = name.trim();
      if (description != null) {
        body['description'] = description.trim().isEmpty
            ? null
            : description.trim();
      }
      if (price != null) body['price'] = price;
      if (categoryId != null) body['category_id'] = categoryId;
      if (imageFilename != null) {
        body['image_url'] = imageFilename.trim().isEmpty
            ? null
            : imageFilename.trim();
      }

      await _api.put('/products/$id', body: body);

      // stay on same page after update
      await fetch(pageOverride: page);
      return true;
    } catch (e) {
      error = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(int id) async {
    error = null;
    notifyListeners();

    // optimistic remove from current page list
    final idx = items.indexWhere((p) => p.id == id);
    Product? backup;
    if (idx != -1) {
      backup = items.removeAt(idx);
      notifyListeners();
    }

    try {
      await _api.delete('/products/$id');

      // if page becomes empty after delete, go back one page
      if (items.isEmpty && page > 1) {
        page -= 1;
      }
      await fetch(pageOverride: page);
      return true;
    } catch (e) {
      if (backup != null && idx != -1) {
        items.insert(idx, backup);
        notifyListeners();
      }
      error = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  // ----------------------------
  // IMAGE UPLOAD
  // ----------------------------
  Future<String?> uploadImage(File file) async {
    error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$API_BASE_URL/uploads');
      final request = http.MultipartRequest('POST', uri);

      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {}

      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        final filename = data['filename'] as String?;
        if (filename == null || filename.trim().isEmpty) {
          error = 'Upload succeeded but filename missing';
          notifyListeners();
          return null;
        }
        return filename.trim();
      }

      error = (data['message']?.toString() ?? 'Upload failed');
      notifyListeners();
      return null;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ----------------------------
  // FILTERS
  // ----------------------------

  void setSearch(String text) {
    search = text;
  }

  void setCategory(int? id) {
    categoryId = id;
    fetch(resetPage: true);
  }

  void setSort({required String by, required String dir}) {
    sortBy = by;
    order = dir;
    fetch(resetPage: true);
  }
}
