import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:minichatappmobile/core/config/app_config.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';

class ChatDetailPage extends StatefulWidget {
  final String title;
  final bool isGroup;
  final String conversationId;
  final String myUserId;

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

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<_Message> _messages = [];
  Timer? _poller;
  bool _loading = false;

  // =========================
  // INIT
  // =========================
  @override
  void initState() {
    super.initState();

    debugPrint(
      '🧩 ChatDetail INIT | user=${widget.myUserId} | room=${widget.conversationId}',
    );

    _loadMessages();

    // 🔁 Polling mỗi 1 giây
    _poller = Timer.periodic(
      const Duration(seconds: 1),
          (_) => _loadMessages(),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // =========================
  // LOAD MESSAGE HISTORY
  // =========================
  Future<void> _loadMessages() async {
    if (_loading) return;
    _loading = true;

    try {
      final res = await http.get(
        Uri.parse(
          '${AppConfig.apiBaseUrl}/messages/${widget.conversationId}',
        ),
      );

      if (res.statusCode != 200) return;

      final list = jsonDecode(res.body) as List;

      setState(() {
        _messages
          ..clear()
          ..addAll(
            list.map(
                  (m) => _Message(
                text: m['content'] ?? '',
                fromMe: m['senderId'] == widget.myUserId,
                time: _formatTime(
                  DateTime.parse(m['createdAt']),
                ),
              ),
            ),
          );
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ Load messages error: $e');
    } finally {
      _loading = false;
    }
  }

  // =========================
  // SEND MESSAGE (REST)
  // =========================
  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    _messageCtrl.clear();

    try {
      await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conversationId': widget.conversationId,
          'senderId': widget.myUserId,
          'content': text,
          'type': 'text',
        }),
      );

      // Reload messages sau khi gửi
      await _loadMessages();
    } catch (e) {
      debugPrint('❌ Send message error: $e');
    }
  }

  // =========================
  // HELPERS
  // =========================
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(
          _scrollCtrl.position.maxScrollExtent + 80,
        );
      }
    });
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // =========================
  // UI
  // =========================
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
            CircleAvatar(
              radius: 18,
              backgroundColor:
              widget.isGroup ? AppColors.secondary : AppColors.primary,
              child: widget.isGroup
                  ? const Icon(Icons.group, size: 18, color: Colors.white)
                  : Text(
                _initials(widget.title),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // =========================
          // MESSAGE LIST
          // =========================
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return _MessageBubble(message: m);
              },
            ),
          ),

          // =========================
          // INPUT
          // =========================
          SafeArea(
            top: false,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Nhắn tin...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
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

// =========================
// MODELS
// =========================

class _Message {
  final String text;
  final bool fromMe;
  final String time;

  _Message({
    required this.text,
    required this.fromMe,
    required this.time,
  });
}

class _MessageBubble extends StatelessWidget {
  final _Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.fromMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTextStyles.legalText.copyWith(
                color:
                isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.time,
              style: AppTextStyles.legalText.copyWith(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withOpacity(0.8)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
