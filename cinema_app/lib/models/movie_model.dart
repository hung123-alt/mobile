import 'package:flutter/foundation.dart' show kIsWeb;

import 'base_entity.dart';
import 'country_model.dart';
import 'genre_model.dart';

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
    required super.id,
    required super.name,
    required super.description,
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
  });

  // ===== Getters riêng của Movie =====

  double getRating() => avgRating;
  int getViewCount() => viewCount;
  int getTotalEpisodes() => totalEpisodes;
  bool getIsFeatured() => isFeatured;

  /// URL hình ảnh hiển thị cho bộ phim (ưu tiên bannerUrl theo yêu cầu của người dùng, fallback posterUrl)
  String? get displayImageUrl {
    String? raw;
    if (bannerUrl != null && bannerUrl!.isNotEmpty && bannerUrl != '{}') {
      raw = bannerUrl;
    } else if (posterUrl != null && posterUrl!.isNotEmpty && posterUrl != '{}') {
      raw = posterUrl;
    }
    if (raw == null) return null;

    // Trên nền tảng Web (Chrome), server vsmov.com không gắn CORS header khiến trình duyệt chặn tải ảnh.
    // Dùng wsrv.nl proxy để gắn CORS và tối ưu tải ảnh trên Web.
    if (kIsWeb && raw.startsWith('http')) {
      return 'https://wsrv.nl/?url=${Uri.encodeComponent(raw)}';
    }
    return raw;
  }

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

  /// Copy với thể loại / quốc gia đã gắn từ bảng trung gian.
  /// Dùng khi enrich phim sau khi đọc thêm `movie_genres` + `movie_countries`.
  Movie copyWith({
    List<Genre>? genres,
    List<Country>? countries,
  }) {
    return Movie(
      id: id,
      name: name,
      description: description,
      slug: slug,
      posterUrl: posterUrl,
      bannerUrl: bannerUrl,
      type: type,
      status: status,
      releaseYear: releaseYear,
      totalEpisodes: totalEpisodes,
      viewCount: viewCount,
      avgRating: avgRating,
      ratingCount: ratingCount,
      isFeatured: isFeatured,
      isVisible: isVisible,
      scheduleDate: scheduleDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      genres: genres ?? this.genres,
      countries: countries ?? this.countries,
    );
  }

  /// Parse từ JSON của server / Firestore.
  ///
  /// LƯU Ý QUAN TRỌNG (fix rớt phim):
  /// Dữ liệu migrate từ MySQL cũ sang Firestore không đồng nhất kiểu:
  /// `id` có thể là int hoặc String, `is_visible` có thể là bool/int/String.
  /// Dùng `as int?` trực tiếp sẽ throw TypeError khiến trang chủ try/catch
  /// bỏ qua cả document -> admin đếm 71 phim nhưng app hiện thiếu.
  /// Vì vậy mọi field số/bool đều parse mềm qua helper bên dưới.
  factory Movie.fromJson(Map<String, dynamic> json, {String? docId}) {
    var parsedId = _parseIntField(json['id'] ?? json['movie_id'], 0);
    if (parsedId == 0 && docId != null) {
      parsedId = int.tryParse(docId.trim()) ?? 0;
    }
    final yearRaw = _parseIntField(
      json['releaseYear'] ?? json['release_year'],
      -1,
    );
    return Movie(
      id: parsedId,
      name: json['title'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      posterUrl: (json['posterUrl'] ?? json['poster_url']) as String?,
      bannerUrl: (json['bannerUrl'] ?? json['banner_url']) as String?,
      type: json['type'] as String? ?? 'phim_le',
      status: json['status'] as String? ?? 'ongoing',
      releaseYear: yearRaw < 0 ? null : yearRaw,
      totalEpisodes: _parseIntField(
        json['totalEpisodes'] ?? json['total_episodes'],
        0,
      ),
      viewCount: _parseIntField(json['viewCount'] ?? json['view_count'], 0),
      avgRating: _parseDoubleField(
        json['avgRating'] ?? json['avg_rating'],
        0.0,
      ),
      ratingCount: _parseIntField(
        json['ratingCount'] ?? json['rating_count'],
        0,
      ),
      isFeatured: _parseBoolField(
        json['isFeatured'] ?? json['is_featured'],
        false,
      ),
      isVisible: _parseBoolField(
        json['isVisible'] ?? json['is_visible'],
        true,
      ),
      scheduleDate: _parseDate(json['scheduleDate'] ?? json['schedule_date']),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
      genres: (json['genres'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) {
            try {
              return Genre.fromJson(e);
            } catch (_) {
              return null;
            }
          }).whereType<Genre>().toList() ??
          <Genre>[],
      countries: (json['countries'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) {
            try {
              return Country.fromJson(e);
            } catch (_) {
              return null;
            }
          }).whereType<Country>().toList() ??
          <Country>[],
    );
  }

  /// Parse số nguyên mềm: nhận int/num/String số/bool (Firestore lẫn MySQL cũ).
  static int _parseIntField(dynamic raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
    if (raw is bool) return raw ? 1 : 0;
    return fallback;
  }

  /// Parse bool mềm: nhận bool/int 0-1/String 'true-1' (tránh `1 as bool?` bị throw).
  static bool _parseBoolField(dynamic raw, bool fallback) {
    if (raw is bool) return raw;
    if (raw is int) return raw != 0;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final v = raw.trim().toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return fallback;
  }

  static double _parseDoubleField(dynamic raw, double fallback) {
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.trim()) ?? fallback;
    return fallback;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    // Firestore Timestamp (tránh import cloud_firestore vào model).
    try {
      final dynamic d = raw;
      final converted = d.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {}
    return DateTime.tryParse(raw.toString());
  }
}
