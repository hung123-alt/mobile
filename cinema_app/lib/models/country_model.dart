import 'base_entity.dart';

/// Model quốc gia - kế thừa BaseEntity<int>
///
/// Khớp với server/src/modules/countries/countries.entity.ts
class Country extends BaseEntity<int> {
  final String slug;
  final bool isVisible;

  Country({
    required int id,
    required String name,
    required String description,
    required this.slug,
    required this.isVisible,
  }) : super(id: id, name: name, description: description);

  /// Parse từ JSON
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }
}
