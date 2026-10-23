import 'id_entity.dart';

/// Model người dùng.
///
/// Lưu ý: User KHÔNG kế thừa BaseEntity vì bảng `users` trong DB
/// không có cột `name` / `description` (xem user.entity.ts).
/// Thay vào đó dùng IdEntity<int> - chỉ giữ phần `id` có ràng buộc kiểu.
///
/// Đây là ví dụ cho thấy Generic không bắt buộc phải dùng cho mọi class.
class User extends IdEntity<int> {
  final String username;
  final String email;
  final String? avatarUrl;
  final String role;
  final bool isBanned;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required int id,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.isBanned,
    required this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  }) : super(id: id);

  /// Tên hiển thị
  String getDisplayName() {
    if (username.isNotEmpty) return username;
    if (email.isNotEmpty) return email;
    return 'Người dùng #$id';
  }

  /// Có phải admin không
  bool getIsAdmin() => role == 'admin';

  /// Tên viết tắt avatar
  String getInitials() {
    if (username.isEmpty) return '?';
    return username.substring(0, 1).toUpperCase();
  }

  /// Parse từ JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'user',
      isBanned: json['isBanned'] as bool? ?? false,
      lastLogin: _parseDate(json['lastLogin']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
