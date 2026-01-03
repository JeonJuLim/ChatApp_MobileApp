import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDio {
  AppDio._();

  static String _baseUrl() {
    // ✅ ANDROID EMULATOR: gọi về máy host
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';

    // ✅ iOS Simulator
    if (Platform.isIOS) return 'http://127.0.0.1:3000';

    return 'http://127.0.0.1:3000';
  }

  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: _baseUrl(),
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // ✅ log để debug URL
        // ignore: avoid_print
        print('DIO -> ${options.method} ${options.baseUrl}${options.path}');

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        // ignore: avoid_print
        print('DIO ERROR -> ${e.type} ${e.message}');
        return handler.next(e);
      },
    ),
  );
}
