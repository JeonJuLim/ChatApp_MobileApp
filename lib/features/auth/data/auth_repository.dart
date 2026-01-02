import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthRepository {
  final ApiClient api;
  final TokenStorage storage;

  AuthRepository(this.api, this.storage);

  Future<void> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    final res = await api.dio.post(
      '/auth/login/password',
      data: {
        'identifier': _normalizeIdentifier(identifier),
        'password': password,
      },
    );

    final data = res.data;
    final token = (data is Map) ? data['accessToken']?.toString() : null;

    if (token == null || token.isEmpty) {
      throw Exception('Server không trả accessToken');
    }

    await storage.save(token);
  }

  // ===== THÊM HÀM NÀY =====
  String _normalizeIdentifier(String raw) {
    final s = raw.trim();

    // 0xxxxxxxxx -> +84xxxxxxxxx
    if (RegExp(r'^0\d{9}$').hasMatch(s)) {
      return '+84${s.substring(1)}';
    }

    // 84xxxxxxxxx -> +84xxxxxxxxx
    if (RegExp(r'^84\d{9}$').hasMatch(s)) {
      return '+$s';
    }

    return s; // email | username | +84...
  }
}
