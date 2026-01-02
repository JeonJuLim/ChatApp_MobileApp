import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import '../../data/user_profile.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/login_password_page.dart';


class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late final Dio _dio;
  late Future<UserProfile> _future;

  @override
  void initState() {
    super.initState();

    _dio = Dio(BaseOptions(

      baseUrl: 'http://10.0.2.2:3001',

      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _future = _fetchMe();
  }

  Future<UserProfile> _fetchMe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      throw Exception('Chưa đăng nhập (thiếu accessToken)');
    }

    final res = await _dio.get(
      '/users/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (res.data is! Map<String, dynamic>) {
      throw Exception('Response /users/me không đúng format');
    }

    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('accessToken');
    await prefs.remove('userId');
    await prefs.remove('isLoggedIn');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPasswordPage()),
          (route) => false, // ❌ xoá toàn bộ stack
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trang cá nhân'),
        centerTitle: true,
      ),
      body: FutureBuilder<UserProfile>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Lỗi load profile: ${snap.error}'),
              ),
            );
          }

          final user = snap.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primarySoft,
                  backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(user.fullName, style: AppTextStyles.welcomeTitle),
                const SizedBox(height: 4),
                Text('@${user.username}', style: AppTextStyles.legalText),
                if (user.status != null) ...[
                  const SizedBox(height: 6),
                  Text(user.status!, style: const TextStyle(color: Colors.green)),
                ],
                const SizedBox(height: 24),

                _infoCard('Thông tin tài khoản', [
                  _infoRow('Email', user.email ?? 'Chưa liên kết', verified: user.emailVerified),
                  _infoRow('Số điện thoại', user.phoneE164 ?? 'Chưa liên kết', verified: user.phoneVerified),
                  _infoRow('Auth provider', user.authProvider),
                ]),
                const SizedBox(height: 16),
                _infoCard('Hệ thống', [
                  _infoRow('Ngày tạo', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
                ]),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Đăng xuất',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Đăng xuất'),
                          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Huỷ'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Đăng xuất'),
                            ),
                          ],
                        ),
                      );

                      if (ok == true) {
                        await _logout();
                      }
                    },
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool? verified}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: AppTextStyles.legalText)),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Flexible(child: Text(value)),
                if (verified != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    verified ? Icons.check_circle : Icons.error_outline,
                    size: 16,
                    color: verified ? Colors.green : Colors.orange,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
