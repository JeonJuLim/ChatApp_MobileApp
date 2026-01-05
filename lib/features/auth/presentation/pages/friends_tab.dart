import 'package:flutter/material.dart';
import 'package:minichatappmobile/features/friends/contacts_page.dart';

// ✅ Nếu chat_list_page.dart đang gọi FriendsTab()
class FriendsTab extends StatelessWidget {
  const FriendsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContactsPage();
  }
}

// ✅ Nếu chat_list_page.dart đang gọi FriendsTabPage()
class FriendsTabPage extends StatelessWidget {
  const FriendsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContactsPage();
  }
}
