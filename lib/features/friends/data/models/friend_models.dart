enum FriendRelationStatus { friend, incomingRequest, outgoingRequest }

FriendRelationStatus _parseStatus(String s) {
  final v = s.trim().toLowerCase();

  switch (v) {
    case 'friend':
    case 'friends':
      return FriendRelationStatus.friend;

    case 'incomingrequest':
    case 'incoming_request':
    case 'incoming':
    case 'pending_in':
      return FriendRelationStatus.incomingRequest;

    case 'outgoingrequest':
    case 'outgoing_request':
    case 'outgoing':
    case 'pending_out':
      return FriendRelationStatus.outgoingRequest;

    default:
    // fallback an toàn: không crash app
      return FriendRelationStatus.friend;
  }
}

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

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['id'] as String,
      username: (json['username'] ?? '') as String,
      fullName: (json['fullName'] ?? '') as String,
      phoneE164: json['phoneE164'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class FriendRelation {
  final FriendRelationStatus status;

  /// User phía bên kia (để render list)
  final FriendUser user;

  /// Chỉ có khi là request (incoming/outgoing)
  final String? requestId;

  FriendRelation({
    required this.status,
    required this.user,
    this.requestId,
  });

  factory FriendRelation.fromJson(Map<String, dynamic> json) {
    return FriendRelation(
      status: _parseStatus(json['status'] as String),
      requestId: json['requestId'] as String?,
      user: FriendUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
