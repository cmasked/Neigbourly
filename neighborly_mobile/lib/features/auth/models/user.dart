/// User model matching the FastAPI UserResponse schema.
class User {
  final String id;
  final String communityId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String verificationStatus;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.communityId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.verificationStatus,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  bool get isAdmin => role == 'admin' || role == 'super_admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      communityId: json['community_id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      role: json['role'],
      verificationStatus: json['verification_status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'community_id': communityId,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
    'avatar_url': avatarUrl,
    'role': role,
    'verification_status': verificationStatus,
    'created_at': createdAt.toIso8601String(),
  };
}
