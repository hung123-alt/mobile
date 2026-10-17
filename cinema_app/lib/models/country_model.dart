import 'generic_entity.dart';

class Country extends GenericEntity<int> {
  final String slug;

  const Country({
    required int id,
    required String name,
    required this.slug,
  }) : super(
          id: id,
          name: name,
        );

  // Chuyển dữ liệu Map thành đối tượng Country
  factory Country.fromMap(Map<String, dynamic> map) {
    return Country(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String,
      slug: map['slug'] as String,
    );
  }

  // Chuyển đối tượng Country thành Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }

  @override
  String describe() {
    return '$name ($slug)';
  }
}