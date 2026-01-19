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

  // Pagination / filter
  final int limit = 20;
  int page = 1;

  String search = '';
  int? categoryId;

  String sortBy = 'name'; // name | price
  String order = 'asc'; // asc | desc  (✅ backend uses "order")

  // State
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? error;

  List<Product> items = [];

  String _cleanError(Object e) {
    final s = e.toString();
    return s.replaceFirst(RegExp(r'^ApiException\(\d+\):\s*'), '');
  }

  // ----------------------------
  // LIST / PAGINATION
  // ----------------------------

  Future<void> resetAndFetch() async {
    page = 1;
    hasMore = true;
    items = [];
    notifyListeners();
    await fetchNextPage();
  }

  Future<void> fetchNextPage() async {
    if (!hasMore) return;
    if (isLoadingMore || isLoading) return;

    if (page == 1) {
      isLoading = true;
    } else {
      isLoadingMore = true;
    }
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

      // ✅ backend returns { paging: {...}, data: [...] }
      final res = await _api.get('/products', query: query);

      final list = (res['data'] as List).cast<dynamic>();
      final total = (res['paging']['total'] as int);

      final newItems = list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();

      items.addAll(newItems);

      hasMore = items.length < total;
      page += 1;

      isLoading = false;
      isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      isLoadingMore = false;
      error = _cleanError(e);
      notifyListeners();
    }
  }

  // ----------------------------
  // CRUD
  // ----------------------------

  Future<bool> create({
    required String name,
    String? description,
    required int categoryId,
    required double price,
    String? imageFilename, // filename only (e.g. "a.jpg")
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

      await resetAndFetch();
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
    String? imageFilename, // filename only
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

      await resetAndFetch();
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

    // optimistic remove
    final idx = items.indexWhere((p) => p.id == id);
    Product? backup;
    if (idx != -1) {
      backup = items.removeAt(idx);
      notifyListeners();
    }

    try {
      await _api.delete('/products/$id');
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
  // Backend endpoint: POST /api/uploads
  // multipart field: "image"
  // returns: { filename: "xxx.jpg" }
  //
  // After upload, pass filename to create/update as imageFilename.
  // ----------------------------

  Future<String?> uploadImage(File file) async {
    error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$API_BASE_URL/uploads');
      final request = http.MultipartRequest('POST', uri);

      // If upload route is protected by JWT (optional)
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
    resetAndFetch();
  }

  void setSort({required String by, required String dir}) {
    sortBy = by;
    order = dir;
    resetAndFetch();
  }
}
