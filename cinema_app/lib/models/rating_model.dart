/// Model đánh giá (rating) phim.
///
/// Bảng `ratings` có KHÓA CHÍNH KÉP (user_id, movie_id) — không có cột `id`.
///
/// Vì vậy KHÔNG kế thừa IdEntity<int> (vì không có id đơn).
/// Đây là trường hợp chứng minh Generic không phải lúc nào cũng áp dụng.
///
/// Khớp với server/src/modules/ratings/rating.entity.ts
class Rating {
  final int userId;
  final int movieId;
  final int score; // 1-10
  final String? content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Rating({
    required this.userId,
    required this.movieId,
    required this.score,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Điểm hiển thị trên thang 5 sao: 8/10 -> 4.0 sao
  double getScoreOutOfFive() => score / 2;

  /// Nhãn điểm
  String getScoreLabel() {
    if (score >= 9) return 'Tuyệt vời';
    if (score >= 7) return 'Rất tốt';
    if (score >= 5) return 'Tạm được';
    if (score >= 3) return 'Tệ';
    return 'Rất tệ';
  }

  /// Parse từ JSON
  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      userId: json['userId'] as int? ?? 0,
      movieId: json['movieId'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      content: json['content'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
