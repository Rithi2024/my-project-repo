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
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await context.read<CategoryProvider>().fetch();
      await context.read<ProductProvider>().resetAndFetch();
    });

    _scroll.addListener(() {
      final p = context.read<ProductProvider>();
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        p.fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _debouncer.dispose();
    _scroll.dispose();
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

    final cats = context.read<CategoryProvider>().items;
    int? selectedCategoryId =
        product?.categoryId ?? (cats.isNotEmpty ? cats.first.id : null);

    File? pickedImage; // local picked image (phone/pc)

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

                      // IMAGE PICK
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

                      // PREVIEW
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

                    // upload image first (if selected)
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
                        imageFilename: filename, // only changes if picked
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
                        _debouncer.run(
                          () => context.read<ProductProvider>().resetAndFetch(),
                        );
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
                      value: prodProv.categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...catProv.items.map(
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
              : ListView.builder(
                  controller: _scroll,
                  itemCount:
                      prodProv.items.length + (prodProv.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= prodProv.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final p = prodProv.items[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: (p.imageUrl ?? '').trim(),
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Image.asset(
                                'assets/images/no_image.png',
                                fit: BoxFit.cover,
                              ),
                              errorWidget: (_, __, ___) => Image.asset(
                                'assets/images/no_image.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          '${p.categoryName ?? ''}\n${p.description ?? ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: SizedBox(
                          width: 110,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${p.price.toStringAsFixed(2)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 34,
                                      height: 34,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () =>
                                        _openProductDialog(product: p),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 34,
                                      height: 34,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () => _confirmDeleteProduct(p),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
