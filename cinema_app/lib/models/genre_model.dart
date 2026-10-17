import 'generic_entity.dart';

class Genre extends GenericEntity<int> {
  final String slug;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Genre({
    required int id,
    required String name,
    required this.slug,
    required this.isVisible,
    required this.createdAt,
    required this.updatedAt,
  }) : super(
          id: id,
          name: name,
        );

  // Chuyển dữ liệu Map thành đối tượng Genre
  factory Genre.fromMap(Map<String, dynamic> map) {
    return Genre(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String,
      slug: map['slug'] as String,
      isVisible: map['isVisible'] as bool? ?? true,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Chuyển đối tượng Genre thành Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'isVisible': isVisible,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String describe() {
    return '$name ($slug)';
  }
}