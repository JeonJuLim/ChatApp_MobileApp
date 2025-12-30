import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:minichatappmobile/core/network/api_client.dart';
import 'package:minichatappmobile/core/storage/token_storage.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/chat_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _phoneCtrl = TextEditingController();

  final _tokenStorage = TokenStorage();
  late final ApiClient _api;

  bool _saving = false;

  String get _normalizedPhone {
    // normalize cực chặt: trim + bỏ khoảng trắng giữa số
    final raw = _phoneCtrl.text;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    // nếu bạn muốn cho phép nhập "098 765 4321" thì bỏ space:
    final noSpaces = trimmed.replaceAll(RegExp(r'\s+'), '');
    return noSpaces;
  }

  bool get _isEmpty => _normalizedPhone.isEmpty;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(_tokenStorage);

    _phoneCtrl.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _goChatList() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChatListPage()),
    );
  }

  Future<void> _onPress() async {
    if (_saving) return;

    // ✅ RỖNG: TUYỆT ĐỐI KHÔNG GỌI API
    if (_isEmpty) {
      _goChatList();
      return;
    }

    setState(() => _saving = true);

    final phone = _normalizedPhone;

    try {
      await _api.dio.patch(
        "/users/me/phone",
        data: {"phone": phone},
      );

      _toast("Đã cập nhật số điện thoại.");
      _goChatList();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      _toast("Cập nhật thất bại (${status ?? "no status"}). Bạn có thể cập nhật sau.");
      _goChatList();
    } catch (_) {
      _toast("Cập nhật thất bại. Bạn có thể cập nhật sau.");
      _goChatList();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu bạn muốn GIỮ nguyên chữ nút luôn luôn là "Cập nhật số điện thoại"
    // thì thay label thành const "Cập nhật số điện thoại".
    final label = _isEmpty ? "Cập nhật sau" : "Cập nhật số điện thoại";

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Số điện thoại (có thể để trống)"),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "Nhập số điện thoại để xác thực sau",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Bạn có thể cập nhật số điện thoại sau.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _onPress,
                child: Text(_saving ? "Đang xử lý..." : label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
