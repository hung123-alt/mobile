import 'package:cinema_app/models/movie_model.dart';

abstract class MovieRepository {
  List<Movies> getAllMovies();
  Movies? getMovieById(int id);
  void addMovie(Movies movie);
}

class MockMovies implements MovieRepository {
  final List<Movies> _listMovies = [
    Movies(
      id: 1,
      title: "Sample Movie",
      description: "This is a sample movie",
      thumbnail: "https://example.com/thumbnail.jpg",
      categoryId: 1,
      countryId: 1,
      releaseYear: 2020,
      movieType: "Movie",
      status: "Active",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )
  ];

  @override
  List<Movies> getAllMovies() {
    return _listMovies;
  }

  @override
  Movies? getMovieById(int id) {
    return _listMovies.firstWhere((movie) => movie.id == id, orElse: () => Movies(
      id: -1,
      title: "",
      description: "",
      thumbnail: "",
      categoryId: -1,
      countryId: -1,
      releaseYear: -1,
      movieType: "",
      status: "",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  void addMovie(Movies movie) {
    _listMovies.add(movie);
  }
}