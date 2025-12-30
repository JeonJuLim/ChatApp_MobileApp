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

  // ANDROID EMULATOR: 10.0.2.2 (không dùng localhost)
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://10.0.2.2:3001",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  );

  bool _isEmail(String input) {
    // đủ dùng cho case login email
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input);
  }

  Future<void> _saveTokenAndGoChatList(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('accessToken', token);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ChatListPage()),
          (route) => false,
    );
  }

  Future<void> _onLogin() async {
    final id = _phoneOrEmailController.text.trim();
    final password = _passwordController.text;

    if (id.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ tài khoản và mật khẩu')),
      );
      return;
    }

    // Hiện tại backend bạn đã làm chắc chắn cho EMAIL (non-OTP).
    // Phone+password chỉ chạy khi backend có endpoint riêng.
    if (!_isEmail(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hiện tại chỉ hỗ trợ đăng nhập bằng EMAIL + mật khẩu.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await _dio.post(
        "/auth/login-email",
        data: {"email": id, "password": password},
      );

      final token = res.data["accessToken"] as String;
      await _saveTokenAndGoChatList(token);
    } on DioException catch (e) {
      final msg = e.response?.data is Map && (e.response?.data["message"] != null)
          ? e.response?.data["message"].toString()
          : e.message ?? "Unknown error";

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng nhập thất bại: $msg")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng nhập thất bại: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
                'Số điện thoại hoặc email',
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
                  hintText: 'Nhập email (ví dụ: test1@gmail.com)',
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
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
