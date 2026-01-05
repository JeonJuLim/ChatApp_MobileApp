import 'package:dio/dio.dart';
import '../models/friend_models.dart';

class FriendsRepository {
  final Dio _dio;
  FriendsRepository(this._dio);

  Future<List<FriendRelation>> getRelations() async {
    try {
      final res = await _dio.get('/friends/relations');

      // ✅ Debug request/response
      // ignore: avoid_print
      print('FRIENDS REQ -> ${res.requestOptions.method} ${res.requestOptions.uri}');
      // ignore: avoid_print
      print('FRIENDS AUTH -> ${res.requestOptions.headers['Authorization'] ?? 'NOT_SET'}');
      // ignore: avoid_print
      print('FRIENDS STATUS -> ${res.statusCode}');
      // ignore: avoid_print
      print('FRIENDS RAW -> ${res.data}');

      final raw = res.data;

      // Support: backend trả List hoặc wrapper {data/items/relations: [...]}
      List<dynamic>? list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        final candidate = raw['data'] ?? raw['items'] ?? raw['relations'];
        if (candidate is List) list = candidate;
      }

      if (list == null) {
        throw Exception(
          'Invalid response for /friends/relations: expected List or wrapper map, got ${raw.runtimeType}',
        );
      }

      return list
          .whereType<Map>()
          .map((e) => FriendRelation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      // ✅ Debug DioException
      // ignore: avoid_print
      print('FRIENDS DIO ERROR -> ${e.requestOptions.method} ${e.requestOptions.uri}');
      // ignore: avoid_print
      print('FRIENDS DIO STATUS -> ${e.response?.statusCode}');
      // ignore: avoid_print
      print('FRIENDS DIO DATA -> ${e.response?.data}');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('FRIENDS ERROR -> $e');
      rethrow;
    }
  }

  Future<void> sendFriendRequest(String phoneE164) async {
    try {
      final res = await _dio.post('/friends/request', data: {'phoneE164': phoneE164});
      // ignore: avoid_print
      print('FRIENDS POST /friends/request -> ${res.statusCode} ${res.data}');
    } on DioException catch (e) {
      // ignore: avoid_print
      print('FRIENDS DIO ERROR /friends/request -> ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> sendFriendRequestByUsername(String username) async {
    await _dio.post(
      '/friends/request-by-username',
      data: {'username': username},
    );
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      final res = await _dio.post('/friends/requests/accept', data: {'requestId': requestId});
      // ignore: avoid_print
      print('FRIENDS POST /friends/requests/accept -> ${res.statusCode} ${res.data}');
    } on DioException catch (e) {
      // ignore: avoid_print
      print('FRIENDS DIO ERROR /friends/requests/accept -> ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }


  Future<void> rejectFriendRequest(String requestId) async {
    try {
      final res = await _dio.post('/friends/requests/reject', data: {'requestId': requestId});
      // ignore: avoid_print
      print('FRIENDS POST /friends/requests/reject -> ${res.statusCode} ${res.data}');
    } on DioException catch (e) {
      // ignore: avoid_print
      print('FRIENDS DIO ERROR /friends/requests/reject -> ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }
}
