
import '../../../../core/Utils/chat_sorter.dart';
import '../../../../core/models/chat.dart';
import '../datasources/chat_local_datasource.dart';
import 'chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource localDataSource;

  ChatRepositoryImpl(this.localDataSource);

  @override
  Future<List<Chat>> getChats() async {
    final dtos = await localDataSource.getChats();
    final chats = dtos.map((e) => e.toEntity()).toList();
    return ChatSorter.sort(chats);
  }
}
