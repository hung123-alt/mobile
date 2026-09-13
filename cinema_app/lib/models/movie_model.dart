class Movies{
  final int id;
  final String title;
  final String? dicription;
  final String thumbnail;
  final int categoryId;
  final int releaseYear;
  final String movieType;
  final String? status;
  final DateTime createAt;
  final DateTime updateAt;


  const Movies({
    required this.id,
    required this.title,
    required this.dicription,
    required this.thumbnail,
    required this.categoryId,
    required this.releaseYear,
    required this.movieType,
    required this.status,
    required this.createAt,
    required this.updateAt,
  });
  
}