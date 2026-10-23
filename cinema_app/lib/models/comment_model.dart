import 'id_entity.dart';

/// Model bình luận.
///
/// Bảng `comments` có khóa chính `id` và các khóa ngoại user_id / movie_id.
/// Kế thừa IdEntity<int> để có getId() với ràng buộc kiểu.
///
/// Khớp với server/src/modules/comments/comment.entity.ts
class Comment extends IdEntity<int> {
  final int userId;
  final int movieId;
  final int? parentId;
  final String content;
  final bool isHidden;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Thông tin người viết (nếu server trả kèm)
  final String? authorName;
  final String? authorAvatar;

  Comment({
    required int id,
    required this.userId,
    required this.movieId,
    required this.parentId,
    required this.content,
    required this.isHidden,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorAvatar,
  }) : super(id: id);

  /// Là bình luận trả lời
  bool getIsReply() => parentId != null;

  /// Định dạng thời gian tương đối: "3 giờ trước"
  String getTimeAgoLabel() {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    return '${diff.inDays ~/ 30} tháng trước';
  }

  /// Parse từ JSON
  factory Comment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Comment(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      movieId: json['movieId'] as int? ?? 0,
      parentId: json['parentId'] as int?,
      content: json['content'] as String? ?? '',
      isHidden: json['isHidden'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      authorName: user?['username'] as String?,
      authorAvatar: user?['avatarUrl'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
