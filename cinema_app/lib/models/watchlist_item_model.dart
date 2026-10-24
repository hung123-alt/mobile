import 'movie_model.dart';

/// Model mục trong danh sách xem sau (Watchlist)
///
/// Khớp với server/src/modules/watchlist/watchlist.entity.ts
class WatchlistItem {
  final int id;
  final int userId;
  final int movieId;
  final Movie? movie;
  final DateTime? createdAt;

  WatchlistItem({
    required this.id,
    required this.userId,
    required this.movieId,
    this.movie,
    this.createdAt,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      movieId: json['movieId'] as int? ?? 0,
      movie: json['movie'] is Map<String, dynamic>
          ? Movie.fromJson(json['movie'] as Map<String, dynamic>)
          : null,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}