import 'package:dio/dio.dart';
import 'package:minichatappmobile/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;

  /// Bật debug khi cần (true), xong tắt (false) để sạch log
  final bool debug;

  AuthInterceptor(this.tokenStorage, {this.debug = false});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await tokenStorage.read();

      if (debug) {
        // ignore: avoid_print
        print('[AUTH] ${options.method} ${options.uri} '
            'token=${token == null ? "NULL" : "LEN=${token.length}"}');
      }

      if (token != null && token.trim().isNotEmpty) {
        options.headers['Authorization'] = 'Bearer ${token.trim()}';
      }

      if (debug) {
        // ignore: avoid_print
        print('[AUTH] Authorization=${options.headers['Authorization'] != null ? "SET" : "NOT_SET"}');
      }
    } catch (e) {
      if (debug) {
        // ignore: avoid_print
        print('[AUTH] read token error: $e');
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (debug) {
      // ignore: avoid_print
      print('[DIO] ERROR ${err.requestOptions.method} ${err.requestOptions.uri}');
      // ignore: avoid_print
      print('[DIO] STATUS ${err.response?.statusCode}');
      // ignore: avoid_print
      print('[DIO] DATA ${err.response?.data}');
    }
    handler.next(err);
  }
}
