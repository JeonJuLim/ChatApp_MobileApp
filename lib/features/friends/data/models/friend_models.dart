enum FriendRelationStatus { friend, incomingRequest, outgoingRequest }

FriendRelationStatus _parseStatus(String s) {
  final v = s.trim().toLowerCase();

  switch (v) {
  // ✅ Friend / Accepted (backend hay trả)
    case 'friend':
    case 'friends':
    case 'accepted':
    case 'accept':
    case 'approved':
    case 'success':
    case 'ok':
      return FriendRelationStatus.friend;

  // ✅ Incoming request
    case 'incomingrequest':
    case 'incoming_request':
    case 'incoming':
    case 'pending_in':
    case 'request_in':
    case 'in':
      return FriendRelationStatus.incomingRequest;

  // ✅ Outgoing request
    case 'outgoingrequest':
    case 'outgoing_request':
    case 'outgoing':
    case 'pending_out':
    case 'request_out':
    case 'out':
      return FriendRelationStatus.outgoingRequest;

    default:
    // 🔎 Debug: xem backend trả status gì
    // ignore: avoid_print
      print('⚠️ Unknown friend status from API: "$s" -> fallback friend');
      return FriendRelationStatus.friend; // fallback an toàn
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
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      phoneE164: json['phoneE164']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
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
    final statusStr = (json['status'] ?? '').toString();
    final userRaw = json['user'];

    // Nếu backend trả user thiếu hoặc null, tránh crash
    final userMap = userRaw is Map
        ? Map<String, dynamic>.from(userRaw as Map)
        : <String, dynamic>{};

    return FriendRelation(
      status: _parseStatus(statusStr),
      requestId: json['requestId']?.toString(),
      user: FriendUser.fromJson(userMap),
    );
  }
}
