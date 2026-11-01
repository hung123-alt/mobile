import 'episode_model.dart';
import 'genre_model.dart';
import 'movie_model.dart';

/// Kết quả chi tiết phim: phim + danh sách tập + thể loại + phim liên quan.
///
/// Khớp với GET /movies/detail/:slug từ NestJS backend.
class MovieDetailResult {
  final Movie movie;
  final List<Episode> episodes;
  final List<Genre> genres;
  final List<Movie> relatedMovies;

  MovieDetailResult({
    required this.movie,
    this.episodes = const [],
    this.genres = const [],
    this.relatedMovies = const [],
  });

  factory MovieDetailResult.fromJson(Map<String, dynamic> json) {
    final movieData = json['movie'] is Map<String, dynamic>
        ? json['movie'] as Map<String, dynamic>
        : json;

    return MovieDetailResult(
      movie: Movie.fromJson(movieData),
      episodes: (json['episodes'] as List?)
              ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      genres: (json['genres'] as List?)
              ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      relatedMovies: (json['relatedMovies'] as List?)
              ?.map((e) => Movie.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}