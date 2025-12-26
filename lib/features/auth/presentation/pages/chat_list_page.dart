import 'package:flutter/material.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import 'package:minichatappmobile/core/theme/theme_x.dart';

import 'package:minichatappmobile/features/auth/presentation/pages/chat_detail_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/settings_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/friends_tab.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0;

  final List<_Conversation> _conversations = [
    _Conversation(
      name: 'Nguyen A',
      lastMessageDetail: '15 phút trước',
      timeLabel: '15 phút trước',
      isGroup: false,
      hasUnread: true,
    ),
    _Conversation(
      name: 'Tran B',
      lastMessageDetail: 'Bạn: hfajod',
      timeLabel: '1 giờ trước',
      isGroup: false,
      hasUnread: true,
    ),
    _Conversation(
      name: 'Group học tập',
      lastMessageDetail: 'Nguyen A: [Sticker]',
      timeLabel: 'Hôm qua',
      isGroup: true,
      hasUnread: false,
    ),
    _Conversation(
      name: 'Tran C',
      lastMessageDetail: 'Bạn: sffs',
      timeLabel: '05/11',
      isGroup: false,
      hasUnread: false,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Conversation> get _filteredConversations {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _conversations;
    return _conversations.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildTabBody()),

            // ===== BOTTOM NAV (ăn theme) =====
            Container(
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                backgroundColor: context.surface,
                currentIndex: _currentTabIndex,
                onTap: (value) => setState(() => _currentTabIndex = value),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: context.primary,
                unselectedItemColor: context.subtext,
                showUnselectedLabels: true,
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
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ FIX: thêm case 1 cho FriendsTab
  Widget _buildTabBody() {
    switch (_currentTabIndex) {
      case 0:
        return _buildChatTab();
      case 1:
        return const FriendsTab(); // ✅ BẠN BÈ
      case 3:
        return const SettingsPage(); // ✅ CÀI ĐẶT
      default:
        return Center(
          child: Text(
            'Đang phát triển...',
            style: AppTextStyles.welcomeSubtitle.copyWith(color: context.text),
          ),
        );
    }
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        const SizedBox(height: 8),

        // ===== TOP BAR =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.secondary,
                  border: Border.all(color: context.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ===== SEARCH BAR (ăn theme) =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.divider.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: context.text, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      hintStyle: TextStyle(color: context.subtext, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 32,
                  width: 32,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: context.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search, size: 18, color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.notifications_none,
                    size: 20,
                    color: context.subtext,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ===== LIST CHATS =====
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _filteredConversations.length,
            itemBuilder: (context, index) {
              final c = _filteredConversations[index];
              return _ConversationTile(
                conversation: c,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatDetailPage(
                        title: c.name,
                        isGroup: c.isGroup,
                      ),
                    ),
                  );
                },
                onToggleUnread: () => setState(() => c.hasUnread = !c.hasUnread),
                onTogglePinned: () {
                  setState(() {
                    c.isPinned = !c.isPinned;
                    _conversations.sort((a, b) {
                      if (a.isPinned == b.isPinned) return 0;
                      return a.isPinned ? -1 : 1;
                    });
                  });
                },
                onToggleMuted: () => setState(() => c.isMuted = !c.isMuted),
                onDelete: () => setState(() => _conversations.remove(c)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Conversation {
  final String name;
  final String lastMessageDetail;
  final String timeLabel;
  final bool isGroup;

  bool hasUnread;
  bool isPinned;
  bool isMuted;

  _Conversation({
    required this.name,
    required this.lastMessageDetail,
    required this.timeLabel,
    required this.isGroup,
    this.hasUnread = false,
    this.isPinned = false,
    this.isMuted = false,
  });
}

class _ConversationTile extends StatelessWidget {
  final _Conversation conversation;
  final VoidCallback onTap;

  final VoidCallback onToggleUnread;
  final VoidCallback onTogglePinned;
  final VoidCallback onToggleMuted;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onToggleUnread,
    required this.onTogglePinned,
    required this.onToggleMuted,
    required this.onDelete,
  });

  String get _initials {
    final parts = conversation.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  void _showContextMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: position,
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                conversation.hasUnread
                    ? Icons.mark_chat_read_outlined
                    : Icons.mark_chat_unread_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                conversation.hasUnread ? 'Đánh dấu đã đọc' : 'Đánh dấu chưa đọc',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          onTap: () => Future.microtask(onToggleUnread),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                conversation.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                conversation.isPinned ? 'Bỏ ghim đoạn chat' : 'Ghim đoạn chat',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          onTap: () => Future.microtask(onTogglePinned),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                conversation.isMuted
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_active_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                conversation.isMuted ? 'Bật lại thông báo' : 'Tắt thông báo đoạn chat',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          onTap: () => Future.microtask(onToggleMuted),
        ),
        const PopupMenuItem(enabled: false, height: 4, child: Divider(height: 1)),
        PopupMenuItem(
          child: Row(
            children: const [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text('Xoá đoạn chat', style: TextStyle(color: AppColors.error)),
            ],
          ),
          onTap: () => Future.microtask(onDelete),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: radius,
            border: Border.all(color: context.divider.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: conversation.isGroup
                        ? [AppColors.secondary, AppColors.mint]
                        : [context.primary, Theme.of(context).colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: conversation.isGroup
                      ? const Icon(Icons.group, size: 22, color: Colors.white)
                      : Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.text,
                            ),
                          ),
                        ),
                        if (conversation.isPinned)
                          Icon(Icons.push_pin, size: 16, color: context.primary),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conversation.lastMessageDetail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.legalText.copyWith(
                        color: conversation.isGroup ? context.primary : context.subtext,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    conversation.timeLabel,
                    style: AppTextStyles.legalText.copyWith(color: context.subtext),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (conversation.isMuted)
                        Icon(Icons.notifications_off_outlined, size: 14, color: context.subtext),
                      if (conversation.hasUnread) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: context.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
