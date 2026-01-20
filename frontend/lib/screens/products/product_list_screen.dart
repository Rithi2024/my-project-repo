import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/debouncer.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/loading.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _search = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await context.read<CategoryProvider>().fetch();
      await context.read<ProductProvider>().resetAndFetch();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteProduct(Product p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Are you sure you want to delete "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await context.read<ProductProvider>().remove(p.id);
    if (!mounted) return;

    if (!ok) {
      final err = context.read<ProductProvider>().error ?? 'Delete failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product deleted')));
    }
  }

  Future<void> _openProductDialog({Product? product}) async {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final priceCtrl = TextEditingController(
      text: product == null ? '' : product!.price.toString(),
    );

    final catsRaw = context.read<CategoryProvider>().items;
    final catsMap = <int, dynamic>{};
    for (final c in catsRaw) {
      catsMap[c.id] = c;
    }
    final cats = catsMap.values.toList();

    int? selectedCategoryId =
        product?.categoryId ?? (cats.isNotEmpty ? cats.first.id : null);

    if (selectedCategoryId != null &&
        !cats.any((c) => c.id == selectedCategoryId)) {
      selectedCategoryId = cats.isNotEmpty ? cats.first.id : null;
    }

    File? pickedImage;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setState) {
            Future<void> pickImage() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                allowMultiple: false,
              );
              if (result == null) return;
              final path = result.files.single.path;
              if (path == null) return;

              setState(() => pickedImage = File(path));
            }

            return AlertDialog(
              title: Text(product == null ? 'Create Product' : 'Edit Product'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: cats
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedCategoryId = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(Icons.photo),
                            label: const Text('Choose Image'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              pickedImage == null
                                  ? (product?.imageUrl == null
                                        ? 'No image'
                                        : 'Keep current image')
                                  : pickedImage!.path
                                        .split(Platform.pathSeparator)
                                        .last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (pickedImage != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            pickedImage!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ] else if (product?.imageUrl != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: product!.imageUrl!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Image.asset(
                              'assets/images/no_image.png',
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            errorWidget: (_, __, ___) => Image.asset(
                              'assets/images/no_image.png',
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/no_image.png',
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.trim());
                    final cid = selectedCategoryId;

                    if (name.isEmpty || price == null || cid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill name, category, valid price',
                          ),
                        ),
                      );
                      return;
                    }

                    String? filename;
                    if (pickedImage != null) {
                      filename = await context
                          .read<ProductProvider>()
                          .uploadImage(pickedImage!);

                      if (!context.mounted) return;

                      if (filename == null) {
                        final err =
                            context.read<ProductProvider>().error ??
                            'Upload failed';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(err)));
                        return;
                      }
                    }

                    bool ok;
                    if (product == null) {
                      ok = await context.read<ProductProvider>().create(
                        name: name,
                        description: descCtrl.text,
                        categoryId: cid,
                        price: price,
                        imageFilename: filename,
                      );
                    } else {
                      ok = await context.read<ProductProvider>().update(
                        id: product!.id,
                        name: name,
                        description: descCtrl.text,
                        categoryId: cid,
                        price: price,
                        imageFilename: filename,
                      );
                    }

                    if (!context.mounted) return;

                    if (ok) {
                      Navigator.pop(dialogCtx);
                    } else {
                      final err =
                          context.read<ProductProvider>().error ??
                          'Save failed';
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catProv = context.watch<CategoryProvider>();
    final prodProv = context.watch<ProductProvider>();

    // dedupe categories for dropdown
    final catMap = <int, dynamic>{};
    for (final c in catProv.items) {
      catMap[c.id] = c;
    }
    final uniqueCats = catMap.values.toList();

    int? safeCategoryId = prodProv.categoryId;
    if (safeCategoryId != null &&
        !uniqueCats.any((c) => c.id == safeCategoryId)) {
      safeCategoryId = null;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        hintText: 'Search products (Khmer/English)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        prodProv.setSearch(v);
                        _debouncer.run(() {
                          context.read<ProductProvider>().resetAndFetch();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _openProductDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: safeCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...uniqueCats.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (id) =>
                          context.read<ProductProvider>().setCategory(id),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: prodProv.sortBy,
                    items: const [
                      DropdownMenuItem(
                        value: 'name',
                        child: Text('Sort: Name'),
                      ),
                      DropdownMenuItem(
                        value: 'price',
                        child: Text('Sort: Price'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      context.read<ProductProvider>().setSort(
                        by: v,
                        dir: prodProv.order,
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Toggle asc/desc',
                    onPressed: () {
                      final newDir = prodProv.order == 'asc' ? 'desc' : 'asc';
                      context.read<ProductProvider>().setSort(
                        by: prodProv.sortBy,
                        dir: newDir,
                      );
                    },
                    icon: Icon(
                      prodProv.order == 'asc'
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
              if (prodProv.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    prodProv.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: prodProv.isLoading && prodProv.items.isEmpty
              ? const Loading()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: prodProv.items.length,
                        itemBuilder: (context, index) {
                          final p = prodProv.items[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: _ProductRow(
                                product: p,
                                onEdit: () => _openProductDialog(product: p),
                                onDelete: () => _confirmDeleteProduct(p),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // pagination (keep your row or change to Wrap if needed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border(
                          top: BorderSide(color: Colors.grey.withOpacity(0.25)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: (prodProv.hasPrev && !prodProv.isLoading)
                                ? () =>
                                      context.read<ProductProvider>().prevPage()
                                : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Previous'),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Page ${prodProv.page} / ${prodProv.totalPages}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: (prodProv.hasNext && !prodProv.isLoading)
                                ? () =>
                                      context.read<ProductProvider>().nextPage()
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Next'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    // give trailing area enough width, but not too big on small screens
    final trailingWidth = w < 380 ? 96.0 : 120.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // image
        SizedBox(
          width: 56,
          height: 56,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: (product.imageUrl ?? '').trim(),
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Image.asset('assets/images/no_image.png', fit: BoxFit.cover),
              errorWidget: (_, __, ___) =>
                  Image.asset('assets/images/no_image.png', fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // title/subtitle area
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                product.categoryName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                product.description ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // trailing actions
        SizedBox(
          width: trailingWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
