import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:minichatappmobile/core/config/app_config.dart';
import 'package:minichatappmobile/core/socket/socket_service.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import 'package:http/http.dart' as http;


class ChatDetailPage extends StatefulWidget {
  final String title;
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
  String _getUserName(String userId) {
    return 'User ${userId.substring(0, 4)}'; // TODO: map thật
  }

  String _getAvatarUrl(String userId) {
    return 'https://i.pravatar.cc/150?u=$userId';
  }
  /* =========================
     INIT
  ========================= */
  @override
  void initState() {
    super.initState();
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
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                    isGroup &&
                        !isMe &&
                        (prev == null || prev.senderId != m.senderId);


                final isLastMyMessage =
                    isMe &&
                        i == _messages.lastIndexWhere(
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
                            backgroundImage:
                            NetworkImage(_getAvatarUrl(m.senderId)),
                          )
                              : const SizedBox(width: 32), // giữ alignment
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
                                      color:
                                      isMe ? Colors.white : AppColors.textPrimary,
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
                                          color: isMe
                                              ? Colors.white70
                                              : AppColors.textSecondary,
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
