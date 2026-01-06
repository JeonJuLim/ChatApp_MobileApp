import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:minichatappmobile/core/config/app_config.dart';
import 'package:minichatappmobile/core/config/app_dio.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/chat_detail_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/user_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/settings_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/friends_tab.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/create_group_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  Dio get _dio => AppDio.instance;

  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0;

  String? _myUserId;
  Future<List<dynamic>>? _conversationFuture;

  static const String _tokenKey = 'accessToken';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  // =============================
  // Ensure Authorization header
  // =============================
  Future<bool> _ensureAuthHeader() async {
    final current = _dio.options.headers['Authorization']?.toString();
    if (current != null && current.startsWith('Bearer ')) return true;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) return false;

    _dio.options.headers['Authorization'] = 'Bearer $token';
    return true;
  }

  Future<void> _bootstrap() async {
    final ok = await _ensureAuthHeader();
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _myUserId = null;
        _conversationFuture = Future.value([]);
      });
      return;
    }

    await _fetchMe();

    if (!mounted) return;
    setState(() {
      _conversationFuture = fetchConversations();
    });
  }

  // =========================
  // GET /users/me -> lấy userId chuẩn
  // =========================
  Future<void> _fetchMe() async {
    try {
      final res = await _dio.get('/users/me');
      final data = res.data;

      final id = (data is Map) ? data['id']?.toString() : null;

      if (!mounted) return;
      setState(() => _myUserId = (id != null && id.isNotEmpty) ? id : null);
    } on DioException catch (e) {
      // ignore: avoid_print
      print('FETCH ME ERR -> ${e.response?.statusCode} ${e.response?.data}');
      if (!mounted) return;
      setState(() => _myUserId = null);
    } catch (e) {
      // ignore: avoid_print
      print('FETCH ME ERR -> $e');
      if (!mounted) return;
      setState(() => _myUserId = null);
    }
  }

  // =========================
  // FETCH CONVERSATIONS (đúng chuẩn: dựa token, không query userId)
  // =========================
  Future<List<dynamic>> fetchConversations() async {
    final ok = await _ensureAuthHeader();
    if (!ok) return [];

    final res = await _dio.get('/conversations');
    final raw = res.data;

    // Support: backend trả List hoặc wrapper {data/items/conversations: [...]}
    if (raw is List) return raw;
    if (raw is Map) {
      final list = raw['data'] ?? raw['items'] ?? raw['conversations'];
      if (list is List) return list;
    }
    return [];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    if (_myUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // =========================
            // HEADER
            // =========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UserProfilePage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.secondary,
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const Spacer(),

                  InkWell(
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CreateGroupPage(myUserId: _myUserId!)),
                      );
                      if (result is Map) {
                        final convId = (result['conversationId'] ?? '').toString();
                        final title = (result['title'] ?? 'Nhóm chat').toString();
                        final isGroup = result['isGroup'] == true;

                        // reload list trước (optional)
                        setState(() => _conversationFuture = fetchConversations());

                        if (!mounted || convId.isEmpty) return;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatDetailPage(
                              title: title,
                              conversationId: convId,
                              myUserId: _myUserId!,
                              isGroup: isGroup,
                            ),
                          ),
                        );
                      }

                    },
                    borderRadius: BorderRadius.circular(999),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.mint,
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =========================
            // SEARCH BAR (UI ONLY)
            // =========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // =========================
            // CHAT LIST
            // =========================
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _conversationFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('❌ Không tải được danh sách chat'),
                    );
                  }

                  final conversations = snapshot.data ?? [];
                  if (conversations.isEmpty) {
                    return const Center(
                      child: Text('Chưa có cuộc trò chuyện'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: conversations.length,
                      itemBuilder: (_, index) {
                        final raw = conversations[index];
                        if (raw is! Map) return const SizedBox.shrink();

                        final c = Map<String, dynamic>.from(raw);

                        final String id = (c['id'] ?? '').toString();
                        if (id.isEmpty) return const SizedBox.shrink();

                        final String type = (c['type'] ?? '').toString(); // "direct" | "group"
                        final bool isGroup = type == 'group';

                        // ✅ title backend đã tính sẵn (direct: tên user còn lại, group: name)
                        final String title = (c['title'] ?? (isGroup ? 'Nhóm chat' : 'Chat')).toString();

                        final String lastMessage = (c['lastMessage'] ?? '').toString();
                        final int unread = (c['unreadCount'] is int) ? c['unreadCount'] as int : 0;
                        final bool hasUnread = unread > 0;

                        return _ConversationTile(
                          title: title,
                          lastMessage: lastMessage,
                          isGroup: isGroup,
                          hasUnread: hasUnread,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatDetailPage(
                                  // ✅ AppBar sẽ dùng title này
                                  title: title,
                                  conversationId: id,
                                  myUserId: _myUserId!,
                                  isGroup: isGroup,
                                ),
                              ),
                            );
                          },
                        );
                      },
                  );
                },
              ),
            ),

            // =========================
            // BOTTOM NAV
            // =========================
            BottomNavigationBar(
              currentIndex: _currentTabIndex,
              onTap: (i) async {
                // 👥 Bạn bè
                if (i == 1) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FriendsTab()),
                  );
                  return; // không đổi tab index
                }

                // ⚙️ Cài đặt
                if (i == 3) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                  return; // không đổi tab index
                }

                setState(() => _currentTabIndex = i);
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  label: 'Tin nhắn',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: 'Bạn bè',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.groups_outlined),
                  label: 'Cộng đồng',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Cài đặt',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// CONVERSATION TILE
// =========================
class _ConversationTile extends StatelessWidget {
  final String title;
  final String lastMessage;
  final bool isGroup;
  final bool hasUnread;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.title,
    required this.lastMessage,
    required this.isGroup,
    required this.hasUnread,
    required this.onTap,
  });

  String get _initials {
    final t = title.trim();
    if (t.isEmpty) return 'C';

    final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';

    final first = parts.first;
    final last = parts.length == 1 ? parts.first : parts.last;

    final a = first.isNotEmpty ? first[0] : 'C';
    final b = last.isNotEmpty ? last[0] : '';

    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isGroup ? AppColors.secondary : AppColors.primary,
                child: isGroup
                    ? const Icon(Icons.group, color: Colors.white)
                    : Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.trim().isEmpty ? (isGroup ? 'Nhóm chat' : 'Chat') : title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.legalText,
                    ),
                  ],
                ),
              ),
              if (hasUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
