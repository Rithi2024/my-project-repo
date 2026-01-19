// ignore_for_file: unnecessary_underscores

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../config.dart';
import '../services/category_service.dart';
import '../services/local_image_cache.dart';
import '../services/product_service.dart';
import 'product_form_dialog.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _productService = ProductService();
  final _categoryService = CategoryService();

  final _imgCache = LocalImageCache();
  final Set<String> _downloading = {};

  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loadingFirst = true;
  bool _loadingMore = false;
  String? _error;

  List<dynamic> _products = [];
  List<dynamic> _categories = [];

  int _page = 1;
  final int _limit = 20;
  int _totalPages = 1;

  int? _selectedCategoryId;
  String _sortBy = "name"; // name|price
  String _order = "asc"; // asc|desc
  String _search = "";

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFirstPage();

    _scrollCtrl.addListener(() {
      final nearBottom =
          _scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200;
      if (nearBottom) _loadMore();
    });
  }

  // -----------------------------
  // CRUD
  // -----------------------------

  Future<void> _createProduct() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please create categories first.")),
      );
      return;
    }

    final form = await showProductFormDialog(
      context: context,
      categories: _categories,
      existingProduct: null,
    );
    if (form == null) return;

    final err = await _productService.createProduct({
      "name": form.name,
      "description": form.description,
      "category_id": form.categoryId,
      "price": form.price,
      "image_url": form.imageUrl.isEmpty ? null : form.imageUrl,
    });

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Product created")));
      await _loadFirstPage();
    }
  }

  Future<void> _editProduct(dynamic p) async {
    if (_categories.isEmpty) return;

    final form = await showProductFormDialog(
      context: context,
      categories: _categories,
      existingProduct: p,
    );
    if (form == null) return;

    final err = await _productService.updateProduct(p["id"], {
      "name": form.name,
      "description": form.description,
      "price": form.price,
      "image_url": form.imageUrl.isEmpty ? null : form.imageUrl,
      "category_id": form.categoryId,
    });

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Product updated")));
      await _loadFirstPage();
    }
  }

  Future<void> _deleteProduct(dynamic p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text("Delete '${p["name"]}' ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final err = await _productService.deleteProduct(p["id"]);

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Product deleted")));
      await _loadFirstPage();
    }
  }

  // -----------------------------
  // Load categories/products
  // -----------------------------

  Future<void> _loadCategories() async {
    try {
      final cats = await _categoryService.getCategories();
      setState(() => _categories = cats);
    } catch (_) {
      // optional
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loadingFirst = true;
      _error = null;
      _page = 1;
      _totalPages = 1;
      _products = [];
    });

    try {
      final res = await _productService.getProducts(
        page: 1,
        limit: _limit,
        search: _search,
        categoryId: _selectedCategoryId,
        sortBy: _sortBy,
        order: _order,
      );

      final paging = res["paging"] as Map<String, dynamic>;
      final data = res["data"] as List<dynamic>;

      setState(() {
        _products = data;
        _totalPages = (paging["total_pages"] as num).toInt();
      });
    } catch (e) {
      setState(() => _error = "Failed to load products");
    }

    if (mounted) setState(() => _loadingFirst = false);
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    if (_loadingFirst) return;
    if (_page >= _totalPages) return;

    setState(() => _loadingMore = true);

    try {
      final nextPage = _page + 1;
      final res = await _productService.getProducts(
        page: nextPage,
        limit: _limit,
        search: _search,
        categoryId: _selectedCategoryId,
        sortBy: _sortBy,
        order: _order,
      );

      final data = res["data"] as List<dynamic>;

      setState(() {
        _page = nextPage;
        _products.addAll(data);
      });
    } catch (_) {
      // ignore
    }

    if (mounted) setState(() => _loadingMore = false);
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _search = value);
      _loadFirstPage();
    });
  }

  // -----------------------------
  // Image local caching with version
  // -----------------------------

  String _resolveImageUrl(String? imageUrl, String version) {
    if (imageUrl == null || imageUrl.isEmpty) return "";
    final base = imageUrl.startsWith("http")
        ? imageUrl
        : (AppConfig.baseUrl + imageUrl);
    return "$base?v=${Uri.encodeComponent(version)}";
  }

  Widget _productImage(dynamic p) {
    final int id = p["id"];
    final String? raw = p["image_url"];
    final String? updatedAt = p["updated_at"]?.toString();

    final String version = (updatedAt == null || updatedAt.isEmpty)
        ? "0"
        : updatedAt;

    final String url = _resolveImageUrl(raw, version);
    if (url.isEmpty) return const Icon(Icons.image_not_supported);

    return FutureBuilder<File?>(
      future: _imgCache.getLocalIfExists(id, version),
      builder: (context, snap) {
        final file = snap.data;

        if (file != null) {
          return Image.file(file, fit: BoxFit.cover);
        }

        // schedule download after frame (prevents "Build scheduled during frame")
        final key = "$id|$version";
        if (!_downloading.contains(key)) {
          _downloading.add(key);

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await _imgCache.downloadAndSave(id, version, url);
              await _imgCache.cleanupOldVersions(id, version);
            } finally {
              _downloading.remove(key);
            }
            if (mounted) setState(() {});
          });
        }

        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // -----------------------------
  // UI
  // -----------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Products"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _categories.isEmpty ? null : _createProduct,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search products (Khmer/English)...",
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    // ignore: deprecated_member_use
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: "Category",
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("All"),
                      ),
                      ..._categories.map((c) {
                        return DropdownMenuItem<int?>(
                          value: c["id"] as int,
                          child: Text(c["name"] ?? ""),
                        );
                        // ignore: unnecessary_to_list_in_spreads
                      }).toList(),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedCategoryId = val);
                      _loadFirstPage();
                    },
                  ),
                ),
                const SizedBox(width: 12),

                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: "name", child: Text("Name")),
                    DropdownMenuItem(value: "price", child: Text("Price")),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _sortBy = v);
                    _loadFirstPage();
                  },
                ),

                IconButton(
                  onPressed: () {
                    setState(() => _order = _order == "asc" ? "desc" : "asc");
                    _loadFirstPage();
                  },
                  icon: Icon(
                    _order == "asc" ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_loadingFirst) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFirstPage,
                child: ListView.builder(
                  controller: _scrollCtrl,
                  itemCount: _products.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _products.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _loadingMore
                              ? const CircularProgressIndicator()
                              : Text(
                                  _page >= _totalPages ? "No more data" : "",
                                ),
                        ),
                      );
                    }

                    final p = _products[index];

                    return Card(
                      child: ListTile(
                        leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _productImage(p),
                          ),
                        ),
                        title: Text(p["name"] ?? ""),
                        subtitle: Text(
                          "Category: ${p["category_name"] ?? ""}\nPrice: \$${p["price"]}",
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 6,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editProduct(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteProduct(p),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
