

import '../../../../core/models/chat.dart';
import '../../../../core/models/tag.dart';

class ChatDto {
  final String id;
  final String title;
  final String lastMessage;
  final bool isPinned;
  final DateTime updatedAt;
  final List<Tag> tags;

  ChatDto({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.isPinned,
    required this.updatedAt,
    required this.tags,
  });

  Chat toEntity() {
    return Chat(
      id: id,
      title: title,
      lastMessage: lastMessage,
      updatedAt: updatedAt,
      isPinned: isPinned,
      tags: tags,
    );
  }
}
