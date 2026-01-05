import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minichatappmobile/core/config/app_config.dart';

class AppDio {
  AppDio._();

  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(_AuthInterceptor());
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken'); // đổi nếu bạn lưu key khác

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      // Debug nhanh
      // ignore: avoid_print
      print('DIO REQ -> ${options.method} ${options.uri}');
      // ignore: avoid_print
      print('DIO AUTH -> ${options.headers['Authorization'] ?? 'NOT_SET'}');
    } catch (e) {
      // ignore: avoid_print
      print('DIO AUTH INTERCEPTOR ERROR -> $e');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('DIO ERR -> ${err.requestOptions.method} ${err.requestOptions.uri}');
    // ignore: avoid_print
    print('DIO ERR STATUS -> ${err.response?.statusCode}');
    // ignore: avoid_print
    print('DIO ERR DATA -> ${err.response?.data}');
    // ignore: avoid_print
    print('DIO ERR AUTH -> ${err.requestOptions.headers['Authorization'] ?? 'NOT_SET'}');
    handler.next(err);
  }
}
