import 'id_entity.dart';

/// Model người dùng.
///
/// Kế thừa `IdEntity<int>`, hỗ trợ đầy đủ các trường thông tin tài khoản
/// và thông tin cá nhân mở rộng lưu trên Firestore `users`.
class User extends IdEntity<int> {
  final String username;
  final String email;
  final String? avatarUrl;
  final String? fullName;
  final String? phone;
  final String? birthDate;
  final String? gender;
  final String? bio;
  final String role;
  final bool isBanned;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required super.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
    this.fullName,
    this.phone,
    this.birthDate,
    this.gender,
    this.bio,
    required this.role,
    required this.isBanned,
    required this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Tên hiển thị (ưu tiên Họ tên nếu có, sau đó đến username, email)
  String getDisplayName() {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    if (username.isNotEmpty) return username;
    if (email.isNotEmpty) return email;
    return 'Người dùng #$id';
  }

  /// Có phải admin không
  bool getIsAdmin() => role == 'admin';

  /// Tên viết tắt avatar
  String getInitials() {
    final display = getDisplayName();
    if (display.isEmpty) return '?';
    return display.substring(0, 1).toUpperCase();
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? avatarUrl,
    bool clearAvatar = false,
    String? fullName,
    String? phone,
    String? birthDate,
    String? gender,
    String? bio,
    String? role,
    bool? isBanned,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'avatar_url': avatarUrl,
      'fullName': fullName,
      'full_name': fullName,
      'phone': phone,
      'birthDate': birthDate,
      'birth_date': birthDate,
      'gender': gender,
      'bio': bio,
      'role': role,
      'isBanned': isBanned,
      'is_banned': isBanned ? 1 : 0,
      'lastLogin': lastLogin?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  /// Parse từ JSON (hỗ trợ cả camelCase và snake_case)
  factory User.fromJson(Map<String, dynamic> json) {
    final rawAvatar = (json['avatarUrl'] ?? json['avatar_url'])?.toString();
    return User(
      id: _parseInt(json['id'], 0),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatarUrl:
          (rawAvatar != null && rawAvatar.isNotEmpty && rawAvatar != 'null')
              ? rawAvatar
              : null,
      fullName: (json['fullName'] ?? json['full_name'])?.toString(),
      phone: json['phone']?.toString(),
      birthDate: (json['birthDate'] ?? json['birth_date'])?.toString(),
      gender: json['gender']?.toString(),
      bio: json['bio']?.toString(),
      role: json['role']?.toString() ?? 'user',
      isBanned: json['isBanned'] == true || json['is_banned'] == 1,
      lastLogin: _parseDate(json['lastLogin'] ?? json['last_login']),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
