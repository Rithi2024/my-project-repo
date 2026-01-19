class Category {
  Category({required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: (j['id'] ?? 0) as int,
    name: (j['name'] ?? '') as String,
    description: j['description'] as String?,
  );
}
