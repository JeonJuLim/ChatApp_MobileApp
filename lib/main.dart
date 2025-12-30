import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:minichatappmobile/core/theme/app_appearance.dart';
import 'package:minichatappmobile/core/theme/theme_builder.dart';

import 'package:minichatappmobile/features/auth/presentation/pages/welcome_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/chat_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('isLoggedIn');
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  final appearance = AppAppearance();
  await appearance.load(); // LOAD setting giao diện đã lưu

  runApp(
    ChangeNotifierProvider.value(
      value: appearance,
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

      // APPLY THEME
      theme: ThemeBuilder.light(a),
      darkTheme: ThemeBuilder.dark(a),
      themeMode: a.themeMode,

      // APPLY FONT SCALE
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
