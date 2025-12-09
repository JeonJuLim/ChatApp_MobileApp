import 'package:flutter/material.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/chat_list_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/login_password_page.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();

  // ==== MODEL ĐƠN GIẢN CHO ĐẦU SỐ QUỐC GIA ====
  final List<_CountryCode> _countries = const [
    _CountryCode(name: 'Việt Nam', flag: '🇻🇳', dialCode: '+84'),
    _CountryCode(name: 'United States', flag: '🇺🇸', dialCode: '+1'),
    _CountryCode(name: 'Japan', flag: '🇯🇵', dialCode: '+81'),
    _CountryCode(name: 'South Korea', flag: '🇰🇷', dialCode: '+82'),
    _CountryCode(name: 'Singapore', flag: '🇸🇬', dialCode: '+65'),
    _CountryCode(name: 'Thailand', flag: '🇹🇭', dialCode: '+66'),
  ];

  late _CountryCode _selectedCountry;

  @override
  void initState() {
    super.initState();
    // Mặc định là Việt Nam
    _selectedCountry = _countries.first;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ======= SHOW BOTTOM SHEET CHỌN ĐẦU SỐ =======
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Chọn mã quốc gia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _countries.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  itemBuilder: (context, index) {
                    final c = _countries[index];
                    final isSelected = c.dialCode == _selectedCountry.dialCode;

                    return ListTile(
                      onTap: () {
                        setState(() {
                          _selectedCountry = c;
                        });
                        Navigator.of(context).pop();
                      },
                      leading: Text(
                        c.flag,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(c.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.dialCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check,
                                size: 18, color: AppColors.primary),
                          ]
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ======= XỬ LÝ KHI BẤM TIẾP TỤC =======
  void _goToOtp() {
    // Nếu không phải +84 -> popup chưa hỗ trợ
    if (_selectedCountry.dialCode != '+84') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Chưa hỗ trợ'),
          content: Text(
              'Hiện tại hệ thống chỉ hỗ trợ tạo tài khoản với đầu số +84 (Việt Nam).\n\n'
                  'Đầu số bạn chọn: ${_selectedCountry.dialCode}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
      return;
    }

    // TODO: validate thêm (độ dài, regex) và gọi API gửi OTP
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OtpPage(),
      ),
    );
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
          'Đăng nhập',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Số điện thoại',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10, // ví dụ: 10 số sau +84
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primarySoft),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.4,
                    ),
                  ),

                  // Ô chọn đầu số
                  prefixIcon: InkWell(
                    onTap: _showCountryPicker,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedCountry.flag,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedCountry.dialCode,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                          const SizedBox(width: 6),
                          Container(
                            width: 1,
                            height: 24,
                            color: const Color(0xFFE5E7EB),
                          ),
                        ],
                      ),
                    ),
                  ),
                  prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),

                  hintText: '0xxxxxxxxx',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chúng tôi sẽ gửi mã OTP để xác nhận số điện thoại của bạn.',
                style: AppTextStyles.legalText,
              ),

              const Spacer(),

              // Nút TIẾP TỤC
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _goToOtp,
                  child: const Text(
                    'TIẾP TỤC',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// MODEL đơn giản cho country code
class _CountryCode {
  final String name;
  final String flag;
  final String dialCode;

  const _CountryCode({
    required this.name,
    required this.flag,
    required this.dialCode,
  });
}

// ===================== OTP PAGE ĐƠN GIẢN (MẪU) =====================
class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  // 4 ô nhập OTP
  final List<TextEditingController> _otpControllers =
  List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // Khi OTP hợp lệ -> coi như đăng nhập thành công
  Future<void> _onOtpSuccess(BuildContext context) async {
    // sau này bạn sẽ lấy accessToken từ API, giờ mock tạm
    const fakeAccessToken = 'fake-token-123';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('accessToken', fakeAccessToken);

    // Đi tới ChatListPage và xoá hết stack trước đó (không quay lại login nữa)
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ChatListPage()),
          (route) => false,
    );
  }

  // Lấy OTP hiện tại
  String get _currentOtp =>
      _otpControllers.map((c) => c.text.trim()).join();

  // Validate đơn giản rồi gọi _onOtpSuccess
  Future<void> _onConfirmPressed() async {
    final otp = _currentOtp;
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 4 số OTP')),
      );
      return;
    }

    // TODO: gọi API verify OTP, nếu OK thì:
    await _onOtpSuccess(context);
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
          'Xác nhận OTP',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Nhập mã OTP gồm 4 số\nđã gửi tới số điện thoại của bạn.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.welcomeSubtitle,
                ),
              ),
              const SizedBox(height: 24),

              // ==== HÀNG 4 Ô OTP ====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  4,
                      (index) => SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          // Nếu chưa phải ô cuối -> chuyển focus sang ô phải
                          if (index < 3) {
                            _focusNodes[index + 1].requestFocus();
                          } else {
                            // Ô cuối cùng -> bỏ focus (đóng bàn phím)
                            _focusNodes[index].unfocus();
                          }
                        } else {
                          // Nếu bấm xoá và không có ký tự, có thể nhảy về ô trái (tuỳ thích)
                          if (index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        }
                      },
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                          const BorderSide(color: AppColors.primarySoft),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Gửi lại OTP
              TextButton(
                onPressed: () {
                  // TODO: Gửi lại OTP
                },
                child: const Text('Gửi lại OTP'),
              ),


      // ==== Đăng nhập bằng mật khẩu ====
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginPasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Đăng nhập bằng mật khẩu',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Spacer(),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      // TODO: check 4 ô OTP có đúng không, gọi API verify
                      // Hiện tại mock luôn là đúng:
                      await _onOtpSuccess(context);
                    },
                    child: const Text(
                      'TIẾP TỤC',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    }
  }

