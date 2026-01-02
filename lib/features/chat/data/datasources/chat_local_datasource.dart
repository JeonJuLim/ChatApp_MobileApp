import '../../../../core/models/tag.dart';
import '../models/chat_dto.dart';


class ChatLocalDataSource {
  Future<List<ChatDto>> getChats() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final workTag = Tag(id: 'work', name: 'Work', color: '#2196F3');
    final urgentTag = Tag(id: 'urgent', name: 'Urgent', color: '#F44336');

    return [
      ChatDto(
        id: '1',
        title: 'Client A',
        lastMessage: 'Need update ASAP',
        isPinned: true,
        updatedAt: DateTime.now(),
        tags: [workTag, urgentTag],
      ),
      ChatDto(
        id: '2',
        title: 'Family',
        lastMessage: 'Dinner tonight?',
        isPinned: false,
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        tags: [],
      ),
    ];
  }
}
