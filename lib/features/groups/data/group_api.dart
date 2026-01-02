import 'package:dio/dio.dart';

class GroupApi {
  final Dio dio;
  GroupApi(this.dio);

  Future<List<dynamic>> listGroups() async {
    try {
      final res = await dio.get('/conversations/groups');
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(_prettyDioError(e));
    }
  }

  Future<Map<String, dynamic>> createGroup({
    required String name,
    required List<String> memberIds,
    String? avatarUrl,
  }) async {
    try {
      final res = await dio.post('/conversations/group', data: {
        'name': name,
        'memberIds': memberIds,
        'avatarUrl': avatarUrl,
      });
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_prettyDioError(e));
    }
  }

  Future<Map<String, dynamic>> getGroup(String conversationId) async {
    try {
      final res = await dio.get('/conversations/$conversationId');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_prettyDioError(e));
    }
  }

  Future<Map<String, dynamic>> updateMembers({
    required String conversationId,
    List<String>? add,
    List<String>? remove,
  }) async {
    try {
      final res = await dio.patch('/conversations/$conversationId/members', data: {
        'add': add ?? [],
        'remove': remove ?? [],
      });
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_prettyDioError(e));
    }
  }

  String _prettyDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Timeout: Không kết nối được server. Kiểm tra backend đang chạy port 3000 và baseUrl=10.0.2.2 (Android emulator).';
    }
    if (e.response != null) {
      return 'HTTP ${e.response?.statusCode}: ${e.response?.data}';
    }
    return e.message ?? 'Lỗi mạng không xác định';
  }
}
