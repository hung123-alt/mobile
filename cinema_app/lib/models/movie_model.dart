import 'base_entity.dart';

/// Model phim - kế thừa BaseEntity<int> để dùng chung
/// getId() / getName() / getDescription().
///
/// Khớp với server/src/modules/movies/movies.entity.ts
class Movie extends BaseEntity<int> {
  final String slug;
  final String? posterUrl;
  final String? bannerUrl;
  final String type;
  final String status;
  final int? releaseYear;
  final int totalEpisodes;
  final int viewCount;
  final double avgRating;
  final int ratingCount;
  final bool isFeatured;
  final bool isVisible;
  final DateTime? scheduleDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Genre> genres;
  final List<Country> countries;

  Movie({
    required int id,
    required String name,
    required String description,
    required this.slug,
    required this.posterUrl,
    required this.bannerUrl,
    required this.type,
    required this.status,
    required this.releaseYear,
    required this.totalEpisodes,
    required this.viewCount,
    required this.avgRating,
    required this.ratingCount,
    required this.isFeatured,
    required this.isVisible,
    required this.scheduleDate,
    required this.createdAt,
    required this.updatedAt,
    required this.genres,
    required this.countries,
  }) : super(id: id, name: name, description: description);

  // ===== Getters riêng của Movie =====

  double getRating() => avgRating;
  int getViewCount() => viewCount;
  int getTotalEpisodes() => totalEpisodes;
  bool getIsFeatured() => isFeatured;

  /// Tên thể loại đầu tiên, dùng cho badge
  String getFirstGenreName() {
    if (genres.isEmpty) return 'Chưa phân loại';
    return genres.first.getName();
  }

  /// Nhãn hiển thị kiểu phim
  String getTypeLabel() {
    switch (type) {
      case 'phim_le':
        return 'Phim Lẻ';
      case 'phim_bo':
        return 'Phim Bộ';
      case 'hoat_hinh':
        return 'Hoạt Hình';
      case 'anime':
        return 'Anime';
      default:
        return 'Khác';
    }
  }

  /// Nhãn hiển thị trạng thái
  String getStatusLabel() {
    switch (status) {
      case 'ongoing':
        return 'Đang phát';
      case 'completed':
        return 'Hoàn thành';
      case 'upcoming':
        return 'Sắp chiếu';
      default:
        return status;
    }
  }

  /// Định dạng lượt xem: 1234 -> "1.2K"
  String getViewCountLabel() {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    }
    if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    }
    return '$viewCount';
  }

  /// Parse từ JSON của server
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int? ?? 0,
      name: json['title'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      posterUrl: json['posterUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      type: json['type'] as String? ?? 'phim_le',
      status: json['status'] as String? ?? 'ongoing',
      releaseYear: json['releaseYear'] as int?,
      totalEpisodes: json['totalEpisodes'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isVisible: json['isVisible'] as bool? ?? true,
      scheduleDate: _parseDate(json['scheduleDate']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      genres: (json['genres'] as List?)
              ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <Genre>[],
      countries: (json['countries'] as List?)
              ?.map((e) => Country.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <Country>[],
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
