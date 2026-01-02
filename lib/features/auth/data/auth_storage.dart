import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _kIsLoggedIn = 'isLoggedIn';
  static const _kAccessToken = 'accessToken';

  Future<void> saveLogin(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, true);
    await prefs.setString(_kAccessToken, accessToken);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsLoggedIn);
    await prefs.remove(_kAccessToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccessToken);
  }
}
