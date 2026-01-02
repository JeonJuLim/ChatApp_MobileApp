import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/welcome_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/chat_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String? userId = prefs.getString('userId');

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    userId: userId,
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userId;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn && userId != null
          ? ChatListPage(myUserId: userId!)
          : const WelcomePage(),
    );
  }
}

