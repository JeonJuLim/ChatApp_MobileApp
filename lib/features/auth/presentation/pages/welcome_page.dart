import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';

import 'package:minichatappmobile/core/network/api_client.dart';
import 'package:minichatappmobile/core/storage/token_storage.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';

import 'package:minichatappmobile/features/auth/presentation/pages/login_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/Register/register_phone_page.dart';
import 'package:minichatappmobile/features/home/home_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool agree = false;

  final _tokenStorage = TokenStorage();
  late final ApiClient _api;

  bool _googleLoading = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(_tokenStorage);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Điều khoản & Chính sách bảo mật'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('1. Mục đích sử dụng\n',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    'Ứng dụng dùng để gọi điện, nhắn tin và chia sẻ nội dung '
                        'giữa người dùng theo thời gian thực cho mục đích cá nhân, '
                        'không sử dụng cho các hoạt động vi phạm pháp luật.\n\n',
                  ),
                  Text('2. Quyền riêng tư\n',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    'Chúng tôi chỉ thu thập thông tin cần thiết để cung cấp dịch vụ. '
                        'Thông tin tài khoản được bảo mật.\n\n',
                  ),
                  Text('3. Hành vi bị cấm\n',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    'Không được sử dụng ứng dụng để spam, lừa đảo, phát tán nội dung '
                        'vi phạm pháp luật.\n\n',
                  ),
                  Text('4. Thay đổi điều khoản\n',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('Điều khoản có thể được cập nhật theo từng thời điểm.'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loginGoogle() async {
    if (_googleLoading) return;

    if (!agree) {
      _toast('Bạn cần đồng ý Điều khoản & Chính sách trước khi tiếp tục.');
      return;
    }

    setState(() => _googleLoading = true);

    try {
      final google = GoogleSignIn(
        scopes: const ['email'],
        serverClientId:
        '450123478574-kfci7mj8dp1398tdsgpmiet0uiefbdu2.apps.googleusercontent.com',
      );

      await google.signOut(); // reset khi test
      final account = await google.signIn();

      if (account == null) {
        _toast('Bạn đã huỷ đăng nhập Google.');
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        throw Exception('Không lấy được idToken từ Google.');
      }

      // ✅ Call backend: /auth/login-google -> { accessToken, user? }
      final res = await _api.dio.post(
        "/auth/login-google",
        data: {"idToken": idToken},
      );

      final data = res.data;
      if (data is! Map) {
        throw Exception('Response backend không hợp lệ.');
      }

      final accessToken = data["accessToken"];
      if (accessToken is! String || accessToken.isEmpty) {
        throw Exception('Backend không trả accessToken.');
      }

      await _tokenStorage.save(accessToken);

      if (!mounted) return;

      // ✅ Không ép phone: đi thẳng Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on DioException catch (e) {
      _toast(
        e.type == DioExceptionType.connectionError
            ? 'Không kết nối được server (IP/PORT sai hoặc backend chưa chạy)'
            : 'Lỗi gọi API: ${e.message}',
      );
    } on SocketException {
      _toast('Không kết nối được server. Kiểm tra Wi-Fi/IP máy backend.');
    } catch (e) {
      _toast('Google login lỗi: $e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: TopWaveClipper(),
              child: Container(
                height: size.height * 0.52,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.mint, AppColors.primarySoft],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 70),

                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone_in_talk_rounded,
                        size: 55,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),
                  Center(child: Text('Welcome', style: AppTextStyles.welcomeTitle)),
                  const SizedBox(height: 12),

                  const Center(
                    child: Text(
                      'Ứng dụng gọi điện và nhắn tin\nthời gian thực dành cho giới trẻ.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.welcomeSubtitle,
                    ),
                  ),

                  const SizedBox(height: 85),

                  // ✅ NÚT 1: Đăng nhập (giữ như cũ)
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!agree) {
                          _toast('Bạn cần đồng ý Điều khoản & Chính sách trước khi tiếp tục.');
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text('Đăng nhập'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ NÚT 2: Google (giữ như cũ)
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _googleLoading ? null : _loginGoogle,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.g_mobiledata, size: 30),
                          const SizedBox(width: 8),
                          Text(
                            _googleLoading ? 'Đang xử lý...' : 'Tiếp tục với Google',
                            style: AppTextStyles.outlineButtonText,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ NÚT 3: Số điện thoại (giữ như cũ)
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        if (!agree) {
                          _toast('Bạn cần đồng ý Điều khoản & Chính sách trước khi tiếp tục.');
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterPhonePage()),
                        );
                      },
                      child: Text(
                        'Tiếp tục bằng số điện thoại',
                        style: AppTextStyles.outlineButtonText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: agree,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => agree = v ?? false),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _showTermsDialog,
                          child: Text(
                            'Tôi đồng ý với Điều khoản & Chính sách bảo mật',
                            style: AppTextStyles.legalText.copyWith(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.55,
      size.height * 0.82,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.65,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
