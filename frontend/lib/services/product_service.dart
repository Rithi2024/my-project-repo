import 'dart:convert';
import 'api_client.dart';

class ProductService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getProducts({
    required int page,
    int limit = 20,
    String search = "",
    int? categoryId,
    String sortBy = "name", // name|price
    String order = "asc", // asc|desc
  }) async {
    final params = <String, String>{
      "page": page.toString(),
      "limit": limit.toString(),
      "sort_by": sortBy,
      "order": order,
    };

    if (search.trim().isNotEmpty) {
      params["search"] = search.trim();
    }
    if (categoryId != null) {
      params["category_id"] = categoryId.toString();
    }

    final uri = Uri(path: "/api/products", queryParameters: params);
    final res = await _api.get(uri.toString());

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw Exception("Failed to load products");
  }

  Future<String?> createProduct(Map<String, dynamic> body) async {
    final res = await _api.post("/api/products", body, auth: true);
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 || res.statusCode == 200) return null;
    return data["message"] ?? "Create failed";
  }

  Future<String?> updateProduct(int id, Map<String, dynamic> body) async {
    final res = await _api.put("/api/products/$id", body, auth: true);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return null;
    return data["message"] ?? "Update failed";
  }

  Future<String?> deleteProduct(int id) async {
    final res = await _api.delete("/api/products/$id", auth: true);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return null;
    return data["message"] ?? "Delete failed";
  }
}
