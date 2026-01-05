import 'package:dio/dio.dart';
import '../models/friend_models.dart';

class FriendsRepository {
  final Dio _dio;
  FriendsRepository(this._dio);

  Future<List<FriendRelation>> getRelations() async {
    final res = await _dio.get('/friends/relations');

    // Debug payload thật (chỉ bật khi cần)
    // ignore: avoid_print
    print('FRIENDS RAW -> ${res.data}');

    if (res.data is! List) {
      throw Exception('Invalid response: expected List, got ${res.data.runtimeType}');
    }

    return (res.data as List)
        .whereType<Map<String, dynamic>>()
        .map(FriendRelation.fromJson)
        .toList();
  }

  Future<void> sendFriendRequest(String phoneE164) async {
    await _dio.post('/friends/request', data: {'phoneE164': phoneE164});
  }

  Future<void> sendFriendRequestByUsername(String username) async {
    await _dio.post('/friends/request-by-username', data: {'username': username});
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _dio.post('/friends/requests/accept', data: {'requestId': requestId});
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _dio.post('/friends/requests/reject', data: {'requestId': requestId});
  }
}
