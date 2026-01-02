import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:minichatappmobile/core/config/app_config.dart';

class AuthApi {
  final http.Client _client;
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  Future<AuthLoginResponse> loginWithPassword({
    required String identifier, // phone/email/username
    required String password,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/auth/login/password');

    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'password': password,
      }),
    );

    final map = _safeJson(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final token = (map['accessToken'] ?? map['token'])?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('Thiếu accessToken từ server');
      }
      return AuthLoginResponse(
        accessToken: token,
        user: map['user'],
      );
    }

    final message = (map['message'] ?? map['error'] ?? 'Đăng nhập thất bại').toString();
    throw Exception(message);
  }

  Map<String, dynamic> _safeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }
}

class AuthLoginResponse {
  final String accessToken;
  final dynamic user; // có thể map user, tuỳ bạn

  AuthLoginResponse({required this.accessToken, this.user});
}
