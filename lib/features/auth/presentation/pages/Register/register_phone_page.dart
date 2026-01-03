import 'package:flutter/material.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';

class RegisterPhonePage extends StatefulWidget {
  const RegisterPhonePage({super.key});

  @override
  State<RegisterPhonePage> createState() => _RegisterPhonePageState();
}

class _RegisterPhonePageState extends State<RegisterPhonePage> {
  final TextEditingController _phoneController = TextEditingController();

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
    _selectedCountry = _countries.first; // mặc định Việt Nam
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                    final selected = c.dialCode == _selectedCountry.dialCode;

                    return ListTile(
                      onTap: () {
                        setState(() => _selectedCountry = c);
                        Navigator.of(context).pop();
                      },
                      leading:
                      Text(c.flag, style: const TextStyle(fontSize: 22)),
                      title: Text(c.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.dialCode,
                            style:
                            const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (selected) ...[
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

  void _onContinue() {
    if (_selectedCountry.dialCode != '+84') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Chưa hỗ trợ'),
          content: Text(
            'Hiện tại hệ thống chỉ hỗ trợ đầu số +84 (Việt Nam).\n\n'
                'Đầu số bạn chọn: ${_selectedCountry.dialCode}',
          ),
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

    // ✅ Không gọi OTP page nữa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hiện tại đăng ký bằng số điện thoại/OTP đang tạm tắt.'),
      ),
    );

    // Nếu bạn muốn điều hướng sang trang khác thì thay đoạn SnackBar bằng Navigator.push(...)
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
          'Đăng ký',
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
                maxLength: 10,
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
                  prefixIcon: InkWell(
                    onTap: _showCountryPicker,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedCountry.flag,
                              style: const TextStyle(fontSize: 18)),
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
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _onContinue,
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
