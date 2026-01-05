import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/chat_list_page.dart';

class LoginPasswordPage extends StatefulWidget {
  const LoginPasswordPage({super.key});

  @override
  State<LoginPasswordPage> createState() => _LoginPasswordPageState();
}

class _LoginPasswordPageState extends State<LoginPasswordPage> {
  final TextEditingController _phoneOrEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  /// IMPORTANT:
  /// - Android Emulator: http://10.0.2.2:3001
  /// - Máy thật: http://<IP_MÁY_MAC>:3001 (vd: http://172.16.1.105:3001)
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://172.16.1.21:3001",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  );

  String _normalizeIdentifier(String raw) {
    final s = raw.trim();

    // VN phone: 0xxxxxxxxx -> +84xxxxxxxxx
    if (RegExp(r'^0\d{9}$').hasMatch(s)) {
      return '+84${s.substring(1)}';
    }

    // 84xxxxxxxxx -> +84xxxxxxxxx
    if (RegExp(r'^84\d{9}$').hasMatch(s)) {
      return '+$s';
    }

    return s; // email | username | +84...
  }

  Future<void> _saveTokenAndGoChatList(
      String token,
      Map<String, dynamic> user,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('accessToken', token);
    await prefs.setString('userId', user['id']); // ⭐ QUAN TRỌNG
    await prefs.setString('username', user['username'] ?? '');
    await prefs.setString('email', user['email'] ?? '');

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ChatListPage()),
          (route) => false,
    );
  }


  Future<void> _onLogin() async {
    if (_loading) return;

    final rawId = _phoneOrEmailController.text;
    final password = _passwordController.text;

    if (rawId.trim().isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ')),
      );
      return;
    }

    final identifier = _normalizeIdentifier(rawId);

    setState(() => _loading = true);

    try {
      debugPrint('➡️ LOGIN REQUEST');
      debugPrint('identifier = $identifier');
      debugPrint('password   = $password');

      final res = await _dio.post(
        "/auth/login/password",
        data: {
          "identifier": identifier,
          "password": password,
        },
      );

      debugPrint('✅ STATUS: ${res.statusCode}');
      debugPrint('✅ BODY: ${res.data}');

      final data = res.data;
      final token = data['accessToken'];
      final user  = data['user'];

      if (token == null) {
        throw Exception("Không có accessToken");
      }

      await _saveTokenAndGoChatList(token,user);
    } on DioException catch (e) {
      debugPrint('❌ LOGIN ERROR');
      debugPrint('STATUS: ${e.response?.statusCode}');
      debugPrint('BODY: ${e.response?.data}');
      debugPrint('MSG: ${e.message}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login fail: ${e.response?.data ?? e.message}")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  void dispose() {
    _phoneOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Đăng nhập bằng mật khẩu',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Email / Username / Số điện thoại',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneOrEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'tram1@gmail.com hoặc tram1 hoặc 0909xxxxxx',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primarySoft),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mật khẩu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Nhập mật khẩu',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primarySoft),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.4,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Quên mật khẩu
                  },
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _onLogin,
                  child: Text(
                    _loading ? 'Đang đăng nhập...' : 'ĐĂNG NHẬP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Hoặc quay lại đăng nhập bằng OTP',
                  style: AppTextStyles.legalText,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
