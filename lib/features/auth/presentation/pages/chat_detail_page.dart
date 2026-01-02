import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

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

enum _MsgType { text, image, file }

class _Attachment {
  final String name;
  final String path; // local path OR remote url
  final int sizeBytes;
  final String? mimeType;

  const _Attachment({
    required this.name,
    required this.path,
    required this.sizeBytes,
    this.mimeType,
  });

  bool get isRemote => path.startsWith('http://') || path.startsWith('https://');
}

class _Message {
  final _MsgType type;
  final bool fromMe;
  final String time;

  final String? text; // for text message
  final _Attachment? attachment; // for image/file

  const _Message({
    required this.type,
    required this.fromMe,
    required this.time,
    this.text,
    this.attachment,
  });
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final _picker = ImagePicker();
  final Dio _dio = Dio();

  final List<_Message> _messages = [];

  @override
  void initState() {
    super.initState();

    _messages.addAll([
      _Message(
        type: _MsgType.text,
        text: 'Hello ${widget.title} 👋',
        fromMe: true,
        time: '09:30',
      ),
      const _Message(
        type: _MsgType.text,
        text: 'Chào bạn, đây là đoạn chat demo.',
        fromMe: false,
        time: '09:31',
      ),
      const _Message(
        type: _MsgType.text,
        text: 'Giờ có thể gửi ảnh & file (demo local).',
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

  // =========================
  // Actions
  // =========================

  void _sendTextMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _Message(
          type: _MsgType.text,
          text: text,
          fromMe: true,
          time: _fakeTimeNow(),
        ),
      );
    });
    _messageController.clear();
    _scrollToBottom();
  }

  /// FIX TRIỆT ĐỂ: pop bằng sheetContext, không pop bằng context page
  Future<void> _openAttachSheet() async {
    final parentContext = context;

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Future<void> closeSheet() async {
          if (Navigator.of(sheetContext).canPop()) {
            Navigator.of(sheetContext).pop();
          }
          // tránh race: sheet chưa đóng hẳn mà đã mở picker
          await Future.delayed(const Duration(milliseconds: 80));
        }

        return _AttachSheet(
          bg: parentContext.bg,
          surface: parentContext.surface,
          text: parentContext.text,
          subtext: parentContext.subtext,
          divider: parentContext.divider,
          primary: parentContext.primary,
          onPickImage: () async {
            await closeSheet();
            if (!mounted) return;
            await _pickImage();
          },
          onPickFile: () async {
            await closeSheet();
            if (!mounted) return;
            await _pickFile();
          },
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return;

      final file = File(x.path);
      final size = await file.length();

      final att = _Attachment(
        name: x.name,
        path: file.path,
        sizeBytes: size,
        mimeType: 'image/*',
      );

      if (!mounted) return;
      setState(() {
        _messages.add(
          _Message(
            type: _MsgType.image,
            fromMe: true,
            time: _fakeTimeNow(),
            attachment: att,
          ),
        );
      });

      _scrollToBottom();
    } catch (e) {
      _toast('Không thể chọn ảnh: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: false,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final f = result.files.first;
      final path = f.path;
      if (path == null) {
        _toast('File không có đường dẫn (path null).');
        return;
      }

      final att = _Attachment(
        name: f.name,
        path: path,
        sizeBytes: f.size,
        mimeType: f.extension,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(
          _Message(
            type: _MsgType.file,
            fromMe: true,
            time: _fakeTimeNow(),
            attachment: att,
          ),
        );
      });

      _scrollToBottom();
    } catch (e) {
      _toast('Không thể chọn file: $e');
    }
  }

  Future<void> _onTapAttachment(_Attachment att) async {
    try {
      if (!att.isRemote) {
        await OpenFilex.open(att.path);
        return;
      }

      final saved = await _downloadToTemp(att.path, att.name);
      await OpenFilex.open(saved);
    } catch (e) {
      _toast('Không mở được file: $e');
    }
  }

  // =========================
  // Helpers
  // =========================

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 220),
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024.0;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024.0;
    return '${gb.toStringAsFixed(2)} GB';
  }

  Future<String> _downloadToTemp(String url, String fileName) async {
    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/$fileName';

    await _dio.download(url, savePath);
    return savePath;
  }

  // =========================
  // UI
  // =========================

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
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                return _MessageBubble(
                  message: m,
                  bubbleRadius: radius,
                  onTapAttachment: _onTapAttachment,
                  formatBytes: _formatBytes,
                );
              },
            ),
          ),
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
                    onPressed: _openAttachSheet,
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
                        onSubmitted: (_) => _sendTextMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _sendTextMessage,
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
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  final double bubbleRadius;

  final Future<void> Function(_Attachment att) onTapAttachment;
  final String Function(int bytes) formatBytes;

  const _MessageBubble({
    required this.message,
    required this.bubbleRadius,
    required this.onTapAttachment,
    required this.formatBytes,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.fromMe;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;

    final bgColor = isMe ? context.primary : context.surface;
    final textColor = isMe ? Colors.white : context.text;

    final r = bubbleRadius;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
      bottomLeft: Radius.circular(isMe ? r : (r <= 10 ? 4 : 6)),
      bottomRight: Radius.circular(isMe ? (r <= 10 ? 4 : 6) : r),
    );

    Widget content;

    switch (message.type) {
      case _MsgType.text:
        content = Text(
          message.text ?? '',
          style: AppTextStyles.legalText.copyWith(
            color: textColor,
            height: 1.3,
          ),
        );
        break;

      case _MsgType.image:
        final att = message.attachment!;
        final img = att.isRemote
            ? Image.network(att.path, fit: BoxFit.cover)
            : Image.file(File(att.path), fit: BoxFit.cover);

        content = ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.62,
            height: 220,
            child: img,
          ),
        );
        break;

      case _MsgType.file:
        final att = message.attachment!;
        content = InkWell(
          onTap: () => onTapAttachment(att),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.white.withOpacity(0.12) : context.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.divider.withOpacity(0.20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file_rounded,
                  color: isMe ? Colors.white : context.primary,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        att.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.legalText.copyWith(
                          color: isMe ? Colors.white : context.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatBytes(att.sizeBytes),
                        style: AppTextStyles.legalText.copyWith(
                          fontSize: 11,
                          color: isMe ? Colors.white.withOpacity(0.80) : context.subtext,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        break;
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
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
            content,
            const SizedBox(height: 6),
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

class _AttachSheet extends StatelessWidget {
  final Color bg;
  final Color surface;
  final Color text;
  final Color subtext;
  final Color divider;
  final Color primary;

  final VoidCallback onPickImage;
  final VoidCallback onPickFile;

  const _AttachSheet({
    required this.bg,
    required this.surface,
    required this.text,
    required this.subtext,
    required this.divider,
    required this.primary,
    required this.onPickImage,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(top: BorderSide(color: divider.withOpacity(0.25))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: divider.withOpacity(0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          _SheetItem(
            icon: Icons.image_rounded,
            title: 'Chọn ảnh',
            subtitle: 'Gửi ảnh từ thư viện',
            primary: primary,
            text: text,
            subtext: subtext,
            onTap: onPickImage,
          ),
          const SizedBox(height: 10),
          _SheetItem(
            icon: Icons.attach_file_rounded,
            title: 'Chọn file',
            subtitle: 'PDF, DOCX, ZIP, ...',
            primary: primary,
            text: text,
            subtext: subtext,
            onTap: onPickFile,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primary;
  final Color text;
  final Color subtext;
  final VoidCallback onTap;

  const _SheetItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.text,
    required this.subtext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: text, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtext, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subtext),
          ],
        ),
      ),
    );
  }
}
