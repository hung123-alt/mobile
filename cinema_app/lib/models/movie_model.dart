class Movies{
  final int id;
  final String title;
  final String? description;
  final String thumbnail;
  final int categoryId;
  final int countryId;
  final int releaseYear;
  final String movieType;
  final String? status;
  final DateTime createdAt;
  final DateTime updatedAt;


  const Movies({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.categoryId,
    required this.countryId,
    required this.releaseYear,
    required this.movieType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  //Chuyển data từ Map sang Object Movies --> DB
  factory Movies.fromMap(Map<String, dynamic> map) {
    return Movies(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      thumbnail: map['thumbnail'] as String,
      categoryId: map['categoryId'] as int,
      countryId: map['countryId'] as int,
      releaseYear: map['releaseYear'] as int,
      movieType: map['movieType'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  //Chuyển data từ Object Movies sang Map --> local
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
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
}