import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:minichatappmobile/core/theme/theme_x.dart';

import '../../data/group_api.dart';

class GroupMembersPage extends StatefulWidget {
  final Dio dio;
  final String conversationId;
  final String title;

  const GroupMembersPage({
    super.key,
    required this.dio,
    required this.conversationId,
    required this.title,
  });

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  late final api = GroupApi(widget.dio);
  late Future<Map<String, dynamic>> future;

  final addC = TextEditingController();
  final removeC = TextEditingController();
  bool loadingAction = false;

  @override
  void initState() {
    super.initState();
    future = api.getGroup(widget.conversationId);
  }

  @override
  void dispose() {
    addC.dispose();
    removeC.dispose();
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

  Future<void> _reload() async {
    setState(() => future = api.getGroup(widget.conversationId));
  }

  Future<void> _apply() async {
    final add = _parseIds(addC.text);
    final remove = _parseIds(removeC.text);

    if (add.isEmpty && remove.isEmpty) return;

    setState(() => loadingAction = true);
    try {
      await api.updateMembers(
        conversationId: widget.conversationId,
        add: add.isEmpty ? null : add,
        remove: remove.isEmpty ? null : remove,
      );
      addC.clear();
      removeC.clear();
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => loadingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        title: Text('Thành viên • ${widget.title}', style: TextStyle(color: context.text, fontWeight: FontWeight.w800)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return Center(child: Text('Lỗi: ${snap.error}', style: TextStyle(color: context.text)));
            }
            return const Center(child: CircularProgressIndicator());
          }

          final conv = snap.data!;
          final members = (conv['members'] as List).map((e) => Map<String, dynamic>.from(e)).toList();

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // form add/remove
              _box(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thêm / Xoá thành viên (userId)', style: TextStyle(color: context.text, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _input(context, addC, 'Add userIds (a,b,c)'),
                    const SizedBox(height: 8),
                    _input(context, removeC, 'Remove userIds (x,y,z)'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 46,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        onPressed: loadingAction ? null : _apply,
                        child: Text(loadingAction ? 'Đang cập nhật...' : 'Cập nhật'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text('Danh sách thành viên (${members.length})', style: TextStyle(color: context.subtext, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),

              ...members.map((m) {
                final role = (m['role'] ?? 'member').toString();
                final user = Map<String, dynamic>.from(m['user']);
                final fullName = (user['fullName'] ?? user['username'] ?? 'User').toString();
                final id = (user['id'] ?? '').toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _box(
                    context,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: context.primary.withOpacity(0.18),
                          child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                              style: TextStyle(color: context.primary, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fullName, style: TextStyle(color: context.text, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(id, style: TextStyle(color: context.subtext, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: context.primary.withOpacity(0.18)),
                          ),
                          child: Text(role, style: TextStyle(color: context.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _box(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.divider.withOpacity(0.25)),
      ),
      child: child,
    );
  }

  Widget _input(BuildContext context, TextEditingController c, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divider.withOpacity(0.25)),
      ),
      child: TextField(
        controller: c,
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
