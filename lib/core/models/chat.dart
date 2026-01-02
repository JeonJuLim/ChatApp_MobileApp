import 'tag.dart';

class Chat {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime updatedAt;

  bool isPinned;
  DateTime? pinnedAt;
  List<Tag> tags;

  Chat({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
    this.isPinned = false,
    this.pinnedAt,
    this.tags = const [],
  });
}
