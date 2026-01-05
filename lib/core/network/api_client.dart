import 'package:dio/dio.dart';
import 'package:minichatappmobile/core/network/auth_interceptor.dart';
import 'package:minichatappmobile/core/storage/token_storage.dart';
import 'package:minichatappmobile/core/config/app_config.dart';
class ApiClient {
  final Dio dio;

  ApiClient(TokenStorage tokenStorage)
      : dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      // Android Emulator
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  ) {
    dio.interceptors.add(AuthInterceptor(tokenStorage));
  }
}
