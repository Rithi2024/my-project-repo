import 'package:flutter/material.dart';
import 'package:frontend/providers/category_provider.dart';
import 'package:frontend/providers/product_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../categories/category_screen.dart';
import '../products/product_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [CategoryScreen(), ProductListScreen()];

    return Scaffold(
      appBar: AppBar(
        title: Text(index == 0 ? 'Categories' : 'Products'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // capture context-safe references BEFORE awaiting (best practice)
              final auth = context.read<AuthProvider>();
              final cat = context.read<CategoryProvider>();
              final prod = context.read<ProductProvider>();

              await auth.logout();
              if (!context.mounted) return;

              cat.reset();
              prod.reset();

              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (_) => false);
            },
          ),
        ],
      ),

      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
        ],
      ),
    );
  }
}
