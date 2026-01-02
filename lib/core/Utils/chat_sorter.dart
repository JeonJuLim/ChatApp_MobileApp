import '../models/chat.dart';

class ChatSorter {
  static List<Chat> sort(List<Chat> chats) {
    chats.sort((a, b) {
      if (a.isPinned && b.isPinned) {
        return b.pinnedAt!.compareTo(a.pinnedAt!);
      }
      if (a.isPinned) return -1;
      if (b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return chats;
  }
}
