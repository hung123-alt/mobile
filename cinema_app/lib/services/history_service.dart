import 'api_service.dart';


class WatchHistoryItem {
  final int id;
  final int userId;
  final int movieId;
  final int episodeId;
  final int progressSeconds;
  final DateTime? watchedAt;

  /// Thông tin kèm theo (server trả qua relation `movie`/`episode`) để
  /// hiển thị thẻ "Xem tiếp" mà không cần gọi thêm API.
  final String? movieTitle;
  final String? moviePosterUrl;
  final String? movieSlug;
  final int? episodeNumber;

  WatchHistoryItem({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.episodeId,
    required this.progressSeconds,
    required this.watchedAt,
    this.movieTitle,
    this.moviePosterUrl,
    this.movieSlug,
    this.episodeNumber,
  });

  /// Nhãn tiến độ: "Tập 5 - Xem đến 12:30"
  String getProgressLabel() {
    final minutes = progressSeconds ~/ 60;
    final seconds = progressSeconds % 60;
    final secStr = seconds.toString().padLeft(2, '0');
    final epLabel = episodeNumber != null ? 'Tập $episodeNumber - ' : '';
    return '${epLabel}Xem đến $minutes:$secStr';
  }

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    final movie = json['movie'] as Map<String, dynamic>?;
    final episode = json['episode'] as Map<String, dynamic>?;
    return WatchHistoryItem(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      movieId: json['movieId'] as int? ?? 0,
      episodeId: json['episodeId'] as int? ?? 0,
      progressSeconds: json['progressSeconds'] as int? ?? 0,
      watchedAt: _parseDate(json['watchedAt']),
      movieTitle: movie?['title'] as String?,
      moviePosterUrl: movie?['posterUrl'] as String?,
      movieSlug: movie?['slug'] as String?,
      episodeNumber: episode?['episodeNumber'] as int?,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}

/// Service gọi API cho lịch sử xem.
///
/// Endpoint lấy từ
/// server/src/modules/watch-history/watch-history.controller.ts.
/// Tất cả route cần đăng nhập (@UseGuards(JwtAuthGuard) ở cấp Controller).
class HistoryService {
  HistoryService(this._api);

  final ApiService _api;

  /// Lưu/ cập nhật tiến độ xem 1 tập phim.
  ///
  ///   POST /watch-history  body: { movieId, episodeId, progressSeconds? }
  Future<void> saveProgress({
    required int movieId,
    required int episodeId,
    int? progressSeconds,
  }) {
    return _api.postVoid('/watch-history', {
      'movieId': movieId,
      'episodeId': episodeId,
      'progressSeconds': ?progressSeconds,
    });
  }

  /// Lịch sử xem của mình (dùng cho mục "Xem tiếp" trang chủ).
  ///
  ///   GET /watch-history
  Future<List<WatchHistoryItem>> getMine() {
    return _api.getList<WatchHistoryItem>(
      '/watch-history',
      (raw) => WatchHistoryItem.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// Xóa toàn bộ lịch sử xem.
  ///
  ///   DELETE /watch-history/all
  Future<void> clearAll() {
    return _api.delete('/watch-history/all');
  }

  /// Xóa 1 bản ghi lịch sử theo id.
  ///
  ///   DELETE /watch-history/:id
  Future<void> remove(int id) {
    return _api.delete('/watch-history/$id');
  }
}