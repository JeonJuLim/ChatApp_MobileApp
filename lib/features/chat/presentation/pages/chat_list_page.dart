import 'package:flutter/material.dart';
import '../../../../core/models/chat.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/usecases/get_chat_list_usecase.dart';
import '../widgets/chat_item.dart';
import '../widgets/tag_filter_bar.dart';


class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late GetChatListUseCase getChatListUseCase;
  List<Chat> chats = [];

  @override
  void initState() {
    super.initState();
    getChatListUseCase = GetChatListUseCase(
      ChatRepositoryImpl(ChatLocalDataSource()),
    );
    _loadChats();
  }

  Future<void> _loadChats() async {
    final result = await getChatListUseCase();
    setState(() => chats = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Column(
        children: [
          TagFilterBar(
            onTagSelected: (tagId) {
              setState(() {
                chats = chats
                    .where((c) =>
                    c.tags.any((tag) => tag.id == tagId))
                    .toList();
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (_, index) {
                return ChatItem(chat: chats[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
