// ignore_for_file: unintended_html_in_doc_comment
import 'base_entity.dart';

/// Model thể loại phim - kế thừa BaseEntity<int>
///
/// Khớp với server/src/modules/genres/genre.entity.ts
class Genre extends BaseEntity<int> {
  final String slug;
  final bool isVisible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Genre({
    required super.id,
    required super.name,
    required super.description,
    required this.slug,
    required this.isVisible,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse mềm từ Firestore/MySQL cũ: id/slug/is_visible có thể lẫn
  /// kiểu int-String-bool. Dùng helper thay vì `as int?` để tránh throw
  /// làm rớt cả document phim khi enrich.
  factory Genre.fromJson(Map<String, dynamic> json, {String? docId}) {
    var parsedId = _parseIntField(json['id'] ?? json['genre_id'], 0);
    if (parsedId == 0 && docId != null) {
      parsedId = int.tryParse(docId.trim()) ?? 0;
    }
    final createdRaw = json['createdAt'] ?? json['created_at'];
    final updatedRaw = json['updatedAt'] ?? json['updated_at'];
    return Genre(
      id: parsedId,
      name: (json['name'] ?? json['title'])?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      isVisible: _parseBoolField(
        json['isVisible'] ?? json['is_visible'],
        true,
      ),
      createdAt: _parseDate(createdRaw),
      updatedAt: _parseDate(updatedRaw),
    );
  }

  static int _parseIntField(dynamic raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
    if (raw is bool) return raw ? 1 : 0;
    return fallback;
  }

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

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    try {
      final dynamic d = raw;
      final converted = d.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {}
    return DateTime.tryParse(raw.toString());
  }
}
