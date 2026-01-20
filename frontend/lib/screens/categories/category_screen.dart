import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/debouncer.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../widgets/loading.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _search = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<CategoryProvider>().fetch(resetPage: true),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteCategory(Category c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Are you sure you want to delete "${c.name}"?'),
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

    final ok = await context.read<CategoryProvider>().remove(c.id);
    if (!mounted) return;

    if (!ok) {
      final err = context.read<CategoryProvider>().error ?? 'Delete failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category deleted')));
    }
  }

  Future<void> _openDialog({Category? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Create Category' : 'Edit Category'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final n = nameCtrl.text.trim();
              if (n.isEmpty) return;

              bool ok;
              final prov = context.read<CategoryProvider>();

              if (existing == null) {
                ok = await prov.create(
                  name: n,
                  description: descCtrl.text.trim(),
                );
              } else {
                ok = await prov.update(
                  id: existing.id,
                  name: n,
                  description: descCtrl.text.trim(),
                );
              }

              if (!context.mounted) return;

              if (ok) {
                Navigator.pop(ctx);
              } else {
                final err = prov.error ?? 'Failed';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(err)));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CategoryProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Search categories (Khmer/English)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _debouncer.run(() {
                    context.read<CategoryProvider>().fetch(
                      search: v,
                      resetPage: true,
                    );
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _openDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                  const SizedBox(width: 10),
                  if (prov.error != null)
                    Expanded(
                      child: Text(
                        prov.error!,
                        style: const TextStyle(color: Colors.red),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: prov.isLoading && prov.items.isEmpty
              ? const Loading()
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => context.read<CategoryProvider>().fetch(
                          search: _search.text.trim(),
                          resetPage: true,
                        ),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: prov.items.length,
                          itemBuilder: (context, index) {
                            final c = prov.items[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(c.name),
                                subtitle: (c.description ?? '').trim().isEmpty
                                    ? null
                                    : Text(c.description ?? ''),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _openDialog(existing: c),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _confirmDeleteCategory(c),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Pagination bar
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
                            onPressed: (prov.hasPrev && !prov.isLoading)
                                ? () => context
                                      .read<CategoryProvider>()
                                      .prevPage()
                                : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Previous'),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Page ${prov.page} / ${prov.totalPages}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: (prov.hasNext && !prov.isLoading)
                                ? () => context
                                      .read<CategoryProvider>()
                                      .nextPage()
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
