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
    required int id,
    required String name,
    required String description,
    required this.slug,
    required this.isVisible,
    required this.createdAt,
    required this.updatedAt,
  }) : super(id: id, name: name, description: description);

  /// Parse từ JSON. Server trả `name` cho genre (không phải `title`)
  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      isVisible: json['isVisible'] as bool? ?? true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
