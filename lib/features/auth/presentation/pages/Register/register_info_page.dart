import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/login_password_page.dart';

class RegisterInfoPage extends StatefulWidget {
  final String gender; // 'male' | 'female'
  final String email;
  final String password;

  const RegisterInfoPage({
    super.key,
    required this.gender,
    required this.email,
    required this.password,
  });

  @override
  State<RegisterInfoPage> createState() => _RegisterInfoPageState();
}

class _RegisterInfoPageState extends State<RegisterInfoPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  String? _selectedArea;

  // =========================
  // IMPORTANT: baseUrl
  // - Emulator: http://10.0.2.2:3001
  // - Máy thật: http://<LAN_IP_Mac>:3001  (vd: http://192.168.1.45:3001)
  // =========================
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://172.16.1.21:3001", // <-- đổi đúng LAN IP
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  );

  bool _checkingUsername = false;
  bool? _usernameOk; // null=chưa check, true=available, false=not available / error
  String? _usernameMessage;

  bool _submitting = false;

  Timer? _debounce;

  final List<String> _areas = const [
    'TP. Hồ Chí Minh',
    'Hà Nội',
    'Đà Nẵng',
    'Cần Thơ',
    'Hải Phòng',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.removeListener(_onUsernameChanged);

    _usernameController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  // =========================
  // USERNAME HELPERS
  // =========================
  String _normalizeUsername(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\s+'), '_'); // spaces -> _
    s = s.replaceAll(RegExp(r'[^a-z0-9_.]'), ''); // keep a-z0-9_.
    s = s.replaceAll(RegExp(r'^[_\.]+'), '');
    s = s.replaceAll(RegExp(r'[_\.]+$'), '');
    if (s.length > 20) s = s.substring(0, 20);
    return s;
  }

  String _randomUsername() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final suffix = (now % 100000).toString().padLeft(5, '0');
    return 'user_$suffix';
  }

  bool _validUsernameFormat(String u) {
    if (u.length < 3 || u.length > 20) return false;
    if (!RegExp(r'^[a-z0-9].*[a-z0-9]$').hasMatch(u)) return false;
    if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(u)) return false;
    return true;
  }

  void _onUsernameChanged() {
    setState(() {
      _usernameOk = null;
      _usernameMessage = null;
    });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final raw = _usernameController.text;
      final u = _normalizeUsername(raw);

      // normalize lại text (giống instagram)
      if (u != raw) {
        _usernameController.value = _usernameController.value.copyWith(
          text: u,
          selection: TextSelection.collapsed(offset: u.length),
        );
      }

      if (u.length >= 3) {
        await _checkUsernameAvailable(u, silent: true);
      }
    });
  }

  Future<void> _checkUsernameAvailable(String raw, {bool silent = false}) async {
    final u = _normalizeUsername(raw);

    if (u.isEmpty || u.length < 3) {
      setState(() {
        _usernameOk = false;
        _usernameMessage = 'Username tối thiểu 3 ký tự';
      });
      return;
    }

    if (!_validUsernameFormat(u)) {
      setState(() {
        _usernameOk = false;
        _usernameMessage = 'Chỉ gồm a-z, 0-9, "_" hoặc "." (3-20 ký tự)';
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
      _usernameOk = null;
      _usernameMessage = silent ? null : 'Đang kiểm tra...';
    });

    try {
      final res = await _dio.get(
        '/users/username-available',
        queryParameters: {'u': u},
      );

      final data = res.data;
      if (data is! Map) throw Exception('Response không đúng định dạng');

      final available = data['available'];
      if (available is! bool) throw Exception('Response thiếu field "available"');

      setState(() {
        _usernameOk = available;
        _usernameMessage = available ? 'Username hợp lệ' : 'Username đã tồn tại';
      });
    } on DioException catch (e) {
      final detail = e.message ?? 'Dio error';
      setState(() {
        _usernameOk = false;
        _usernameMessage = 'Không gọi được backend: $detail';
      });
    } catch (e) {
      setState(() {
        _usernameOk = false;
        _usernameMessage = 'Không kiểm tra được username: $e';
      });
    } finally {
      if (mounted) setState(() => _checkingUsername = false);
    }
  }

  // =========================
  // AREA PICKER
  // =========================
  void _showAreaPicker() {
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
                'Chọn khu vực',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _areas.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  itemBuilder: (context, index) {
                    final area = _areas[index];
                    final selected = area == _selectedArea;
                    return ListTile(
                      onTap: () {
                        setState(() => _selectedArea = area);
                        Navigator.of(context).pop();
                      },
                      title: Text(area),
                      trailing: selected
                          ? const Icon(Icons.check,
                          size: 18, color: AppColors.primary)
                          : null,
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

  // =========================
  // SUBMIT: REGISTER EMAIL thật
  // =========================
  Future<void> _onFinish() async {
    if (_submitting) return;

    final username = _normalizeUsername(_usernameController.text);

    if (username.isEmpty) {
      _toast('Vui lòng nhập username');
      return;
    }

    await _checkUsernameAvailable(username);
    if (_usernameOk != true) {
      _toast(_usernameMessage ?? 'Username không hợp lệ');
      return;
    }

    final last = _lastNameController.text.trim();
    final first = _firstNameController.text.trim();
    if (last.isEmpty || first.isEmpty) {
      _toast('Vui lòng nhập đầy đủ họ và tên');
      return;
    }

    final day = _dayController.text.trim();
    final month = _monthController.text.trim();
    final year = _yearController.text.trim();
    if (day.isEmpty || month.isEmpty || year.isEmpty) {
      _toast('Vui lòng nhập ngày sinh');
      return;
    }

    if (_selectedArea == null) {
      _toast('Vui lòng chọn khu vực');
      return;
    }

    final fullName = '$last $first'.replaceAll(RegExp(r'\s+'), ' ').trim();

    setState(() => _submitting = true);

    try {
      // 1) Register bằng email/password
      // NOTE: đổi endpoint theo backend bạn (ví dụ /auth/register-email)
      final res = await _dio.post(
        '/auth/register-email',
        data: {
          'email': widget.email,
          'password': widget.password,
          'fullName': fullName,
          // nếu backend bạn chưa có các field này thì bỏ đi
          'username': username,
          'gender': widget.gender,
          'dob': '$year-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}',
          'area': _selectedArea,
        },
      );

      final data = res.data;

      // Nếu backend trả { ok: true } hoặc trả user/token đều ok
      final ok = (data is Map && (data['ok'] == true || data['id'] != null || data['user'] != null));

      if (!ok) {
        throw Exception('Đăng ký thất bại (response không như mong đợi)');
      }

      if (!mounted) return;

      // 2) Thành công -> chuyển sang LoginPasswordPage
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPasswordPage()),
            (route) => false,
      );
    } on DioException catch (e) {
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response?.data['message'].toString()
          : (e.message ?? 'Dio error');
      _toast('Đăng ký thất bại: $msg');
    } catch (e) {
      _toast('Đăng ký thất bại: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  // =========================
  // UI DECORATIONS
  // =========================
  InputDecoration _roundDecoration(String hint, {Widget? suffixIcon}) =>
      InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primarySoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        suffixIcon: suffixIcon,
      );

  InputDecoration _dobDecoration(String hint) => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintText: hint,
    hintStyle: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
    ),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primarySoft),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
    ),
  );

  Widget? _usernameStatusIcon() {
    if (_checkingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_usernameOk == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (_usernameOk == false) {
      return const Icon(Icons.cancel, color: Colors.red);
    }
    return null;
  }

  Color _usernameMessageColor() {
    if (_usernameOk == true) return Colors.green;
    if (_usernameOk == false) return Colors.red;
    return AppColors.textSecondary;
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
          'Thông tin',
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
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'THÔNG TIN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Username',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: _roundDecoration(
                        'vd: tram_01',
                        suffixIcon: _usernameStatusIcon(),
                      ),
                      onEditingComplete: () =>
                          _checkUsernameAvailable(_usernameController.text),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () async {
                        final u = _randomUsername();
                        _usernameController.text = u;
                        await _checkUsernameAvailable(u);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primarySoft),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Random',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              if (_usernameMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  _usernameMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _usernameMessageColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      decoration: _roundDecoration('Họ và tên đệm'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      decoration: _roundDecoration('Tên'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                'Ngày sinh',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _dayController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _dobDecoration('Ngày'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _monthController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _dobDecoration('Tháng'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: _dobDecoration('Năm'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                'Khu vực',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _showAreaPicker,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primarySoft),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedArea ?? 'Chọn khu vực',
                          style: TextStyle(
                            color: _selectedArea == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _onFinish,
                  child: Text(
                    _submitting ? 'ĐANG TẠO TÀI KHOẢN...' : 'TIẾP TỤC',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
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
