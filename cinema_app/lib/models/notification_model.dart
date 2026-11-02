import 'id_entity.dart';
class AppNotification extends IdEntity<int> {
  final int userId;
  final String type;
  final String title;
  final String? content;
  final String? linkUrl;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required super.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    required this.linkUrl,
    required this.isRead,
    required this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      content: content,
      linkUrl: linkUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  /// Parse từ JSON; nhận cả camelCase (NestJS/Firestore) lẫn snake_case (MySQL).
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _toInt(json['id']),
      userId: _toInt(json['userId'] ?? json['user_id']),
      type: (json['type'] ?? 'system').toString(),
      title: (json['title'] ?? '').toString(),
      content: json['content']?.toString(),
      linkUrl: (json['linkUrl'] ?? json['link_url'])?.toString(),
      isRead: _toBool(json['isRead'] ?? json['is_read']),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      ),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == 'true' || s == '1';
  }
}
