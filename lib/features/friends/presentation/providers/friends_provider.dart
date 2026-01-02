import 'package:flutter/foundation.dart';
import '../../data/models/friend_models.dart';
import '../../data/repositories/friends_repository.dart';

class FriendsProvider extends ChangeNotifier {
  final FriendsRepository repo;
  FriendsProvider(this.repo);

  List<FriendRelation> _relations = [];
  bool _loading = false;
  String? _error;

  List<FriendRelation> get relations => _relations;
  bool get loading => _loading;
  String? get error => _error;

  List<FriendRelation> get friends =>
      _relations.where((r) => r.status == FriendRelationStatus.friend).toList();

  List<FriendRelation> get incomingRequests =>
      _relations.where((r) => r.status == FriendRelationStatus.incomingRequest).toList();

  List<FriendRelation> get outgoingRequests =>
      _relations.where((r) => r.status == FriendRelationStatus.outgoingRequest).toList();

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _relations = await repo.getRelations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> sendRequest(String phoneE164) async {
    _error = null;
    notifyListeners();
    try {
      await repo.sendFriendRequest(phoneE164);
      await load();
    } catch (_) {
      _error = 'Không thể gửi lời mời lúc này';
      notifyListeners();
    }
  }

  Future<void> accept(String phoneE164) async {
    await repo.acceptFriendRequest(phoneE164);
    await load();
  }

  Future<void> reject(String phoneE164) async {
    await repo.rejectFriendRequest(phoneE164);
    await load();
  }
}
