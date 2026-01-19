import 'dart:convert';
import 'api_client.dart';

class CategoryService {
  final ApiClient _api = ApiClient();

  Future<List<dynamic>> getCategories({String search = ""}) async {
    final q = search.trim().isEmpty
        ? ""
        : "?search=${Uri.encodeComponent(search.trim())}";
    final res = await _api.get("/api/categories$q");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["data"] as List<dynamic>;
    }
    throw Exception("Failed to load categories");
  }

  Future<String?> createCategory(String name, String description) async {
    final res = await _api.post("/api/categories", {
      "name": name,
      "description": description,
    }, auth: true);

    final data = jsonDecode(res.body);
    if (res.statusCode == 201 || res.statusCode == 200) return null;

    return data["message"] ?? "Create failed";
  }

  Future<String?> updateCategory(
    int id,
    String name,
    String description,
  ) async {
    final res = await _api.put("/api/categories/$id", {
      "name": name,
      "description": description,
    }, auth: true);

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return null;

    return data["message"] ?? "Update failed";
  }

  Future<String?> deleteCategory(int id) async {
    final res = await _api.delete("/api/categories/$id", auth: true);

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return null;

    return data["message"] ?? "Delete failed";
  }
}
