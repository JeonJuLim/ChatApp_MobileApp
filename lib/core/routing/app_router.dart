import 'package:flutter/material.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/login_page.dart';
// sau này import thêm chat_list_page

import 'app_routes.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    // case AppRoutes.chatList:
    //   return MaterialPageRoute(builder: (_) => const ChatListPage());
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
