import 'generic_entity.dart';

class Movies extends GenericEntity<int> {
  final String thumbnail;
  final int categoryId;
  final int countryId;
  final int releaseYear;
  final String movieType;
  final String? status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Movies({
    required int id,
    required String title,
    required String? description,
    required this.thumbnail,
    required this.categoryId,
    required this.countryId,
    required this.releaseYear,
    required this.movieType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  }) : super(
          id: id,
          name: title,
          description: description,
        );

  // Giữ lại tên title để tương thích với code cũ
  String get title => name;

  // Chuyển Map thành đối tượng Movies
  factory Movies.fromMap(Map<String, dynamic> map) {
    return Movies(
      id: (map['id'] as num).toInt(),
      title: map['title'] as String,
      description: map['description'] as String?,
      thumbnail: map['thumbnail'] as String,
      categoryId: (map['categoryId'] as num).toInt(),
      countryId: (map['countryId'] as num).toInt(),
      releaseYear: (map['releaseYear'] as num).toInt(),
      movieType: map['movieType'] as String,
      status: map['status'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Chuyển đối tượng Movies thành Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': name,
      'description': description,
      'thumbnail': thumbnail,
      'categoryId': categoryId,
      'countryId': countryId,
      'releaseYear': releaseYear,
      'movieType': movieType,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Ghi đè phương thức mô tả chung
  @override
  String describe() {
    return '$name ($releaseYear)';
  }
}