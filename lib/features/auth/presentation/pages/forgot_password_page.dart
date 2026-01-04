import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;
  bool _otpSent = false;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://192.168.1.45:3001",
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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

  Future<void> _sendResetRequest() async {
    if (_loading) return;

    final rawId = _identifierController.text;

    if (rawId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email hoặc số điện thoại')),
      );
      return;
    }

    final identifier = _normalizeIdentifier(rawId);

    setState(() => _loading = true);

    try {
      debugPrint('➡️ FORGOT PASSWORD REQUEST');
      debugPrint('identifier = $identifier');

      final res = await _dio.post(
        "/auth/forgot-password",
        data: {
          "identifier": identifier,
        },
      );

      debugPrint('✅ STATUS: ${res.statusCode}');
      debugPrint('✅ BODY: ${res.data}');

      if (!mounted) return;

      setState(() => _otpSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã OTP đã được gửi! Vui lòng kiểm tra email/SMS'),
          backgroundColor: Colors.green,
        ),
      );
    } on DioException catch (e) {
      debugPrint('❌ FORGOT PASSWORD ERROR');
      debugPrint('STATUS: ${e.response?.statusCode}');
      debugPrint('BODY: ${e.response?.data}');
      debugPrint('MSG: ${e.message}');
      debugPrint('TYPE: ${e.type}');

      if (!mounted) return;

      String errorMsg = 'Có lỗi xảy ra';
      
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMsg = 'Không thể kết nối đến server. Vui lòng kiểm tra:\n'
                   '- Server backend đã chạy chưa?\n'
                   '- IP address có đúng không? (${_dio.options.baseUrl})';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = 'Lỗi kết nối mạng. Kiểm tra Wi-Fi/IP backend';
      } else if (e.response?.data != null) {
        errorMsg = e.response?.data?['message'] ?? e.message ?? 'Lỗi không xác định';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_loading) return;

    final identifier = _normalizeIdentifier(_identifierController.text);
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (otp.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      debugPrint('➡️ RESET PASSWORD REQUEST');
      debugPrint('identifier = $identifier');
      debugPrint('otp = $otp');

      final res = await _dio.post(
        "/auth/reset-password",
        data: {
          "identifier": identifier,
          "otp": otp,
          "newPassword": newPassword,
        },
      );

      debugPrint('✅ STATUS: ${res.statusCode}');
      debugPrint('✅ BODY: ${res.data}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại'),
          backgroundColor: Colors.green,
        ),
      );

      // Quay lại trang login
      Navigator.of(context).pop();
    } on DioException catch (e) {
      debugPrint('❌ RESET PASSWORD ERROR');
      debugPrint('STATUS: ${e.response?.statusCode}');
      debugPrint('BODY: ${e.response?.data}');
      debugPrint('MSG: ${e.message}');
      debugPrint('TYPE: ${e.type}');

      if (!mounted) return;

      String errorMsg = 'Có lỗi xảy ra';
      
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMsg = 'Không thể kết nối đến server. Kiểm tra backend và IP';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = 'Lỗi kết nối mạng. Kiểm tra Wi-Fi/IP backend';
      } else if (e.response?.data != null) {
        errorMsg = e.response?.data?['message'] ?? e.message ?? 'Lỗi không xác định';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
          'Quên mật khẩu',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Email / Số điện thoại',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _identifierController,
                enabled: !_otpSent,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _otpSent ? Colors.grey[200] : Colors.white,
                  hintText: 'tram1@gmail.com hoặc 0909xxxxxx',
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
              if (!_otpSent) ...[
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendResetRequest,
                    child: Text(
                      _loading ? 'Đang gửi...' : 'GỬI MÃ XÁC THỰC',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Mã OTP',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Nhập mã OTP',
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
                  'Mật khẩu mới',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Nhập mật khẩu mới',
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
                        _obscureNewPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNewPassword = !_obscureNewPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Xác nhận mật khẩu mới',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Nhập lại mật khẩu mới',
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
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _resetPassword,
                    child: Text(
                      _loading ? 'Đang xử lý...' : 'ĐỔI MẬT KHẨU',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _otpSent = false;
                        _otpController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    child: const Text(
                      'Gửi lại mã',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
