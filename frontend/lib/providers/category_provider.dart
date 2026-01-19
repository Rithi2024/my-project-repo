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

  Future<void> fetch({String? search}) async {
    final s = (search ?? _lastSearch).trim();
    _lastSearch = s;

    if (isLoading) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final query = <String, String>{};
      if (s.isNotEmpty) query['search'] = s;

      final res = await _api.get('/categories', query: query);

      // ✅ backend returns { data: [...] }
      final list = (res['data'] as List).cast<dynamic>();

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

      await fetch(search: _lastSearch);
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

      await fetch(search: _lastSearch);
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

    // Optional: optimistic remove
    final index = _items.indexWhere((c) => c.id == id);
    Category? removed;
    if (index != -1) {
      removed = _items.removeAt(index);
      notifyListeners();
    }

    try {
      await _api.delete('/categories/$id');
      return true;
    } catch (e) {
      // rollback if delete failed
      if (removed != null) {
        _items.insert(index, removed);
        notifyListeners();
      }
      error = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  String _cleanError(Object e) {
    // If your ApiClient throws ApiException(message), you can detect it
    final text = e.toString();
    return text.startsWith('ApiException')
        ? text.replaceFirst(RegExp(r'^ApiException\(\d+\):\s*'), '')
        : text;
  }
}
