import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:minichatappmobile/core/config/app_config.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  final String myUserId;
  const ChatListPage({super.key,required this.myUserId});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0;

  // =========================
  // REST: FETCH CONVERSATIONS
  // =========================
  Future<List<dynamic>> fetchConversations() async {
    final res = await http.get(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/conversations?userId=${widget.myUserId}',
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
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.secondary,
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
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
                future: fetchConversations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('❌ Không tải được danh sách chat'),
                    );
                  }

                  final conversations = snapshot.data!;
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
                                myUserId: 'u1',
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
              onTap: (i) => setState(() => _currentTabIndex = i),
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
