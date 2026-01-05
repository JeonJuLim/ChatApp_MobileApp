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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // ✅ Khởi tạo + load trước
  final appearance = AppAppearance();
  await appearance.load();

  runApp(
    MultiProvider(
      providers: [
        // ✅ PROVIDE AppAppearance để MyApp context.watch<AppAppearance>() đọc được
        ChangeNotifierProvider<AppAppearance>.value(value: appearance),

        ChangeNotifierProvider(
          create: (_) => FriendsProvider(
            FriendsRepository(AppDio.instance),
          )..load(),
        ),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

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
      home: isLoggedIn ? const ChatListPage() : const WelcomePage(),
    );
  }
}
