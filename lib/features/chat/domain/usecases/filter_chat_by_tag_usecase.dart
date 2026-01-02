import '../../../../core/models/chat.dart';

class FilterChatByTagUseCase {
  List<Chat> call(List<Chat> chats, String tagId) {
    return chats
        .where((chat) => chat.tags.any((t) => t.id == tagId))
        .toList();
  }
}
