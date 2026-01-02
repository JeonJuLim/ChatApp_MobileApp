

import '../../../../core/models/chat.dart';

abstract class ChatRepository {
  Future<List<Chat>> getChats();
}
