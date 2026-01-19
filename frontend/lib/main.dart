import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/product_provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';
import 'core/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ApiClient api;

  @override
  void initState() {
    super.initState();

    api = ApiClient(baseUrl: API_BASE_URL);
  }

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
        theme: ThemeData(useMaterial3: true),
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
    if (auth.isLoggedIn) return const HomeShell();
    return const LoginScreen();
  }
}
