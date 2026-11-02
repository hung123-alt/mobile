import 'id_entity.dart';

/// Model bình luận - kế thừa `IdEntity<int>`.
class Comment extends IdEntity<int> {
  final String? docId;
  final int userId;
  final int movieId;
  final int? parentId;
  final String content;
  final bool isHidden;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Thông tin người viết
  final String? authorName;
  final String? authorAvatar;

  /// Lượt thích / không thích
  final int likeCount;
  final int dislikeCount;
  final List<int> likedUserIds;
  final List<int> dislikedUserIds;

  Comment({
    required super.id,
    this.docId,
    required this.userId,
    required this.movieId,
    required this.parentId,
    required this.content,
    required this.isHidden,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorAvatar,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.likedUserIds = const [],
    this.dislikedUserIds = const [],
  });

  /// Là bình luận trả lời
  bool getIsReply() => parentId != null && parentId! > 0;

  /// Định dạng thời gian tương đối: "2 giờ trước" hoặc ngày giờ
  String getTimeAgoLabel() {
    if (createdAt == null) return 'Vừa xong';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.isNegative || diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30} tháng trước';
    final d = createdAt!.day.toString().padLeft(2, '0');
    final m = createdAt!.month.toString().padLeft(2, '0');
    return '$d/$m/${createdAt!.year}';
  }

  Comment copyWith({
    int? id,
    String? docId,
    int? userId,
    int? movieId,
    int? parentId,
    String? content,
    bool? isHidden,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorName,
    String? authorAvatar,
    int? likeCount,
    int? dislikeCount,
    List<int>? likedUserIds,
    List<int>? dislikedUserIds,
  }) {
    return Comment(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      userId: userId ?? this.userId,
      movieId: movieId ?? this.movieId,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      likedUserIds: likedUserIds ?? this.likedUserIds,
      dislikedUserIds: dislikedUserIds ?? this.dislikedUserIds,
    );
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  static int? _parseNullableInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  static List<int> _parseIntList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => _parseNullableInt(e))
          .whereType<int>()
          .toList();
    }
    return const [];
  }

  /// Parse từ JSON (hỗ trợ cả camelCase và snake_case từ Firestore / MySQL)
  factory Comment.fromJson(Map<String, dynamic> json, {String? docId}) {
    final user = json['user'] as Map<String, dynamic>?;
    final likedList = _parseIntList(json['likedUserIds'] ?? json['liked_user_ids']);
    final dislikedList =
        _parseIntList(json['dislikedUserIds'] ?? json['disliked_user_ids']);

    final rawLikeCount =
        _parseInt(json['likeCount'] ?? json['like_count'], likedList.length);
    final rawDislikeCount = _parseInt(
      json['dislikeCount'] ?? json['dislike_count'],
      dislikedList.length,
    );

    final rawAuthorAvatar = (json['authorAvatar'] ??
            json['author_avatar'] ??
            user?['avatarUrl'] ??
            user?['avatar_url'])
        ?.toString();

    return Comment(
      id: _parseInt(json['id'], 0),
      docId: docId ?? json['__docId']?.toString(),
      userId: _parseInt(json['userId'] ?? json['user_id'], 0),
      movieId: _parseInt(json['movieId'] ?? json['movie_id'], 0),
      parentId: _parseNullableInt(json['parentId'] ?? json['parent_id']),
      content: json['content']?.toString() ?? '',
      isHidden: json['isHidden'] == true || json['is_hidden'] == 1,
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
      authorName: (json['authorName'] ??
              json['author_name'] ??
              user?['fullName'] ??
              user?['username'])
          ?.toString(),
      authorAvatar: (rawAuthorAvatar != null &&
              rawAuthorAvatar.isNotEmpty &&
              rawAuthorAvatar != 'null')
          ? rawAuthorAvatar
          : null,
      likeCount: rawLikeCount < likedList.length ? likedList.length : rawLikeCount,
      dislikeCount: rawDislikeCount < dislikedList.length
          ? dislikedList.length
          : rawDislikeCount,
      likedUserIds: likedList,
      dislikedUserIds: dislikedList,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    // Hỗ trợ cả định dạng SQL "2026-06-19 10:50:11" và ISO 8601
    return DateTime.tryParse(str) ??
        DateTime.tryParse(str.replaceFirst(' ', 'T'));
  }
}
