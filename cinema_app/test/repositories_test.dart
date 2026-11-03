/// 8b + 8a — Unit test cho Repository: bat loi ApiException o ranh gioi I/O.
/// Moi repository phai TRA VE gia tri an toan thay vi nem loi len UI.
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/models/comment_model.dart';
import 'package:cinema_app/models/movie_model.dart';
import 'package:cinema_app/models/movie_detail_result.dart';
import 'package:cinema_app/models/page_result.dart';
import 'package:cinema_app/models/watchlist_item_model.dart';
import 'package:cinema_app/repositories/comment_repository.dart';
import 'package:cinema_app/repositories/movie_repository.dart';
import 'package:cinema_app/repositories/watchlist_repository.dart';
import 'package:cinema_app/services/api_service.dart';
import 'package:cinema_app/services/comment_service.dart';
import 'package:cinema_app/services/movie_service.dart';
import 'package:cinema_app/services/watchlist_service.dart';

/// MovieService gia: tat ca deu nem ApiException de gia lap loi mang.
class _FailMovieService extends MovieService {
  _FailMovieService() : super(ApiService());

  @override
  Future<List<Movie>> getAll() => throw ApiException(500, 'mang loi');

  @override
  Future<Movie> getById(int id) => throw ApiException(404, 'khong thay');

  @override
  Future<Movie> getBySlug(String slug) =>
      throw ApiException(404, 'khong thay');

  @override
  Future<MovieDetailResult> getDetail(String slug) =>
      throw ApiException(500, 'mang loi');

  @override
  Future<Movie> getRandomOne() => throw ApiException(500, 'mang loi');

  @override
  Future<List<Movie>> getRandomAdvanced({
    String? type,
    String? status,
    List<int>? genreIds,
    int limit = 10,
    String sortBy = 'view',
  }) =>
      throw ApiException(500, 'mang loi');

  @override
  Future<PageResult<Movie>> filter({
    String? keyword,
    int? countryId,
    String? country,
    String? status,
    String? type,
    List<int>? genreIds,
    int? releaseYear,
    String sortBy = 'newest',
    int page = 1,
    int limit = 20,
  }) =>
      throw ApiException(500, 'mang loi');
}

/// WatchlistService gia bao loi.
class _FailWatchlistService extends WatchlistService {
  _FailWatchlistService() : super(ApiService());
  @override
  Future<void> add(int movieId) => throw ApiException(401, 'chua login');
  @override
  Future<List<WatchlistItem>> getMine() =>
      throw ApiException(500, 'mang loi');
  @override
  Future<bool> checkInWatchlist(int movieId) =>
      throw ApiException(500, 'mang loi');
  @override
  Future<void> remove(int movieId) => throw ApiException(500, 'mang loi');
}

/// CommentService gia bao loi.
class _FailCommentService extends CommentService {
  _FailCommentService() : super(ApiService());
  @override
  Future<Comment> create({
    required int movieId,
    required String content,
    int? parentId,
  }) =>
      throw ApiException(500, 'mang loi');
  @override
  Future<List<Comment>> getByMovie(int movieId) =>
      throw ApiException(500, 'mang loi');
  @override
  Future<void> remove(int commentId) =>
      throw ApiException(403, 'khong quyen');
}

void main() {
  group('MovieRepository bat loi (8a/8d)', () {
    test('getMovies loi -> [] (khong crash Home)', () async {
      final repo = MovieRepository(_FailMovieService());
      expect(await repo.getMovies(), isEmpty);
    });

    test('getMovieById loi -> null (hien "khong tim thay")', () async {
      final repo = MovieRepository(_FailMovieService());
      expect(await repo.getMovieById(1), isNull);
    });

    test('getMovieBySlug loi -> null', () async {
      final repo = MovieRepository(_FailMovieService());
      expect(await repo.getMovieBySlug('x'), isNull);
    });

    test('getRandomMovie loi -> null', () async {
      final repo = MovieRepository(_FailMovieService());
      expect(await repo.getRandomMovie(), isNull);
    });

    test('getRandomMovies loi -> []', () async {
      final repo = MovieRepository(_FailMovieService());
      expect(await repo.getRandomMovies(), isEmpty);
    });

    test('filterMovies loi -> PageResult.empty (khong crash phan trang)',
        () async {
      final repo = MovieRepository(_FailMovieService());
      final p = await repo.filterMovies(keyword: 'x');
      expect(p.items, isEmpty);
      expect(p.total, 0);
    });

    test('getMovieDetail KHONG nuot loi (de Page phan biet trang thai)',
        () async {
      final repo = MovieRepository(_FailMovieService());
      expect(
        () => repo.getMovieDetail('x'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('WatchlistRepository bat loi (8a/8d)', () {
    test('add loi -> false', () async {
      expect(await WatchlistRepository(_FailWatchlistService()).add(1),
          isFalse);
    });

    test('getMine loi -> []', () async {
      expect(
          await WatchlistRepository(_FailWatchlistService()).getMine(),
          isEmpty);
    });

    test('isInWatchlist loi -> false (nut khong ket o trang thai sai)',
        () async {
      expect(
          await WatchlistRepository(_FailWatchlistService())
              .isInWatchlist(1),
          isFalse);
    });

    test('remove loi -> false', () async {
      expect(await WatchlistRepository(_FailWatchlistService()).remove(1),
          isFalse);
    });
  });

  group('CommentRepository bat loi (8a/8d)', () {
    test('create loi -> null', () async {
      expect(
          await CommentRepository(_FailCommentService())
              .create(movieId: 1, content: 'hi'),
          isNull);
    });

    test('getByMovie loi -> []', () async {
      expect(await CommentRepository(_FailCommentService()).getByMovie(1),
          isEmpty);
    });

    test('remove loi -> false', () async {
      expect(await CommentRepository(_FailCommentService()).remove(1),
          isFalse);
    });
  });

  group('ApiException toString (8d)', () {
    test('dinh dang', () {
      expect(ApiException(404, 'het').toString(), contains('404'));
    });
  });
}
