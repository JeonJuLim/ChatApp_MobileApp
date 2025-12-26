import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';
import 'package:minichatappmobile/core/theme/theme_x.dart';
import 'package:minichatappmobile/core/theme/app_appearance.dart';

class ChatDetailPage extends StatefulWidget {
  final String title;
  final bool isGroup;

  const ChatDetailPage({
    super.key,
    required this.title,
    this.isGroup = false,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_Message> _messages = [];

  @override
  void initState() {
    super.initState();

    _messages.addAll([
      _Message(
        text: 'Hello ${widget.title} 👋',
        fromMe: true,
        time: '09:30',
      ),
      _Message(
        text: 'Chào bạn, đây là đoạn chat demo.',
        fromMe: false,
        time: '09:31',
      ),
      _Message(
        text: 'Sau này sẽ thay bằng dữ liệu từ backend + socket.',
        fromMe: true,
        time: '09:32',
      ),
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _Message(
          text: text,
          fromMe: true,
          time: _fakeTimeNow(),
        ),
      );
    });
    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fakeTimeNow() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppAppearance>();
    final radius = appearance.bubbleStyle == BubbleStyle.round ? 18.0 : 8.0;

    return Scaffold(
      backgroundColor: context.bg,

      appBar: AppBar(
        backgroundColor: context.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: context.text),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.isGroup
                  ? Theme.of(context).colorScheme.secondary
                  : context.primary,
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
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: context.text),
          ),
        ],
      ),

      body: Column(
        children: [
          // Danh sách message
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isMe = m.fromMe;
                return _MessageBubble(
                  message: m,
                  isMe: isMe,
                  bubbleRadius: radius,
                );
              },
            ),
          ),

          // Thanh nhập tin nhắn
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: context.bg,
                border: Border(top: BorderSide(color: context.divider.withOpacity(0.25))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add_circle_outline),
                    color: context.primary,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: context.divider.withOpacity(0.25)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(color: context.text),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Nhắn tin...',
                          hintStyle: TextStyle(color: context.subtext),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.primary,
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}

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
  final bool isMe;
  final double bubbleRadius;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.bubbleRadius,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;

    final bgColor = isMe ? context.primary : context.surface;
    final textColor = isMe ? Colors.white : context.text;

    // Bo góc theo style (round/flat) nhưng vẫn giữ “đuôi” nhẹ
    final r = bubbleRadius;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
      bottomLeft: Radius.circular(isMe ? r : (r <= 10 ? 4 : 6)),
      bottomRight: Radius.circular(isMe ? (r <= 10 ? 4 : 6) : r),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
          border: isMe ? null : Border.all(color: context.divider.withOpacity(0.20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTextStyles.legalText.copyWith(
                color: textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.time,
              style: AppTextStyles.legalText.copyWith(
                fontSize: 10,
                color: isMe ? Colors.white.withOpacity(0.80) : context.subtext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
