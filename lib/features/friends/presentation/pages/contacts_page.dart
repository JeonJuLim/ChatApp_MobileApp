import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import 'package:minichatappmobile/core/theme/theme_x.dart';

import '../providers/friends_provider.dart';
import '../../data/models/friend_models.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().load();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsProvider>();

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Danh bạ',
              onSearch: () {},
              onAdd: () => _tab.animateTo(2),
              onScan: () {},
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.divider.withOpacity(0.25)),
                ),
                child: TabBar(
                  controller: _tab,
                  labelColor: context.primary,
                  unselectedLabelColor: context.subtext,
                  indicatorColor: context.primary,
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Bạn bè'),
                    Tab(text: 'Lời mời'),
                    Tab(text: 'Thêm bạn'),
                  ],
                ),
              ),
            ),

            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: _InlineError(text: vm.error!),
              ),

            Expanded(
              child: vm.loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                controller: _tab,
                children: [
                  _FriendsSection(
                    relations: vm.friends,
                    onOpenRequestsTab: () => _tab.animateTo(1),
                  ),
                  _RequestsSection(
                    incoming: vm.incomingRequests,
                    outgoing: vm.outgoingRequests,
                  ),
                  const _AddFriendSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// HEADER
/// =======================
class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onSearch;
  final VoidCallback onAdd;
  final VoidCallback onScan;

  const _Header({
    required this.title,
    required this.onSearch,
    required this.onAdd,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.welcomeTitle.copyWith(color: context.text),
            ),
          ),
          _IconCircle(icon: Icons.search, onTap: onSearch),
          const SizedBox(width: 10),
          _IconCircle(icon: Icons.person_add_alt_1, onTap: onAdd),
          const SizedBox(width: 10),
          _IconCircle(icon: Icons.qr_code_scanner, onTap: onScan),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: context.surface,
          shape: BoxShape.circle,
          border: Border.all(color: context.divider.withOpacity(0.25)),
        ),
        child: Icon(icon, color: context.text, size: 20),
      ),
    );
  }
}

/// =======================
/// TAB 1: BẠN BÈ
/// =======================
class _FriendsSection extends StatelessWidget {
  final List<FriendRelation> relations;
  final VoidCallback onOpenRequestsTab;

  const _FriendsSection({
    required this.relations,
    required this.onOpenRequestsTab,
  });

  @override
  Widget build(BuildContext context) {
    final incomingCount = context.watch<FriendsProvider>().incomingRequests.length;

    if (relations.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        children: [
          _RequestSummaryCard(count: incomingCount, onTap: onOpenRequestsTab),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Chưa có bạn bè',
              style: AppTextStyles.welcomeSubtitle.copyWith(color: context.subtext),
            ),
          ),
        ],
      );
    }

    final groups = <String, List<FriendRelation>>{};
    for (final r in relations) {
      final key = _firstLetter(r.user.fullName);
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(r);
    }

    final sortedKeys = groups.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      children: [
        _RequestSummaryCard(count: incomingCount, onTap: onOpenRequestsTab),
        const SizedBox(height: 14),
        for (final k in sortedKeys) ...[
          _GroupHeader(letter: k),
          const SizedBox(height: 8),
          ...groups[k]!.map(
                (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ContactRow(
                name: r.user.fullName,
                subtitle: r.user.username.isNotEmpty
                    ? '@${r.user.username}'
                    : (r.user.phoneE164 ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionCircle(icon: Icons.chat_bubble_outline, onTap: () {}),
                    const SizedBox(width: 8),
                    _ActionCircle(icon: Icons.call_outlined, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _firstLetter(String name) {
    final s = name.trim();
    if (s.isEmpty) return '#';
    return s.characters.first.toUpperCase();
  }
}

class _GroupHeader extends StatelessWidget {
  final String letter;
  const _GroupHeader({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Text(
      letter,
      style: TextStyle(
        color: context.subtext,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    );
  }
}

class _RequestSummaryCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _RequestSummaryCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.divider.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_alt_1, color: context.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lời mời kết bạn ($count)',
                style: TextStyle(color: context.text, fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.chevron_right, color: context.subtext),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// TAB 2: LỜI MỜI
/// =======================
class _RequestsSection extends StatelessWidget {
  final List<FriendRelation> incoming;
  final List<FriendRelation> outgoing;

  const _RequestsSection({
    required this.incoming,
    required this.outgoing,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.read<FriendsProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      children: [
        Text(
          'Lời mời đến',
          style: AppTextStyles.welcomeSubtitle.copyWith(color: context.text),
        ),
        const SizedBox(height: 10),

        if (incoming.isEmpty)
          Text('Không có', style: TextStyle(color: context.subtext))
        else
          ...incoming.map(
                (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ContactRow(
                name: r.user.fullName,
                subtitle: r.user.username.isNotEmpty
                    ? '@${r.user.username}'
                    : (r.user.phoneE164 ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionPill(
                      text: 'Từ chối',
                      onTap: () => vm.reject(r.requestId!),
                      filled: false,
                    ),
                    const SizedBox(width: 8),
                    _ActionPill(
                      text: 'Chấp nhận',
                      onTap: () => vm.accept(r.requestId!),
                      filled: true,
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 18),

        Text(
          'Lời mời đã gửi',
          style: AppTextStyles.welcomeSubtitle.copyWith(color: context.text),
        ),
        const SizedBox(height: 10),

        if (outgoing.isEmpty)
          Text('Không có', style: TextStyle(color: context.subtext))
        else
          ...outgoing.map(
                (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ContactRow(
                name: r.user.fullName,
                subtitle: r.user.username.isNotEmpty
                    ? 'Đã gửi lời mời • @${r.user.username}'
                    : 'Đã gửi lời mời • ${r.user.phoneE164 ?? ''}',
                trailing: const _StatusTag(text: 'Đã gửi'),
              ),
            ),
          ),
      ],
    );
  }
}

/// =======================
/// TAB 3: THÊM BẠN (SĐT + USERNAME) — DB THẬT
/// =======================
class _AddFriendSection extends StatefulWidget {
  const _AddFriendSection();

  @override
  State<_AddFriendSection> createState() => _AddFriendSectionState();
}

class _AddFriendSectionState extends State<_AddFriendSection> {
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  String _normalizeToE164VN(String input) {
    final raw = input.trim().replaceAll(' ', '');
    if (raw.isEmpty) return raw;
    if (raw.startsWith('+84')) return raw;
    if (raw.startsWith('0')) return '+84${raw.substring(1)}';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      children: [
        Text(
          'Thêm bạn bằng username',
          style: AppTextStyles.welcomeSubtitle.copyWith(color: context.text),
        ),
        const SizedBox(height: 10),

        _InputCard(
          controller: _usernameCtrl,
          hint: 'Nhập username (VD: ironman)',
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () async {
              final username = _usernameCtrl.text.trim();
              if (username.isEmpty) return;

              await context.read<FriendsProvider>().sendRequestByUsername(username);

              if (!mounted) return;
              if (vm.error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã gửi lời mời tới @$username')),
                );
                _usernameCtrl.clear();
              }
            },
            child: const Text('Gửi lời mời (Username)'),
          ),
        ),

        const SizedBox(height: 18),
        Divider(color: context.divider.withOpacity(0.25)),
        const SizedBox(height: 18),

        Text(
          'Thêm bạn bằng số điện thoại',
          style: AppTextStyles.welcomeSubtitle.copyWith(color: context.text),
        ),
        const SizedBox(height: 10),

        _InputCard(
          controller: _phoneCtrl,
          hint: 'Nhập SĐT (VD: 0839610128)',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () async {
              final e164 = _normalizeToE164VN(_phoneCtrl.text);
              if (e164.isEmpty) return;

              await context.read<FriendsProvider>().sendRequest(e164);

              if (!mounted) return;
              if (vm.error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã gửi lời mời tới $e164')),
                );
                _phoneCtrl.clear();
              }
            },
            child: const Text('Gửi lời mời (SĐT)'),
          ),
        ),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _InputCard({
    required this.controller,
    required this.hint,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.divider.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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

/// =======================
/// COMPONENTS
/// =======================
class _ContactRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final Widget trailing;

  const _ContactRow({
    required this.name,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.divider.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          _Avatar(letter: _initial(name)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: context.text, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: context.subtext, fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  String _initial(String s) {
    final t = s.trim();
    if (t.isEmpty) return 'A';
    return t.characters.first.toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  final String letter;
  const _Avatar({required this.letter});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: context.primary.withOpacity(0.18),
      child: Text(
        letter,
        style: TextStyle(color: context.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: context.primary.withOpacity(0.10),
          shape: BoxShape.circle,
          border: Border.all(color: context.primary.withOpacity(0.18)),
        ),
        child: Icon(icon, size: 18, color: context.primary),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool filled;

  const _ActionPill({
    required this.text,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? context.primary : context.surface;
    final fg = filled ? Colors.white : context.text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.divider.withOpacity(0.25)),
        ),
        child: Text(
          text,
          style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String text;
  const _StatusTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.primary.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(color: context.primary, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String text;
  const _InlineError({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.22)),
      ),
      child: Text(
        text.replaceFirst('Exception: ', ''),
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
      ),
    );
  }
}
