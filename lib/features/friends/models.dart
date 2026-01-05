class FriendUser {
  final String id;
  final String username;
  final String fullName;
  final String? phoneE164;
  final String? avatarUrl;

  FriendUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.phoneE164,
    this.avatarUrl,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) => FriendUser(
    id: json['id'],
    username: json['username'] ?? '',
    fullName: json['fullName'] ?? '',
    phoneE164: json['phoneE164'],
    avatarUrl: json['avatarUrl'],
  );
}

enum FriendRelationStatus { friend, incomingRequest, outgoingRequest }

class FriendRelation {
  final FriendUser user;
  final FriendRelationStatus status;
  final String? requestId;

  FriendRelation({
    required this.user,
    required this.status,
    this.requestId,
  });

  factory FriendRelation.fromJson(Map<String, dynamic> json) => FriendRelation(
    user: FriendUser.fromJson(json['user']),
    status: _parseStatus(json['status']),
    requestId: json['requestId'],
  );

  static FriendRelationStatus _parseStatus(String s) {
    switch (s) {
      case 'friend':
        return FriendRelationStatus.friend;
      case 'incomingRequest':
        return FriendRelationStatus.incomingRequest;
      case 'outgoingRequest':
        return FriendRelationStatus.outgoingRequest;
      default:
        return FriendRelationStatus.friend;
    }
  }
}
