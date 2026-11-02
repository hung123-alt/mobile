// ignore_for_file: unintended_html_in_doc_comment
import 'base_entity.dart';

/// Model quốc gia - kế thừa BaseEntity<int>
class Country extends BaseEntity<int> {
  final String slug;
  final bool isVisible;

  Country({
    required super.id,
    required super.name,
    required super.description,
    required this.slug,
    required this.isVisible,
  });

  /// Parse từ JSON (hỗ trợ cả camelCase và snake_case, id kiểu lẫn lộn).
  factory Country.fromJson(Map<String, dynamic> json, {String? docId}) {
    var parsedId = _parseIntField(json['id'] ?? json['country_id'], 0);
    if (parsedId == 0 && docId != null) {
      parsedId = int.tryParse(docId.trim()) ?? 0;
    }
    return Country(
      id: parsedId,
      name: (json['name'] ?? json['title'])?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      isVisible: _parseBoolField(
        json['isVisible'] ?? json['is_visible'],
        true,
      ),
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
}
