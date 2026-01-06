import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:minichatappmobile/core/config/app_config.dart';
import 'package:minichatappmobile/core/socket/socket_service.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/call/voice_call_page.dart';
import 'package:minichatappmobile/features/auth/presentation/pages/call/video_call_page.dart';

import 'package:http/http.dart' as http;

class ChatDetailPage extends StatefulWidget {
  final String title; // fallback
  final String conversationId;
  final String myUserId;
  final bool isGroup;

  const ChatDetailPage({
    super.key,
    required this.title,
    required this.conversationId,
    required this.myUserId,
    this.isGroup = false,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

/* =========================
   MODEL MESSAGE
========================= */
class _Message {
  final String id;
  final String text;
  final String senderId;
  final DateTime createdAt;

  _Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.createdAt,
  });
}

/* =========================
   PAGE STATE
========================= */
class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<_Message> _messages = [];

  // messageId -> status: sent | delivered | seen
  final Map<String, String> _status = {};

  bool _otherTyping = false;
  Timer? _typingDebounce;

  // ====== FIX: title + peer user ======
  String _appBarTitle = '';
  bool _loadingTitle = true;

  // Map userId -> user info (fullName/username/avatarUrl)
  final Map<String, Map<String, dynamic>> _userCache = {};

  /* =========================
     INIT
  ========================= */
  @override
  void initState() {
    super.initState();

    _appBarTitle = widget.title; // fallback ngay
    _loadConversationTitle(); // ✅ FIX: lấy title đúng theo conversation + members

    _loadHistory();

    debugPrint(
      '🧩 ChatDetail INIT | user=${widget.myUserId} | room=${widget.conversationId}',
    );

    SocketService.I.connect(
      AppConfig.socketUrl,
      onConnected: () {
        SocketService.I.joinConversation(
          widget.conversationId,
          widget.myUserId,
        );
      },
    );

    _initSocketListeners();
  }

  // =============================
  // FIX: GET /conversations/:id => set AppBar title đúng
  // - group: name
  // - direct: tên người còn lại (member != myUserId)
  // =============================
  Future<void> _loadConversationTitle() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/conversations/${widget.conversationId}'),
      );

      if (res.statusCode != 200) {
        throw Exception('Load conversation failed (${res.statusCode})');
      }

      final raw = jsonDecode(res.body);

      Map<String, dynamic>? conv;
      if (raw is Map<String, dynamic>) {
        conv = raw;
      } else if (raw is Map) {
        conv = Map<String, dynamic>.from(raw);
      }

      if (conv == null) {
        if (!mounted) return;
        setState(() => _loadingTitle = false);
        return;
      }

      final type = (conv['type'] ?? '').toString(); // "direct" | "group"
      final name = (conv['name'] ?? '').toString();

      // cache members -> userCache
      final members = conv['members'];
      if (members is List) {
        for (final m in members) {
          if (m is! Map) continue;
          final u = m['user'];
          if (u is! Map) continue;

          final uid = (u['id'] ?? '').toString();
          if (uid.isEmpty) continue;

          _userCache[uid] = Map<String, dynamic>.from(u);
        }
      }

      String nextTitle = widget.title;

      if (type == 'group' || widget.isGroup == true) {
        if (name.trim().isNotEmpty) nextTitle = name.trim();
      } else {
        // direct: tìm user khác mình
        Map<String, dynamic>? peer;
        for (final entry in _userCache.entries) {
          if (entry.key != widget.myUserId) {
            peer = entry.value;
            break;
          }
        }

        if (peer != null) {
          final fullName = (peer['fullName'] ?? '').toString().trim();
          final username = (peer['username'] ?? '').toString().trim();
          nextTitle = fullName.isNotEmpty
              ? fullName
              : (username.isNotEmpty ? username : widget.title);
        }
      }

      if (!mounted) return;
      setState(() {
        _appBarTitle = nextTitle;
        _loadingTitle = false;
      });
    } catch (e) {
      debugPrint('❌ Load conversation title error: $e');
      if (!mounted) return;
      setState(() => _loadingTitle = false);
    }
  }

  Future<void> _loadHistory() async {
    try {
      final res = await http.get(
        Uri.parse(
          '${AppConfig.apiBaseUrl}/messages/${widget.conversationId}',
        ),
      );

      if (res.statusCode != 200) {
        throw Exception('Load messages failed');
      }

      final List list = jsonDecode(res.body);

      setState(() {
        _messages.clear();
        for (final m in list) {
          _messages.add(
            _Message(
              id: m['id'],
              text: m['content'] ?? '',
              senderId: m['senderId'],
              createdAt: DateTime.parse(m['createdAt']),
            ),
          );
          _status[m['id']] = m['status'] ?? 'sent';
        }
      });

      _scrollToBottom();
      _markAllSeen();
    } catch (e) {
      debugPrint('❌ Load history error: $e');
    }
  }

  void _initSocketListeners() {
    /* ---------- NEW MESSAGE ---------- */
    SocketService.I.onNewMessage((data) {
      final m = data is Map ? data : jsonDecode(data.toString());

      final msgId = m['id'] as String;
      final senderId = m['senderId'] as String;

      setState(() {
        _messages.add(
          _Message(
            id: msgId,
            text: m['content'] ?? '',
            senderId: senderId,
            createdAt: DateTime.parse(m['createdAt']),
          ),
        );
        _status[msgId] = 'sent';
      });

      // delivered nếu không phải tin của mình
      if (senderId != widget.myUserId) {
        SocketService.I.markDelivered(
          widget.conversationId,
          widget.myUserId,
          msgId,
        );
      }

      _scrollToBottom();
      _markAllSeen();
    });

    /* ---------- TYPING ---------- */
    SocketService.I.onTyping((data) {
      final m = data is Map ? data : jsonDecode(data.toString());
      if (m['conversationId'] != widget.conversationId) return;
      if (m['userId'] == widget.myUserId) return;

      setState(() {
        _otherTyping = m['isTyping'] == true;
      });
    });

    /* ---------- MESSAGE STATUS ---------- */
    SocketService.I.onMessageStatus((data) {
      final m = data is Map ? data : jsonDecode(data.toString());
      final messageId = m['messageId'] as String;
      final status = m['status'] as String;

      setState(() {
        _status[messageId] = status;
      });
    });
  }

  /* =========================
     DISPOSE
  ========================= */
  @override
  void dispose() {
    SocketService.I.offNewMessage();
    SocketService.I.offTyping();
    SocketService.I.offMessageStatus();
    _typingDebounce?.cancel();
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /* =========================
     SEND MESSAGE
  ========================= */
  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    _messageCtrl.clear();
    SocketService.I.typingStop(
      widget.conversationId,
      widget.myUserId,
    );

    SocketService.I.sendMessage(
      widget.conversationId,
      widget.myUserId,
      text,
    );
  }

  /* =========================
     SEEN
  ========================= */
  void _markAllSeen() {
    for (final m in _messages) {
      if (m.senderId != widget.myUserId) {
        SocketService.I.markSeen(
          widget.conversationId,
          widget.myUserId,
          m.id,
        );
      }
    }
  }

  /* =========================
     HELPERS
  ========================= */
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  // =============================
  // FIX: map thật username/fullName từ _userCache (fallback)
  // =============================
  String _getUserName(String userId) {
    final u = _userCache[userId];
    if (u != null) {
      final fullName = (u['fullName'] ?? '').toString().trim();
      final username = (u['username'] ?? '').toString().trim();
      if (fullName.isNotEmpty) return fullName;
      if (username.isNotEmpty) return username;
    }
    return 'User ${userId.length >= 4 ? userId.substring(0, 4) : userId}';
  }

  String _getAvatarUrl(String userId) {
    final u = _userCache[userId];
    final url = (u?['avatarUrl'] ?? '').toString().trim();
    if (url.isNotEmpty) return url;
    return 'https://i.pravatar.cc/150?u=$userId';
  }

  /* =========================
     UI
  ========================= */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _appBarTitle.isEmpty ? 'Chat' : _appBarTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_loadingTitle)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Call voice',
            icon: const Icon(Icons.call, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VoiceCallPage(
                    title: _appBarTitle.isEmpty ? widget.title : _appBarTitle,
                    conversationId: widget.conversationId,
                    myUserId: widget.myUserId,
                    isGroup: widget.isGroup,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Call video',
            icon: const Icon(Icons.videocam, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VideoCallPage(
                    title: _appBarTitle.isEmpty ? widget.title : _appBarTitle,
                    conversationId: widget.conversationId,
                    myUserId: widget.myUserId,
                    isGroup: widget.isGroup,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          /* ---------- MESSAGE LIST ---------- */
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isMe = m.senderId == widget.myUserId;
                final isGroup = widget.isGroup;

                final prev = i > 0 ? _messages[i - 1] : null;

                final showSenderInfo =
                    isGroup && !isMe && (prev == null || prev.senderId != m.senderId);

                final isLastMyMessage = isMe &&
                    i ==
                        _messages.lastIndexWhere(
                              (msg) => msg.senderId == widget.myUserId,
                        );

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      // ===== AVATAR (chỉ người khác & chỉ khi showSenderInfo) =====
                      if (!isMe)
                        Padding(
                          padding: const EdgeInsets.only(right: 8, top: 2),
                          child: showSenderInfo
                              ? CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(_getAvatarUrl(m.senderId)),
                          )
                              : const SizedBox(width: 32),
                        ),

                      // ===== MESSAGE BUBBLE =====
                      Flexible(
                        child: Column(
                          crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            // ===== USER NAME (group + showSenderInfo) =====
                            if (showSenderInfo)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  _getUserName(m.senderId),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),

                            // ===== BUBBLE =====
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.text,
                                    style: AppTextStyles.legalText.copyWith(
                                      fontSize: 16,
                                      height: 1.35,
                                      color: isMe ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatTime(m.createdAt),
                                        style: AppTextStyles.legalText.copyWith(
                                          fontSize: 10,
                                          color:
                                          isMe ? Colors.white70 : AppColors.textSecondary,
                                        ),
                                      ),
                                      if (isLastMyMessage) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          _status[m.id] == 'seen'
                                              ? '✓✓'
                                              : _status[m.id] == 'delivered'
                                              ? '✓✓'
                                              : '✓',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _status[m.id] == 'seen'
                                                ? Colors.blue
                                                : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          /* ---------- TYPING ---------- */
          if (_otherTyping)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Đang nhập...',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),

          /* ---------- INPUT ---------- */
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      onChanged: (_) {
                        SocketService.I.typingStart(
                          widget.conversationId,
                          widget.myUserId,
                        );

                        _typingDebounce?.cancel();
                        _typingDebounce =
                            Timer(const Duration(milliseconds: 700), () {
                              SocketService.I.typingStop(
                                widget.conversationId,
                                widget.myUserId,
                              );
                            });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Tin nhắn',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: AppColors.primary,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
