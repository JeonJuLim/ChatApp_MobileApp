import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:minichatappmobile/core/config/app_config.dart';
import 'package:minichatappmobile/core/socket/socket_service.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';

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

  /* =========================
     INIT
  ========================= */
  @override
  void initState() {
    super.initState();

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

                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                      isMe ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.text,
                          style: AppTextStyles.legalText.copyWith(
                            color: isMe
                                ? Colors.white
                                : AppColors.textPrimary,
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
                            if (isMe) ...[
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
                  'đang nhập...',
                  style: TextStyle(fontSize: 12),
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
                        hintText: 'Nhắn tin...',
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
