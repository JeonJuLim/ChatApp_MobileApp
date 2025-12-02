import 'package:flutter/material.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool agree = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Nền wave phía trên
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: TopWaveClipper(),
              child: Container(
                height: size.height * 0.52, // wave cao hơn
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.mint,       // #ADEEE2
                      AppColors.primarySoft // xanh tím nhạt
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // Nội dung chính
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 70), // đẩy logo xuống trong wave

                  // Logo
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

                  Center(
                    child: Text(
                      'Welcome',
                      style: AppTextStyles.welcomeTitle,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Center(
                    child: Text(
                      'Ứng dụng gọi điện và nhắn tin\nthời gian thực dành cho giới trẻ.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.welcomeSubtitle,
                    ),
                  ),

                  const SizedBox(height: 85), // tách khỏi wave, bắt đầu vùng trắng

                  // Nút Đăng nhập
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!agree) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Bạn cần đồng ý Điều khoản & Chính sách trước khi tiếp tục.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text('Đăng nhập'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nút Google
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Google sign-in
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.g_mobiledata, size: 30),
                          const SizedBox(width: 8),
                          Text(
                            'Tiếp tục với Google',
                            style: AppTextStyles.outlineButtonText,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nút tiếp tục bằng số điện thoại
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: điều hướng tới login phone trực tiếp
                      },
                      child: Text(
                        'Tiếp tục bằng số điện thoại',
                        style: AppTextStyles.outlineButtonText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Checkbox(
                        value: agree,
                        activeColor: AppColors.primary,
                        onChanged: (v) {
                          setState(() => agree = v ?? false);
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Tôi đồng ý với Điều khoản & Chính sách bảo mật',
                          style: AppTextStyles.legalText,
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

/// Clipper tạo shape wave cong phía trên
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Bắt đầu từ góc trái, đi xuống 75% chiều cao
    path.lineTo(0, size.height * 0.75);

    // Cong thứ nhất
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.55,
      size.height * 0.82,
    );

    // Cong thứ hai
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.65,
      size.width,
      size.height * 0.8,
    );

    // Đóng path
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
