import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/debouncer.dart';
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
    Future.microtask(() => context.read<CategoryProvider>().fetch());
  }

  @override
  void dispose() {
    _search.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _openDialog({int? id, String? name, String? desc}) async {
    final nameCtrl = TextEditingController(text: name ?? '');
    final descCtrl = TextEditingController(text: desc ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Create Category' : 'Edit Category'),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final n = nameCtrl.text.trim();
              if (n.isEmpty) return;

              bool ok;
              if (id == null) {
                ok = await context.read<CategoryProvider>().create(
                  name: n,
                  description: descCtrl.text,
                );
              } else {
                ok = await context.read<CategoryProvider>().update(
                  id: id,
                  name: n,
                  description: descCtrl.text,
                );
              }

              if (!context.mounted) return;
              if (ok) {
                Navigator.pop(context);
              } else {
                final err = context.read<CategoryProvider>().error ?? 'Failed';
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
                  _debouncer.run(
                    () => context.read<CategoryProvider>().fetch(search: v),
                  );
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
              : ListView.builder(
                  itemCount: prov.items.length,
                  itemBuilder: (_, i) {
                    final c = prov.items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(c.name),
                        subtitle: Text(c.description ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openDialog(
                                id: c.id,
                                name: c.name,
                                desc: c.description,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final ok = await context
                                    .read<CategoryProvider>()
                                    .remove(c.id);
                                if (!context.mounted) return;
                                if (!ok) {
                                  final err =
                                      context.read<CategoryProvider>().error ??
                                      'Delete failed';
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text(err)));
                                }
                              },
                            ),
                          ],
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
