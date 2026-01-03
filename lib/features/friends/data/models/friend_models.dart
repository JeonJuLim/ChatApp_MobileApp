enum FriendRelationStatus {
  none,
  friend,
  outgoingRequest, // mình gửi lời mời
  incomingRequest, // người ta gửi lời mời
}

class AppUser {
  final String id;
  final String fullName;
  final String phoneE164;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.phoneE164,
  });

  AppUser copyWith({
    String? id,
    String? fullName,
    String? phoneE164,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneE164: phoneE164 ?? this.phoneE164,
    );
  }
}

class FriendRelation {
  final AppUser user;
  FriendRelationStatus status;

  FriendRelation({
    required this.user,
    required this.status,
  });
}
