// contacts_page.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:minichatappmobile/core/config/app_config.dart';

import 'models.dart';

// ✅ Pages bạn đã có
import 'package:minichatappmobile/features/auth/presentation/pages/chat_detail_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/call/voice_call_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/call/video_call_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  List<FriendRelation> _relations = [];
  bool _loading = true;
  String? _error;

  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _token = '';
  String _myUserId = '';

  // ✅ Dio dùng baseUrl từ AppConfig
  late final Dio _dio;

  static const String _tokenKey = 'accessToken';

  @override
  void initState() {
    super.initState();

    _tab = TabController(length: 3, vsync: this);

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl, // ✅ lấy baseurl từ app_config
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _loadTokenAndData();
  }

  // =============================
  // Helper: attach token nếu chưa có
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

  Future<void> _loadTokenAndData() async {
    final ok = await _ensureAuthHeader();
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Bạn chưa đăng nhập';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ?? '';
    _token = token;
    _myUserId = _getUserIdFromJwt(_token);

    if (_myUserId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Token không hợp lệ (không lấy được userId)';
      });
      return;
    }

    await _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok = await _ensureAuthHeader();
      if (!ok) throw Exception('Missing token');

      // ✅ Không hardcode IP nữa
      final res = await _dio.get('/friends/relations');

      final raw = res.data;
      List<dynamic> list = [];

      if (raw is List) list = raw;
      if (raw is Map) {
        list = raw['data'] ?? raw['items'] ?? raw['relations'] ?? [];
      }

      if (!mounted) return;
      setState(() {
        _relations = list
            .whereType<Map>()
            .map((e) => FriendRelation.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi load danh sách bạn bè';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendRequestByUsername(String username) async {
    final u = username.trim();
    if (u.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập username')),
      );
      return;
    }

    try {
      final ok = await _ensureAuthHeader();
      if (!ok) throw Exception('Missing token');

      await _dio.post(
        '/friends/request-by-username',
        data: {'username': u},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi lời mời tới @$u')),
      );
      _usernameCtrl.clear();
      await _fetchFriends();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi gửi lời mời')),
      );
    }
  }

  Future<void> _sendRequestByPhone(String phone) async {
    final p = phone.trim();
    if (p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
      return;
    }

    try {
      final ok = await _ensureAuthHeader();
      if (!ok) throw Exception('Missing token');

      await _dio.post(
        '/friends/request',
        data: {'phoneE164': p},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi lời mời tới $p')),
      );
      _phoneCtrl.clear();
      await _fetchFriends();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi gửi lời mời')),
      );
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      final ok = await _ensureAuthHeader();
      if (!ok) throw Exception('Missing token');

      await _dio.post(
        '/friends/requests/accept',
        data: {'requestId': requestId},
      );
      await _fetchFriends();
    } catch (_) {}
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      final ok = await _ensureAuthHeader();
      if (!ok) throw Exception('Missing token');

      await _dio.post(
        '/friends/requests/reject',
        data: {'requestId': requestId},
      );
      await _fetchFriends();
    } catch (_) {}
  }

  // ============================================================
  // ✅ JWT -> myUserId (sub/userId/id)
  // ============================================================
  String _getUserIdFromJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return '';

      final normalized = base64Url.normalize(parts[1]);
      final bytes = base64Url.decode(normalized);
      final payload = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      return (payload['sub'] ?? payload['userId'] ?? payload['id'] ?? '')
          .toString();
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // ✅ Lấy/Tạo conversation 1-1 để mở chat/call/video
  // IMPORTANT: endpoint này phải tồn tại trên backend của bạn.
  // ============================================================
  Future<String> _ensureDirectConversationId(String peerUserId) async {
    final ok = await _ensureAuthHeader();
    if (!ok) throw Exception('Missing token');

    final res = await _dio.post(
      '/conversations/direct',
      data: {'peerUserId': peerUserId},
    );

    final data = res.data;

    if (data is Map) {
      final directId = data['conversationId'] ?? data['id'];
      if (directId != null) return directId.toString();

      final wrap = data['data'];
      if (wrap is Map) {
        final wrapId = wrap['conversationId'] ?? wrap['id'];
        if (wrapId != null) return wrapId.toString();
      }
    }

    throw Exception('Server không trả conversationId');
  }

  Future<void> _openChat(FriendRelation r) async {
    try {
      final peerId = r.user.id;
      if (peerId.isEmpty) throw Exception('peerUserId rỗng');

      final conversationId = await _ensureDirectConversationId(peerId);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            title: (r.user.fullName.isNotEmpty ? r.user.fullName : r.user.username),
            conversationId: conversationId,
            myUserId: _myUserId,
            isGroup: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được chat: $e')),
      );
    }
  }


  Future<void> _openVoiceCall(FriendRelation r) async {
    try {
      final conversationId = await _ensureDirectConversationId(r.user.id);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceCallPage(
            title: r.user.fullName,
            conversationId: conversationId,
            myUserId: _myUserId,
            isGroup: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được voice call: $e')),
      );
    }
  }

  Future<void> _openVideoCall(FriendRelation r) async {
    try {
      final conversationId = await _ensureDirectConversationId(r.user.id);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallPage(
            title: r.user.fullName,
            conversationId: conversationId,
            myUserId: _myUserId,
            isGroup: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được video call: $e')),
      );
    }
  }

  // ============================================================
  // UI HELPERS
  // ============================================================
  Map<String, List<FriendRelation>> _groupByFirstLetter(List<FriendRelation> list) {
    final map = <String, List<FriendRelation>>{};
    for (final r in list) {
      final name = (r.user.fullName).trim();
      final letter = name.isEmpty ? '#' : name[0].toUpperCase();
      (map[letter] ??= []).add(r);
    }
    final keys = map.keys.toList()..sort();
    return {for (final k in keys) k: map[k]!};
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friends = _relations
        .where((r) => r.status == FriendRelationStatus.friend)
        .toList();

    final incoming = _relations
        .where((r) => r.status == FriendRelationStatus.incomingRequest)
        .toList();

    final outgoing = _relations
        .where((r) => r.status == FriendRelationStatus.outgoingRequest)
        .toList();

    final bestFriends = friends.take(2).toList();
    final otherFriends = friends.skip(2).toList();
    final grouped = _groupByFirstLetter(otherFriends);

    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ FIX 1: KHÔNG DỰNG BOTTOM NAV Ở ĐÂY NỮA
      // bottomNavigationBar: ... (đã xóa)

      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : Column(
          children: [
            // ===== TOP BAR =====
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.search, size: 20, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CircleIconButton(
                    icon: Icons.person_add_alt_1,
                    onTap: () => _tab.animateTo(2),
                  ),
                ],
              ),
            ),

            // ===== Friend Requests Line =====
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _tab.animateTo(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF2F80ED),
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lời mời kết bạn (${incoming.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),

            // ===== TAB VIEW (ẩn TabBar) =====
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  // TAB 1: Friends
                  ListView(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    children: [
                      if (bestFriends.isNotEmpty) ...[
                        const _SectionHeader(title: 'Bạn thân', leading: '⭐'),
                        const SizedBox(height: 6),
                        ...bestFriends.map(
                              (r) => _ContactRow(
                            name: r.user.fullName,
                            subtitle: r.user.username,
                            onChat: () => _openChat(r),
                            onCall: () => _openVoiceCall(r),
                            onVideo: () => _openVideoCall(r),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      ...grouped.entries.expand((entry) {
                        final letter = entry.key;
                        final items = entry.value;
                        return [
                          _LetterDivider(letter: letter),
                          ...items.map(
                                (r) => _ContactRow(
                              name: r.user.fullName,
                              subtitle: r.user.username,
                              onChat: () => _openChat(r),
                              onCall: () => _openVoiceCall(r),
                              onVideo: () => _openVideoCall(r),
                            ),
                          ),
                        ];
                      }).toList(),
                    ],
                  ),

                  // TAB 2: Requests
                  ListView(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    children: [
                      const _SectionHeader(title: 'Lời mời đến', leading: '📥'),
                      const SizedBox(height: 6),
                      ...incoming.map(
                            (r) => _InviteRow(
                          name: r.user.fullName,
                          subtitle: r.user.username,
                          onAccept: () => _acceptRequest(r.requestId!),
                          onReject: () => _rejectRequest(r.requestId!),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 10),
                      const _SectionHeader(title: 'Đã gửi', leading: '📤'),
                      const SizedBox(height: 6),
                      ...outgoing.map(
                            (r) => _InfoRow(
                          name: r.user.fullName,
                          subtitle: 'Đã gửi lời mời • ${r.user.username}',
                        ),
                      ),
                    ],
                  ),

                  // TAB 3: Add friend
                  ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      const _SectionHeader(title: 'Thêm bạn', leading: '➕'),
                      const SizedBox(height: 12),
                      _InputCard(
                        title: 'Theo Username',
                        child: Column(
                          children: [
                            TextField(
                              controller: _usernameCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Nhập username',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () => _sendRequestByUsername(_usernameCtrl.text),
                                child: const Text('Gửi lời mời'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InputCard(
                        title: 'Theo Số điện thoại (E.164)',
                        child: Column(
                          children: [
                            TextField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(
                                hintText: '+84xxxxxxxxx',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () => _sendRequestByPhone(_phoneCtrl.text),
                                child: const Text('Gửi lời mời'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== UI COMPONENTS (chỉ giao diện) =====================

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String leading;

  const _SectionHeader({required this.title, required this.leading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(leading, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    );
  }
}

class _LetterDivider extends StatelessWidget {
  final String letter;

  const _LetterDivider({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        children: [
          Text(letter, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          const Expanded(child: Divider(height: 1)),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onChat;
  final VoidCallback onCall;
  final VoidCallback onVideo;

  const _ContactRow({
    required this.name,
    required this.subtitle,
    required this.onChat,
    required this.onCall,
    required this.onVideo,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFFFD54F),
            child: Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _MiniAction(icon: Icons.chat_bubble, onTap: onChat),
          _MiniAction(icon: Icons.phone, onTap: onCall),
          _MiniAction(icon: Icons.videocam, onTap: onVideo),
        ],
      ),
    );
  }
}

class _InviteRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _InviteRow({
    required this.name,
    required this.subtitle,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFFFD54F),
            child: Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _MiniAction(icon: Icons.check, onTap: onAccept),
          _MiniAction(icon: Icons.close, onTap: onReject),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String name;
  final String subtitle;

  const _InfoRow({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFFFD54F),
            child: Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InputCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
