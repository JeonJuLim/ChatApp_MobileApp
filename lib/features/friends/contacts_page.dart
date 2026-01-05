import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'models.dart'; // file models.dart
import 'package:shared_preferences/shared_preferences.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  List<FriendRelation> _relations = [];
  bool _loading = true;
  String? _error;

  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  late String _token;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadTokenAndData();
  }

  Future<void> _loadTokenAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    if (token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Bạn chưa đăng nhập';
      });
      return;
    }

    _token = token;
    await _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _dio.get(
        'http://172.16.1.21:3001/friends/relations',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );

      final raw = res.data;
      List<dynamic> list = [];
      if (raw is List) list = raw;
      if (raw is Map) list = raw['data'] ?? raw['items'] ?? raw['relations'] ?? [];

      setState(() {
        _relations = list
            .whereType<Map>()
            .map((e) => FriendRelation.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi load danh sách bạn bè';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendRequestByUsername(String username) async {
    try {
      await _dio.post(
        'http://172.16.1.21:3001/friends/request-by-username',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
        data: {'username': username},
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đã gửi lời mời tới @$username')));
      _usernameCtrl.clear();
      await _fetchFriends();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi gửi lời mời')));
    }
  }

  Future<void> _sendRequestByPhone(String phone) async {
    try {
      await _dio.post(
        'http://172.16.1.21:3001/friends/request',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
        data: {'phoneE164': phone},
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đã gửi lời mời tới $phone')));
      _phoneCtrl.clear();
      await _fetchFriends();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi gửi lời mời')));
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await _dio.post(
        'http://172.16.1.21:3001/friends/requests/accept',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
        data: {'requestId': requestId},
      );
      await _fetchFriends();
    } catch (_) {}
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await _dio.post(
        'http://172.16.1.21:3001/friends/requests/reject',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
        data: {'requestId': requestId},
      );
      await _fetchFriends();
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friends = _relations.where((r) => r.status == FriendRelationStatus.friend).toList();
    final incoming = _relations.where((r) => r.status == FriendRelationStatus.incomingRequest).toList();
    final outgoing = _relations.where((r) => r.status == FriendRelationStatus.outgoingRequest).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Danh bạ')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
        children: [
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Bạn bè'),
              Tab(text: 'Lời mời'),
              Tab(text: 'Thêm bạn'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // TAB 1: bạn bè
                ListView(
                  children: friends.map((r) => ListTile(
                    title: Text(r.user.fullName),
                    subtitle: Text(r.user.username),
                  )).toList(),
                ),
                // TAB 2: lời mời
                ListView(
                  children: [
                    ...incoming.map((r) => ListTile(
                      title: Text(r.user.fullName),
                      subtitle: Text(r.user.username),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () => _acceptRequest(r.requestId!),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _rejectRequest(r.requestId!),
                          ),
                        ],
                      ),
                    )),
                    const Divider(),
                    ...outgoing.map((r) => ListTile(
                      title: Text(r.user.fullName),
                      subtitle: Text('Đã gửi lời mời • ${r.user.username}'),
                    )),
                  ],
                ),
                // TAB 3: thêm bạn
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    TextField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _sendRequestByUsername(_usernameCtrl.text),
                      child: const Text('Gửi lời mời (Username)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _sendRequestByPhone(_phoneCtrl.text),
                      child: const Text('Gửi lời mời (SĐT)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
