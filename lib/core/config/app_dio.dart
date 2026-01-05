import 'package:dio/dio.dart';
import 'package:minichatappmobile/core/config/app_config.dart';

class AppDio {
  AppDio._();

  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl, // ✅ luôn lấy từ AppConfig
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}
