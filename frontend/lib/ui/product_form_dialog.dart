import 'package:flutter/material.dart';

class ProductFormResult {
  final String name;
  final String description;
  final int categoryId;
  final double price;
  final String imageUrl;

  ProductFormResult({
    required this.name,
    required this.description,
    required this.categoryId,
    required this.price,
    required this.imageUrl,
  });
}

Future<ProductFormResult?> showProductFormDialog({
  required BuildContext context,
  required List<dynamic> categories,
  dynamic existingProduct, // nullable for create
}) async {
  final nameCtrl = TextEditingController(text: existingProduct?["name"] ?? "");
  final descCtrl = TextEditingController(
    text: existingProduct?["description"] ?? "",
  );
  final priceCtrl = TextEditingController(
    text: existingProduct?["price"]?.toString() ?? "",
  );
  final imageCtrl = TextEditingController(
    text: existingProduct?["image_url"] ?? "",
  );

  int? selectedCategoryId = existingProduct?["category_id"] as int?;
  selectedCategoryId ??= categories.isNotEmpty
      ? (categories[0]["id"] as int)
      : null;

  String? error;

  return showDialog<ProductFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(
          existingProduct == null ? "Create Product" : "Edit Product",
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Name (Khmer/English)",
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                // ignore: deprecated_member_use
                value: selectedCategoryId,
                decoration: const InputDecoration(labelText: "Category"),
                items: categories.map((c) {
                  return DropdownMenuItem<int>(
                    value: c["id"] as int,
                    child: Text(c["name"] ?? ""),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedCategoryId = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: imageCtrl,
                decoration: const InputDecoration(
                  labelText: "Image URL",
                  hintText: "/images/p001.jpg",
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final desc = descCtrl.text.trim();
              final priceText = priceCtrl.text.trim();
              final img = imageCtrl.text.trim();

              if (name.isEmpty) {
                setState(() => error = "Name is required");
                return;
              }
              if (selectedCategoryId == null) {
                setState(() => error = "Category is required");
                return;
              }
              final price = double.tryParse(priceText);
              if (price == null || price < 0) {
                setState(() => error = "Price must be a valid number");
                return;
              }

              Navigator.pop(
                ctx,
                ProductFormResult(
                  name: name,
                  description: desc,
                  categoryId: selectedCategoryId!,
                  price: price,
                  imageUrl: img,
                ),
              );
            },
            child: Text(existingProduct == null ? "Create" : "Update"),
          ),
        ],
      ),
    ),
  );
}
