import 'api_service.dart';
import '../models/rating_model.dart';

/// Service gọi API cho đánh giá (rating) phim.
///
/// Endpoint lấy từ server/src/modules/ratings/ratings.controller.ts.
/// Tất cả route cần đăng nhập (@UseGuards(JwtAuthGuard) ở cấp Controller).
class RatingService {
  RatingService(this._api);

  final ApiService _api;

  /// Đánh giá phim (tạo mới hoặc cập nhật nếu đã đánh giá trước đó —
  /// server dùng khóa chính kép userId+movieId nên "rate" đóng vai trò
  /// upsert, không cần phân biệt create/update ở phía client).
  ///
  ///   POST /ratings  body: { movieId, score, content? }
  Future<Rating> rate({
    required int movieId,
    required int score,
    String? content,
  }) {
    return _api.post<Rating>(
      '/ratings',
      {
        'movieId': movieId,
        'score': score,
        if (content != null && content.isNotEmpty) 'content': content,
      },
      (raw) => Rating.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// Lấy điểm mình đã đánh giá cho 1 phim. Trả null nếu chưa đánh giá
  /// (server trả 404 -> [ApiService] ném [ApiException], bắt ở Repository).
  ///
  ///   GET /ratings/movie/:movieId
  Future<Rating?> getUserRating(int movieId) {
    return _api.get<Rating?>(
      '/ratings/movie/$movieId',
      (raw) =>
          raw == null ? null : Rating.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// Xóa đánh giá của mình cho 1 phim.
  ///
  ///   DELETE /ratings/movie/:movieId
  Future<void> remove(int movieId) {
    return _api.delete('/ratings/movie/$movieId');
  }
}
