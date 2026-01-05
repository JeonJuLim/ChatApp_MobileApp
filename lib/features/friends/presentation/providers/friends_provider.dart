import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:minichatappmobile/core/storage/token_storage.dart';

import '../../data/models/friend_models.dart';
import '../../data/repositories/friends_repository.dart';

class FriendsProvider extends ChangeNotifier {
  final FriendsRepository repo;
  final TokenStorage storage;

  FriendsProvider(this.repo, this.storage);

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
    if (_loading) return;

    final token = await storage.read();
    if (token == null || token.trim().isEmpty) {
      _relations = [];
      _error = null; // hoặc 'Bạn cần đăng nhập'
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _relations = await repo.getRelations();
    } catch (e) {
      _error = _prettyError(e);
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
    } catch (e) {
      _error = _prettyError(e);
      notifyListeners();
    }
  }

  Future<void> sendRequestByUsername(String username) async {
    _error = null;
    notifyListeners();

    try {
      await repo.sendFriendRequestByUsername(username);
      await load();
    } catch (e) {
      _error = _prettyError(e);
      notifyListeners();
    }
  }

  Future<void> accept(String requestId) async {
    _error = null;
    notifyListeners();

    try {
      await repo.acceptFriendRequest(requestId);
      await load();
    } catch (e) {
      _error = _prettyError(e);
      notifyListeners();
    }
  }

  Future<void> reject(String requestId) async {
    _error = null;
    notifyListeners();

    try {
      await repo.rejectFriendRequest(requestId);
      await load();
    } catch (e) {
      _error = _prettyError(e);
      notifyListeners();
    }
  }

  String _prettyError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      // NestJS thường trả { message: "...", statusCode: ... }
      String msg = e.message ?? 'Network error';

      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }

      return status != null ? 'HTTP $status: $msg' : msg;
    }

    return e.toString();
  }
}
