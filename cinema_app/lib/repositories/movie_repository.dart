import 'package:flutter/foundation.dart';

import '../models/movie_detail_result.dart';
import '../models/movie_model.dart';
import '../models/page_result.dart';
import '../services/api_service.dart';
import '../services/movie_service.dart';


class MovieRepository {
  MovieRepository(this._movieService);

  final MovieService _movieService;

  /// Danh sách phim đang hiển thị (trang chủ).
  ///
  /// Lỗi mạng/máy chủ sẽ được ghi log và trả về danh sách rỗng để UI
  /// hiển thị trạng thái "chưa có phim" thay vì crash toàn trang.
  Future<List<Movie>> getMovies() async {
    try {
      return await _movieService.getAll();
    } on ApiException catch (e) {
      debugPrint('MovieRepository.getMovies lỗi: $e');
      return <Movie>[];
    }
  }

  /// Chi tiết phim theo id. Trả null nếu không tìm thấy hoặc lỗi mạng,
  /// để UI hiển thị "Không tìm thấy phim" thay vì màn hình đỏ báo lỗi.
  Future<Movie?> getMovieById(int id) async {
    try {
      return await _movieService.getById(id);
    } on ApiException catch (e) {
      debugPrint('MovieRepository.getMovieById($id) lỗi: $e');
      return null;
    }
  }

  /// Chi tiết phim theo slug — dùng khi chỉ cần thông tin phim, chưa cần
  /// danh sách tập (ví dụ hiển thị trong màn hình yêu thích/xem sau).
  Future<Movie?> getMovieBySlug(String slug) async {
    try {
      return await _movieService.getBySlug(slug);
    } on ApiException catch (e) {
      debugPrint('MovieRepository.getMovieBySlug($slug) lỗi: $e');
      return null;
    }
  }

  /// Trang xem phim đầy đủ: phim + tập + thể loại + phim liên quan.
  ///
  /// KHÔNG nuốt lỗi ở đây (không trả null) vì trang xem phim cần phân biệt
  /// rõ "đang tải" / "lỗi mạng" / "không tìm thấy" để hiển thị thông báo
  /// đúng, không thể gộp chung thành "rỗng" như [getMovies]. Lỗi
  /// [ApiException] sẽ bay lên cho Provider/Page tự quyết định hiển thị.
  Future<MovieDetailResult> getMovieDetail(String slug) {
    return _movieService.getDetail(slug);
  }

  /// Random 1 phim — dùng cho nút "Xem ngẫu nhiên" ở trang chủ.
  Future<Movie?> getRandomMovie() async {
    try {
      return await _movieService.getRandomOne();
    } on ApiException catch (e) {
      debugPrint('MovieRepository.getRandomMovie lỗi: $e');
      return null;
    }
  }

  /// Random nâng cao theo bộ lọc (loại phim, trạng thái, thể loại).
  ///
  /// Xem giải thích ràng buộc [limit]/[genreIds] trong
  /// `services/movie_service.dart` -> `getRandomAdvanced`.
  Future<List<Movie>> getRandomMovies({
    String? type,
    String? status,
    List<int>? genreIds,
    int limit = 10,
    String sortBy = 'view',
  }) async {
    try {
      return await _movieService.getRandomAdvanced(
        type: type,
        status: status,
        genreIds: genreIds,
        limit: limit,
        sortBy: sortBy,
      );
    } on ApiException catch (e) {
      debugPrint('MovieRepository.getRandomMovies lỗi: $e');
      return <Movie>[];
    }
  }

  /// Lọc phim nhiều điều kiện + sắp xếp + phân trang — dùng cho trang
  /// Thể loại và trang Tìm kiếm.
  ///
  /// Trả [PageResult.empty] khi lỗi để `widgets/pagination.dart` không
  /// phải tự xử lý trường hợp null, chỉ cần kiểm tra `items.isEmpty`.
  Future<PageResult<Movie>> filterMovies({
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
  }) async {
    try {
      return await _movieService.filter(
        keyword: keyword,
        countryId: countryId,
        country: country,
        status: status,
        type: type,
        genreIds: genreIds,
        releaseYear: releaseYear,
        sortBy: sortBy,
        page: page,
        limit: limit,
      );
    } on ApiException catch (e) {
      debugPrint('MovieRepository.filterMovies lỗi: $e');
      return PageResult<Movie>.empty();
    }
  }
}
