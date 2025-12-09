import 'package:flutter/material.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/chat_detail_page.dart';
// Sửa path này cho đúng với file settings_page.dart của bạn
import 'package:minichatappmobile/features/auth/presentation/pages/settings_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0;

  // Fake data list chat (KHÔNG const nữa để có thể cập nhật trạng thái)
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
    return _conversations
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // phần nội dung thay đổi theo tab
            Expanded(child: _buildTabBody()),

            /// BOTTOM NAV
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentTabIndex,
                onTap: (value) {
                  setState(() => _currentTabIndex = value);
                },
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textSecondary,
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

  /// chọn widget theo tab hiện tại
  Widget _buildTabBody() {
    switch (_currentTabIndex) {
      case 0:
        return _buildChatTab();
      case 3:
        return const SettingsPage(); // tab Cài đặt
      default:
        return const Center(
          child: Text(
            'Đang phát triển...',
            style: AppTextStyles.welcomeSubtitle,
          ),
        );
    }
  }

  /// Tab 0: danh sách chat (giữ nguyên UI bạn đã có)
  Widget _buildChatTab() {
    return Column(
      children: [
        const SizedBox(height: 8),

        /// TOP BAR: avatar + nút +
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Avatar tròn mock
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
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
              // Nút thêm cuộc trò chuyện / thêm bạn
              InkWell(
                onTap: () {
                  // TODO: mở màn tạo chat mới
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mint.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        /// SEARCH BAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
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
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.notifications_none,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        /// LIST CHATS
        Expanded(
          child: ListView.builder(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

                // Các action khi chọn từ menu popup
                onToggleUnread: () {
                  setState(() {
                    c.hasUnread = !c.hasUnread;
                  });
                },
                onTogglePinned: () {
                  setState(() {
                    c.isPinned = !c.isPinned;
                    // sắp xếp: cuộc chat ghim lên đầu
                    _conversations.sort((a, b) {
                      if (a.isPinned == b.isPinned) return 0;
                      return a.isPinned ? -1 : 1;
                    });
                  });
                },
                onToggleMuted: () {
                  setState(() {
                    c.isMuted = !c.isMuted;
                  });
                },
                onDelete: () {
                  setState(() {
                    _conversations.remove(c);
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// MODEL một cuộc trò chuyện (cho phép cập nhật một số trạng thái)
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

/// UI mỗi item trong danh sách chat
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
    final parts = conversation.name.split(' ');
    if (parts.length == 1) return parts.first.characters.first;
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  void _showContextMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
              ),
              const SizedBox(width: 8),
              Text(
                conversation.hasUnread
                    ? 'Đánh dấu đã đọc'
                    : 'Đánh dấu chưa đọc',
              ),
            ],
          ),
          onTap: () {
            Future.microtask(onToggleUnread);
          },
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                conversation.isPinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                conversation.isPinned
                    ? 'Bỏ ghim đoạn chat'
                    : 'Ghim đoạn chat',
              ),
            ],
          ),
          onTap: () {
            Future.microtask(onTogglePinned);
          },
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                conversation.isMuted
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_active_outlined,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                conversation.isMuted
                    ? 'Bật lại thông báo'
                    : 'Tắt thông báo đoạn chat',
              ),
            ],
          ),
          onTap: () {
            Future.microtask(onToggleMuted);
          },
        ),
        const PopupMenuItem(
          enabled: false,
          height: 4,
          child: Divider(height: 1),
        ),
        PopupMenuItem(
          child: Row(
            children: const [
              Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.error,
              ),
              SizedBox(width: 8),
              Text(
                'Xoá đoạn chat',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
          onTap: () {
            Future.microtask(onDelete);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: conversation.isGroup
                        ? [AppColors.secondary, AppColors.mint]
                        : [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: conversation.isGroup
                      ? const Icon(
                    Icons.group,
                    size: 22,
                    color: Colors.white,
                  )
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

              // Name + last message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (conversation.isPinned)
                          const Icon(
                            Icons.push_pin,
                            size: 16,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conversation.lastMessageDetail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.legalText.copyWith(
                        color: conversation.isGroup
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Time + dot unread / mute
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    conversation.timeLabel,
                    style: AppTextStyles.legalText,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (conversation.isMuted)
                        const Icon(
                          Icons.notifications_off_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      if (conversation.hasUnread) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
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
