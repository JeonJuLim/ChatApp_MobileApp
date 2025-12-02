import 'package:flutter/material.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text('Xin chào 👋', style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              const Text(
                'Đăng nhập để tiếp tục trò chuyện',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: gọi API login sau
                },
                child: const Text('Đăng nhập'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // TODO: chuyển sang register_page
                },
                child: const Text('Chưa có tài khoản? Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
