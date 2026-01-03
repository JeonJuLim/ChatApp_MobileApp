import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:minichatappmobile/core/config/app_config.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/chat_detail_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/user_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/settings_page.dart';
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});


  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0;
  String? _myUserId;
  Future<List<dynamic>>? _conversationFuture;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId');

    debugPrint('👤 Logged userId = $uid');

    if (!mounted) return;

    setState(() {
      _myUserId = uid;
      if (uid != null) {
        _conversationFuture = fetchConversations();
      }
    });
  }


  // =========================
  // REST: FETCH CONVERSATIONS
  // =========================
  Future<List<dynamic>> fetchConversations() async {
    if (_myUserId == null) return [];

    final res = await http.get(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/conversations?userId=$_myUserId',
      ),
    );

    debugPrint('STATUS: ${res.statusCode}');
    debugPrint('BODY: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('API error');
    }

    final data = jsonDecode(res.body);
    if (data is! List) {
      throw Exception('Invalid response format');
    }

    return data;
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

                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.mint,
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 18,
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
                      final c = conversations[index];

                      final String id = c['id'];
                      final String title = c['title'] ?? 'Chat';
                      final String lastMessage =
                          c['lastMessage'] ?? '';
                      final bool isGroup = c['type'] == 'group';
                      final bool hasUnread =
                          (c['unreadCount'] ?? 0) > 0;

                      return _ConversationTile(
                        title: title,
                        lastMessage: lastMessage,
                        isGroup: isGroup,
                        hasUnread: hasUnread,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatDetailPage(
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
                if (i == 3) {
                  // ✅ Cài đặt -> chuyển sang SettingsPage
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                  return; // ✅ không đổi tab index
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
    final parts = title.split(' ');
    if (parts.length == 1) return parts.first[0];
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                isGroup ? AppColors.secondary : AppColors.primary,
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
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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
