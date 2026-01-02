import 'package:flutter/material.dart';

import '../../../../core/models/chat.dart';


class ChatItem extends StatelessWidget {
  final Chat chat;

  const ChatItem({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: chat.isPinned
          ? const Icon(Icons.push_pin, color: Colors.orange)
          : null,
      title: Text(chat.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chat.lastMessage),
          Wrap(
            spacing: 4,
            children: chat.tags
                .map((t) => Chip(
              label: Text(t.name),
              visualDensity: VisualDensity.compact,
            ))
                .toList(),
          )
        ],
      ),
    );
  }
}
