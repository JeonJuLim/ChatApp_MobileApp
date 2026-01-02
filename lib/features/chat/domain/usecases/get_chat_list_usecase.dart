
import '../../../../core/models/chat.dart';
import '../../data/repositories/chat_repository.dart';

class GetChatListUseCase {
  final ChatRepository repository;

  GetChatListUseCase(this.repository);

  Future<List<Chat>> call() {
    return repository.getChats();
  }
}
