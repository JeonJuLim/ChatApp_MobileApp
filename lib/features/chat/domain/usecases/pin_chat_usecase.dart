import '../../../../core/models/chat.dart';

class PinChatUseCase {
  Chat call(Chat chat) {
    chat.isPinned = true;
    chat.pinnedAt = DateTime.now();
    return chat;
  }
}
