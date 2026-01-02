class UserProfile {
  final String id;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String? status;

  final String authProvider;
  final String? email;
  final bool emailVerified;
  final String? phoneE164;
  final bool phoneVerified;

  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.status,
    required this.authProvider,
    this.email,
    required this.emailVerified,
    this.phoneE164,
    required this.phoneVerified,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      username: json['username'].toString(),
      fullName: json['fullName'].toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      status: json['status']?.toString(),
      authProvider: json['authProvider'].toString(),
      email: json['email']?.toString(),
      emailVerified: (json['emailVerified'] == true),
      phoneE164: json['phoneE164']?.toString(),
      phoneVerified: (json['phoneVerified'] == true),
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}
