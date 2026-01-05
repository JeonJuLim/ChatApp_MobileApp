import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:minichatappmobile/core/theme/app_appearance.dart';
import 'package:minichatappmobile/core/theme/theme_builder.dart';
import 'package:minichatappmobile/core/network/app_dio.dart';
import 'package:minichatappmobile/core/storage/token_storage.dart';
import 'package:minichatappmobile/core/network/auth_interceptor.dart';

import 'package:minichatappmobile/features/auth/presentation/pages/welcome_page.dart';
// import ChatListPage nếu vẫn dùng chat list
// import 'package:minichatappmobile/features/auth/presentation/pages/chat_list_page.dart';

// ✅ import trực tiếp UI contacts page mới
import 'package:minichatappmobile/features/friends/contacts_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appearance = AppAppearance();
  await appearance.load();

  final tokenStorage = TokenStorage();
  final dio = AppDio.instance;

  dio.interceptors.removeWhere((i) => i is AuthInterceptor);
  dio.interceptors.add(AuthInterceptor(tokenStorage));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppAppearance>.value(value: appearance),
        Provider<TokenStorage>.value(value: tokenStorage),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AppAppearance>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeBuilder.light(a),
      darkTheme: ThemeBuilder.dark(a),
      themeMode: a.themeMode,
      builder: (context, child) {
        final scale = ThemeBuilder.textScale(a.fontScale);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        );
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _future;

  @override
  void initState() {
    super.initState();
    _future = _checkAuth();
  }

  Future<bool> _checkAuth() async {
    final storage = context.read<TokenStorage>();
    final token = await storage.read();

    if (token == null || token.trim().isEmpty) return false;

    try {
      await AppDio.instance.get('/auth/me');
      return true;
    } catch (_) {
      await storage.clear();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.data == true) {
          // ✅ thay ChatListPage bằng ContactsPage trực tiếp
          return const ContactsPage();
        }

        return const WelcomePage();
      },
    );
  }
}
