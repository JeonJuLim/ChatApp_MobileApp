import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:minichatappmobile/core/theme/theme_x.dart';

import '../../data/group_api.dart';

class GroupCreatePage extends StatefulWidget {
  final Dio dio;
  const GroupCreatePage({super.key, required this.dio});

  @override
  State<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends State<GroupCreatePage> {
  late final api = GroupApi(widget.dio);

  final nameC = TextEditingController();
  final membersC = TextEditingController(); // nhập userId cách nhau dấu phẩy
  bool loading = false;

  @override
  void dispose() {
    nameC.dispose();
    membersC.dispose();
    super.dispose();
  }

  List<String> _parseIds(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        title: Text('Tạo nhóm', style: TextStyle(color: context.text, fontWeight: FontWeight.w800)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _field(context, controller: nameC, hint: 'Tên nhóm (VD: Team IRONMAN)'),
            const SizedBox(height: 10),
            _field(context, controller: membersC, hint: 'Member userIds (cách nhau bởi dấu phẩy)'),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: loading
                    ? null
                    : () async {
                  final name = nameC.text.trim();
                  if (name.isEmpty) return;

                  final ids = _parseIds(membersC.text);

                  setState(() => loading = true);
                  try {
                    await api.createGroup(name: name, memberIds: ids);
                    if (!mounted) return;
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  } finally {
                    if (mounted) setState(() => loading = false);
                  }
                },
                child: Text(loading ? 'Đang tạo...' : 'Tạo nhóm'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'MVP test: nhập userId thành viên.\nAdmin mặc định là tài khoản đang đăng nhập (creator).',
              style: TextStyle(color: context.subtext, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context, {required TextEditingController controller, required String hint}) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.divider.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        style: TextStyle(color: context.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.subtext),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
