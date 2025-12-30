import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthRepository {
  final ApiClient api;
  final TokenStorage storage;

  AuthRepository(this.api, this.storage);

  Future<void> loginEmail(String email, String password) async {
    final res = await api.dio.post(
      '/auth/login-email',
      data: {'email': email, 'password': password},
    );

    await storage.save(res.data['accessToken']);
  }
}
