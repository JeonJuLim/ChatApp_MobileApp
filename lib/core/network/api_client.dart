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
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  ) {
    // Bật log request/response để chốt lỗi khi cần
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    // Auth interceptor (đặt debug=true nếu bạn muốn xem token + headers)
    dio.interceptors.add(AuthInterceptor(tokenStorage, debug: true));
  }
}
