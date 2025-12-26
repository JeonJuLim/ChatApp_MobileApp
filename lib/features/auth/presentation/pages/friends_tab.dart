import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:minichatappmobile/core/theme/theme_x.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/chat_detail_page.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final _searchCtrl = TextEditingController();

  int _friendRequestsCount = 19;

  // Mock data: bạn bè (sau nối API)
  final List<_Friend> _friends = [
    _Friend(name: 'Tran B', avatarSeed: 'TB'),
    _Friend(name: 'Tran C', avatarSeed: 'TC'),
    _Friend(name: 'A', avatarSeed: 'A'),
    _Friend(name: 'Acds', avatarSeed: 'AC'),
    _Friend(name: 'B', avatarSeed: 'B'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  List<_Friend> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _friends;
    return _friends.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  String _firstLetter(String name) {
    final s = name.trim();
    if (s.isEmpty) return '#';
    return s.substring(0, 1).toUpperCase();
  }

  Map<String, List<_Friend>> _groupByInitial(List<_Friend> list) {
    final map = <String, List<_Friend>>{};
    for (final f in list) {
      final key = _firstLetter(f.name);
      map.putIfAbsent(key, () => []);
      map[key]!.add(f);
    }

    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });

    final sorted = <String, List<_Friend>>{};
    for (final k in keys) {
      final items = [...map[k]!]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      sorted[k] = items;
    }
    return sorted;
  }

  // =========================
  // ACTIONS
  // =========================

  Future<void> _openAddFriendSheet() async {
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    // 0 = phone, 1 = email
    int mode = 0;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              void setMode(int v) => setModalState(() => mode = v);

              return _SheetCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // handle
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.divider.withOpacity(0.40),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // header
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: context.primary.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.primary.withOpacity(0.18)),
                          ),
                          child: Icon(Icons.person_add_alt_1, color: context.primary, size: 19),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thêm bạn',
                                style: TextStyle(
                                  color: context.text,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Chọn 1 cách để gửi lời mời',
                                style: TextStyle(
                                  color: context.subtext,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: context.subtext),
                          splashRadius: 22,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // segmented choice
                    _SegmentedChoice(
                      index: mode,
                      onChanged: setMode,
                      left: (icon: Icons.phone_iphone_rounded, label: 'SĐT'),
                      right: (icon: Icons.alternate_email_rounded, label: 'Email'),
                    ),

                    const SizedBox(height: 12),

                    // content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: mode == 0
                          ? Column(
                        key: const ValueKey('phone'),
                        children: [
                          _Input(
                            controller: phoneCtrl,
                            hint: 'Ví dụ: 09xx...',
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                final phone = phoneCtrl.text.trim();
                                if (phone.isEmpty) {
                                  _toast('Vui lòng nhập số điện thoại.');
                                  return;
                                }
                                Navigator.pop(context);
                                _toast('Đã gửi lời mời tới SĐT: $phone (mock).');
                                // TODO: gọi API gửi lời mời theo SĐT
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.send_rounded, size: 18),
                                  SizedBox(width: 10),
                                  Text(
                                    'KẾT BẠN BẰNG SĐT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                          : Column(
                        key: const ValueKey('email'),
                        children: [
                          _Input(
                            controller: emailCtrl,
                            hint: 'Ví dụ: abc@gmail.com',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                final email = emailCtrl.text.trim();
                                if (email.isEmpty) {
                                  _toast('Vui lòng nhập Email.');
                                  return;
                                }
                                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(email);
                                if (!ok) {
                                  _toast('Email không hợp lệ.');
                                  return;
                                }

                                Navigator.pop(context);
                                _toast('Đã gửi lời mời tới Email: $email (mock).');
                                // TODO: gọi API gửi lời mời theo Email
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.mail_outline_rounded, size: 18),
                                  SizedBox(width: 10),
                                  Text(
                                    'KẾT BẠN BẰNG EMAIL',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // QR (always visible)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.divider.withOpacity(0.35)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: context.text,
                          backgroundColor: context.bg.withOpacity(0.18),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          final qr = await Navigator.of(context).push<String>(
                            MaterialPageRoute(builder: (_) => const QrScanPage()),
                          );
                          if (qr == null) return;
                          _toast('Đã quét QR: $qr');
                          // TODO: parse qr -> gọi API
                        },
                        icon: Icon(Icons.qr_code_scanner, color: context.primary),
                        label: const Text(
                          'QUÉT QR',
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    emailCtrl.dispose();
    phoneCtrl.dispose();
  }

  Future<void> _openFriendRequests() async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => FriendRequestsPage(initialCount: _friendRequestsCount),
      ),
    );

    if (result != null && mounted) {
      setState(() => _friendRequestsCount = result);
    }
  }

  void _openChat(_Friend f) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(title: f.name, isGroup: false),
      ),
    );
  }

  void _callFriend(_Friend f) {
    _toast('Gọi ${f.name} (demo)');
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    final groups = _groupByInitial(_filtered);

    return Container(
      color: context.bg,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _SearchBar(
                      controller: _searchCtrl,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CircleIcon(
                    icon: Icons.person_add_alt_1,
                    onTap: _openAddFriendSheet,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // FRIEND REQUESTS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _openFriendRequests,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.divider.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.primary.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_add, color: context.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lời mời kết bạn',
                          style: TextStyle(
                            color: context.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _Badge(count: _friendRequestsCount),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, color: context.subtext),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // LIST FRIENDS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  for (final entry in groups.entries) ...[
                    _SectionHeader(letter: entry.key),
                    const SizedBox(height: 8),
                    for (final f in entry.value) ...[
                      _FriendRow(
                        friend: f,
                        onTap: () => _openChat(f),
                        onChat: () => _openChat(f),
                        onCall: () => _callFriend(f),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// MODELS
// =========================

class _Friend {
  final String name;
  final String avatarSeed;
  const _Friend({required this.name, required this.avatarSeed});
}

// =========================
// WIDGETS
// =========================

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.divider.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, size: 18, color: context.subtext),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              style: TextStyle(color: context.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: context.subtext),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.tune, color: context.subtext, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String letter;
  const _SectionHeader({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          letter,
          style: TextStyle(
            color: context.subtext,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            color: context.divider.withOpacity(0.25),
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _FriendRow extends StatelessWidget {
  final _Friend friend;
  final VoidCallback onTap;
  final VoidCallback onChat;
  final VoidCallback onCall;

  const _FriendRow({
    required this.friend,
    required this.onTap,
    required this.onChat,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.divider.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.primary.withOpacity(0.25),
              child: Text(
                friend.avatarSeed,
                style: TextStyle(
                  color: context.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                friend.name,
                style: TextStyle(
                  color: context.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _ActionIcon(icon: Icons.chat_bubble_outline, onTap: onChat),
            const SizedBox(width: 10),
            _ActionIcon(icon: Icons.call_outlined, onTap: onCall),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: context.primary.withOpacity(0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: context.primary),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: context.primary.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  final Widget child;
  const _SheetCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: context.divider.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: child,
    );
  }
}

class _SegmentedChoice extends StatelessWidget {
  final int index;
  final void Function(int) onChanged;
  final ({IconData icon, String label}) left;
  final ({IconData icon, String label}) right;

  const _SegmentedChoice({
    required this.index,
    required this.onChanged,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    Widget item({
      required bool active,
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 44,
            decoration: BoxDecoration(
              color: active ? context.primary.withOpacity(0.14) : context.bg.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? context.primary.withOpacity(0.35)
                    : context.divider.withOpacity(0.22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: active ? context.primary : context.subtext),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? context.text : context.subtext,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.bg.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          item(
            active: index == 0,
            icon: left.icon,
            label: left.label,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 8),
          item(
            active: index == 1,
            icon: right.icon,
            label: right.label,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bg.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider.withOpacity(0.22)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.surface.withOpacity(0.60),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.divider.withOpacity(0.18)),
            ),
            child: Icon(icon, color: context.subtext, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(color: context.text, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: context.subtext, fontWeight: FontWeight.w600),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// QR SCAN PAGE
// =========================

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        foregroundColor: context.text,
        title: Text(
          'Quét QR',
          style: TextStyle(color: context.text, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Bật/tắt đèn',
            onPressed: () => _controller.toggleTorch(),
            icon: Icon(Icons.flash_on, color: context.text),
          ),
          IconButton(
            tooltip: 'Đổi camera',
            onPressed: () => _controller.switchCamera(),
            icon: Icon(Icons.cameraswitch, color: context.text),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_handled) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final raw = barcodes.first.rawValue;
              if (raw == null || raw.trim().isEmpty) return;

              _handled = true;
              Navigator.pop(context, raw.trim());
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Đưa QR vào trong khung để quét.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// FRIEND REQUESTS PAGE (mock)
// =========================

class FriendRequestsPage extends StatefulWidget {
  final int initialCount;
  const FriendRequestsPage({super.key, required this.initialCount});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  late int _count;

  final List<_Request> _requests = [
    _Request(name: 'Nguyen X', subtitle: 'abc@gmail.com'),
    _Request(name: 'Tran Y', subtitle: 'y@gmail.com'),
    _Request(name: 'Le Z', subtitle: 'z@gmail.com'),
  ];

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _accept(_Request r) {
    setState(() {
      _requests.remove(r);
      _count = (_count - 1).clamp(0, 999);
    });
    _toast('Đã chấp nhận ${r.name} (mock)');
  }

  void _deny(_Request r) {
    setState(() {
      _requests.remove(r);
      _count = (_count - 1).clamp(0, 999);
    });
    _toast('Đã từ chối ${r.name} (mock)');
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_count);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: context.bg,
          foregroundColor: context.text,
          elevation: 0,
          title: Text(
            'Lời mời kết bạn ($_count)',
            style: TextStyle(color: context.text, fontWeight: FontWeight.w900),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.text),
            onPressed: () => Navigator.of(context).pop(_count),
          ),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          itemCount: _requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = _requests[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.divider.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: context.primary.withOpacity(0.25),
                    child: Text(
                      r.initials,
                      style: TextStyle(
                        color: context.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: TextStyle(color: context.text, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(r.subtitle, style: TextStyle(color: context.subtext)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _MiniBtn(
                    label: 'Từ chối',
                    onTap: () => _deny(r),
                    color: context.subtext.withOpacity(0.15),
                    textColor: context.text,
                  ),
                  const SizedBox(width: 8),
                  _MiniBtn(
                    label: 'Chấp nhận',
                    onTap: () => _accept(r),
                    color: context.primary,
                    textColor: Colors.white,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Request {
  final String name;
  final String subtitle;
  _Request({required this.name, required this.subtitle});

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class _MiniBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const _MiniBtn({
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
