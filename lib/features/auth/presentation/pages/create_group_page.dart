import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:minichatappmobile/core/network/app_dio.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';

class CreateGroupPage extends StatefulWidget {
  final String myUserId;
  const CreateGroupPage({super.key, required this.myUserId});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  /// Backend: GET /friends => List<{ id, username, fullName, avatarUrl }>
  List<dynamic> _friends = [];
  final Set<String> _selectedFriendIds = {};

  static const String _tokenKey = 'accessToken';
  Dio get _dio => AppDio.instance;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<bool> _ensureAuthHeader() async {
    final current = _dio.options.headers['Authorization']?.toString();
    if (current != null && current.startsWith('Bearer ')) return true;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return false;

    _dio.options.headers['Authorization'] = 'Bearer $token';
    return true;
  }

  Future<void> _fetchFriends() async {
    try {
      final ok = await _ensureAuthHeader();
      if (!ok) {
        if (mounted) setState(() => _friends = []);
        _toast('Chưa có token đăng nhập');
        return;
      }

      final res = await _dio.get('/friends');
      final data = res.data;

      if (data is! List) {
        if (mounted) setState(() => _friends = []);
        _toast('Response friends không đúng format');
        return;
      }

      if (mounted) setState(() => _friends = data);
    } on DioException catch (e) {
      // ignore: avoid_print
      print('FETCH FRIENDS ERR -> ${e.response?.statusCode} ${e.response?.data}');
      if (mounted) setState(() => _friends = []);
      _toast('Không tải được bạn bè (${e.response?.statusCode ?? 'ERR'})');
    } catch (e) {
      // ignore: avoid_print
      print('FETCH FRIENDS ERR -> $e');
      if (mounted) setState(() => _friends = []);
      _toast('Không tải được bạn bè');
    }
  }

  Future<void> _createGroup() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('Vui lòng nhập tên nhóm');
      return;
    }
    if (_selectedFriendIds.isEmpty) {
      _toast('Chọn ít nhất 1 thành viên');
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await _ensureAuthHeader();
      if (!ok) {
        _toast('Chưa có token đăng nhập');
        return;
      }

      final res = await _dio.post(
        '/conversations/groups',
        data: {
          'name': name,
          'memberIds': _selectedFriendIds.toList(),
        },
      );

      final data = res.data;
      final convId = (data is Map) ? data['id']?.toString() : null;

      if (convId == null || convId.isEmpty) {
        _toast('Server không trả conversationId');
        return;
      }

      if (!mounted) return;

      // ✅ Trả về convId để ChatList mở thẳng ChatDetail
      Navigator.of(context).pop({
        'conversationId': convId,
        'title': name,
        'isGroup': true,
      });
    } on DioException catch (e) {
      // ignore: avoid_print
      print('CREATE GROUP ERR -> ${e.response?.statusCode} ${e.response?.data}');
      _toast('Tạo nhóm thất bại (${e.response?.statusCode ?? 'ERR'})');
    } catch (e) {
      // ignore: avoid_print
      print('CREATE GROUP ERR -> $e');
      _toast('Lỗi tạo nhóm');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Tạo nhóm chat',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _fetchFriends,
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Tên nhóm',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Thành viên đã chọn: ${_selectedFriendIds.length}',
                    style: AppTextStyles.bodySecondary,
                  ),
                  const Spacer(),
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _friends.isEmpty
                  ? Center(
                child: Text(
                  'Bạn chưa có bạn bè để thêm',
                  style: AppTextStyles.bodySecondary,
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                itemCount: _friends.length,
                itemBuilder: (_, i) {
                  final raw = _friends[i];

                  final user = (raw is Map)
                      ? Map<String, dynamic>.from(raw)
                      : <String, dynamic>{};

                  final id = (user['id'] ?? '').toString();
                  if (id.isEmpty) return const SizedBox.shrink();

                  final displayName =
                  (user['fullName'] ?? user['username'] ?? 'User')
                      .toString();

                  final selected = _selectedFriendIds.contains(id);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedFriendIds.remove(id);
                          } else {
                            _selectedFriendIds.add(id);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.secondary,
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                displayName,
                                style: AppTextStyles.body,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Checkbox(
                              value: selected,
                              onChanged: (_) {
                                setState(() {
                                  if (selected) {
                                    _selectedFriendIds.remove(id);
                                  } else {
                                    _selectedFriendIds.add(id);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _loading ? 'Đang tạo...' : 'Tạo nhóm',
                    style: AppTextStyles.outlineButtonText
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
