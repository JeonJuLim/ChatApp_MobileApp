import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:minichatappmobile/core/theme/app_appearance.dart';
import 'package:minichatappmobile/core/theme/theme_builder.dart';
import 'package:minichatappmobile/core/network/app_dio.dart';

import 'package:minichatappmobile/features/auth/presentation/pages/welcome_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/chat_list_page.dart';

import 'package:minichatappmobile/features/friends/data/repositories/friends_repository.dart';
import 'package:minichatappmobile/features/friends/presentation/providers/friends_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appearance = AppAppearance();
  await appearance.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppAppearance>.value(value: appearance),
        ChangeNotifierProvider(
          create: (_) => FriendsProvider(
            FriendsRepository(AppDio.instance),
          )..load(),
        ),
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
    final prefs = await SharedPreferences.getInstance();

    const tokenKey = 'accessToken'; // 🔴 đổi nếu key bạn khác
    final token = prefs.getString(tokenKey);

    if (token == null || token.isEmpty) {
      return false;
    }

    // attach token cho Dio
    final dio = AppDio.instance;
    dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      // 🔴 đổi endpoint nếu backend bạn khác
      await dio.get('/auth/me');
      return true;
    } catch (_) {
      // token không hợp lệ → logout
      dio.options.headers.remove('Authorization');
      await prefs.remove(tokenKey);
      await prefs.remove('isLoggedIn');
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
          return const ChatListPage();
        }

        return const WelcomePage();
      },
    );
  }
}
