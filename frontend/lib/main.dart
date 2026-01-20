import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/product_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = ApiClient(baseUrl: API_BASE_URL);

  // ✅ IMPORTANT: load token into ApiClient memory before any request
  await api.initTokenFromStorage();

  runApp(MyApp(api: api));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api: api)..init()),
        ChangeNotifierProvider(create: (_) => CategoryProvider(api: api)),
        ChangeNotifierProvider(create: (_) => ProductProvider(api: api)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter CRUD',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Khmer',
          textTheme: const TextTheme(
            bodyMedium: TextStyle(height: 1.35),
            bodyLarge: TextStyle(height: 1.35),
            titleMedium: TextStyle(height: 1.35),
          ),
        ),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeShell(),
        },
        home: const _Gate(),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isLoggedIn ? const HomeShell() : const LoginScreen();
  }
}
