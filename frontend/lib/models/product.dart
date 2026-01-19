import 'package:frontend/core/constants.dart';

class Product {
  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.categoryId,
    this.categoryName,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String? description;
  final double price;
  final int categoryId;
  final String? categoryName;
  final String? imageUrl;

  factory Product.fromJson(Map<String, dynamic> j) {
    final filename = (j['image_url'] as String?)?.trim();
    final fullUrl = (filename == null || filename.isEmpty)
        ? null
        : '$SERVER_BASE_URL/images/$filename';

    return Product(
      id: (j['id'] ?? 0) as int,
      name: (j['name'] ?? '') as String,
      description: j['description'] as String?,
      price: (j['price'] is num)
          ? (j['price'] as num).toDouble()
          : double.tryParse(j['price']?.toString() ?? '0') ?? 0.0,
      categoryId: (j['category_id'] ?? 0) as int,
      categoryName: j['category_name'] as String?,
      imageUrl: fullUrl,
    );
  }
}
