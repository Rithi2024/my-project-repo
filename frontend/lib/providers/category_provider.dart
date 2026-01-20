import 'package:flutter/foundation.dart' hide Category;
import '../core/api/api_client.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider({required ApiClient api}) : _api = api;

  final ApiClient _api;

  final List<Category> _items = [];
  List<Category> get items => List.unmodifiable(_items);

  bool isLoading = false;
  String? error;

  String _lastSearch = '';

  int _page = 1;
  final int _limit = 10;

  int total = 0;
  int totalPages = 1;

  int get page => _page;
  int get limit => _limit;

  bool get hasPrev => _page > 1;
  bool get hasNext => _page < totalPages;

  Future<void> fetch({
    String? search,
    int? page,
    bool resetPage = false,
  }) async {
    final s = (search ?? _lastSearch).trim();
    _lastSearch = s;

    if (resetPage) _page = 1;
    if (page != null) _page = page;

    if (isLoading) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final query = <String, String>{'page': '$_page', 'limit': '$_limit'};
      if (s.isNotEmpty) query['search'] = s;

      final res = await _api.get('/categories', query: query);

      // ✅ backend returns { data: [...], paging: { total, totalPages }, page, limit }
      final list = (res['data'] as List).cast<dynamic>();
      final paging = (res['paging'] as Map<String, dynamic>?);

      total = (paging?['total'] as int?) ?? list.length;
      totalPages = (paging?['totalPages'] as int?) ?? 1;

      final newItems = list
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();

      _items
        ..clear()
        ..addAll(newItems);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error = _cleanError(e);
      notifyListeners();
    }
  }

  Future<void> nextPage() async {
    if (!hasNext) return;
    await fetch(page: _page + 1);
  }

  Future<void> prevPage() async {
    if (!hasPrev) return;
    await fetch(page: _page - 1);
  }

  Future<bool> create({required String name, String? description}) async {
    error = null;
    notifyListeners();

    try {
      await _api.post(
        '/categories',
        body: {
          'name': name.trim(),
          'description': (description ?? '').trim().isEmpty
              ? null
              : description!.trim(),
        },
      );

      await fetch(search: _lastSearch, resetPage: true);
      return true;
    } catch (e) {
      error = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> update({
    required int id,
    required String name,
    String? description,
  }) async {
    error = null;
    notifyListeners();

    try {
      await _api.put(
        '/categories/$id',
        body: {
          'name': name.trim(),
          'description': (description ?? '').trim().isEmpty
              ? null
              : description!.trim(),
        },
      );

      await fetch(search: _lastSearch, page: _page);
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

    final idx = _items.indexWhere((c) => c.id == id);
    Category? backup;
    if (idx != -1) {
      backup = _items.removeAt(idx);
      notifyListeners();
    }

    try {
      await _api.delete('/categories/$id');

      // if page becomes empty, go back a page
      if (_items.isEmpty && _page > 1) _page -= 1;

      await fetch(search: _lastSearch, page: _page);
      return true;
    } catch (e) {
      if (backup != null && idx != -1) {
        _items.insert(idx, backup);
        notifyListeners();
      }
      error = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  String _cleanError(Object e) {
    final text = e.toString();
    return text.startsWith('ApiException')
        ? text.replaceFirst(RegExp(r'^ApiException\(\d+\):\s*'), '')
        : text;
  }

  void reset() {
    _items.clear(); // NOT items.clear()
    isLoading = false;
    error = null;
    _lastSearch = '';
    _page = 1;
    total = 0;
    totalPages = 1;
    notifyListeners();
  }
}
