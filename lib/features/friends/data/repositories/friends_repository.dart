import 'dart:math';
import '../models/friend_models.dart';

abstract class FriendsRepository {
  Future<List<FriendRelation>> getRelations();
  Future<void> sendFriendRequest(String phoneE164);
  Future<void> acceptFriendRequest(String phoneE164);
  Future<void> rejectFriendRequest(String phoneE164);
}

class FriendsRepositoryMock implements FriendsRepository {
  final _rng = Random();

  // ===== Mock “DB users” (có sẵn vài user để test nhanh) =====
  final List<AppUser> _users = [
    const AppUser(id: 'u1', fullName: 'Nguyễn A', phoneE164: '+84900000001'),
    const AppUser(id: 'u2', fullName: 'Trần B', phoneE164: '+84900000002'),
    const AppUser(id: 'u3', fullName: 'Group Study (Admin)', phoneE164: '+84900000003'),
    const AppUser(id: 'u4', fullName: 'Lê C', phoneE164: '+84900000004'),
  ];

  // ===== Mock relations =====
  late final List<FriendRelation> _relations = [
    FriendRelation(user: _users[0], status: FriendRelationStatus.friend),
    FriendRelation(user: _users[1], status: FriendRelationStatus.incomingRequest), // request đến để test
    FriendRelation(user: _users[3], status: FriendRelationStatus.outgoingRequest), // request đi để test
  ];

  AppUser _ensureUserByPhone(String phoneE164) {
    final existed = _users.where((u) => u.phoneE164 == phoneE164).toList();
    if (existed.isNotEmpty) return existed.first;

    // ✅ TỰ TẠO USER nếu SĐT không có trong mock (để bạn nhập số bất kỳ vẫn test được)
    final id = 'u${1000 + _rng.nextInt(9000)}';
    final user = AppUser(
      id: id,
      fullName: 'User $id',
      phoneE164: phoneE164,
    );
    _users.add(user);
    return user;
  }

  FriendRelation? _findRelationByPhone(String phoneE164) {
    try {
      return _relations.firstWhere((r) => r.user.phoneE164 == phoneE164);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<FriendRelation>> getRelations() async {
    return _relations;
  }

  @override
  Future<void> sendFriendRequest(String phoneE164) async {
    final rel = _findRelationByPhone(phoneE164);

    // Nếu đã là bạn hoặc đã có request -> không gửi lại
    if (rel != null) return;

    final user = _ensureUserByPhone(phoneE164);
    _relations.add(FriendRelation(user: user, status: FriendRelationStatus.outgoingRequest));
  }

  @override
  Future<void> acceptFriendRequest(String phoneE164) async {
    final rel = _findRelationByPhone(phoneE164);
    if (rel == null) return;
    if (rel.status == FriendRelationStatus.incomingRequest) {
      rel.status = FriendRelationStatus.friend;
    }
  }

  @override
  Future<void> rejectFriendRequest(String phoneE164) async {
    final rel = _findRelationByPhone(phoneE164);
    if (rel == null) return;
    if (rel.status == FriendRelationStatus.incomingRequest) {
      _relations.remove(rel);
    }
  }
}
