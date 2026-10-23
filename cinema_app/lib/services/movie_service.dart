import 'api_service.dart';
import '../models/movie_detail_result.dart';
import '../models/movie_model.dart';
import '../models/page_result.dart';

/// Service gọi API cho phim.
///
/// Endpoint lấy từ server/src/modules/movies/movies.controller.ts:
///   GET /movies            -> danh sách phim đang hiển thị
///   GET /movies/slug/:slug -> chi tiết phim (tăng lượt xem)
///   GET /movies/detail/:slug -> trang xem phim (phim + tập + liên quan)
///   GET /movies/random     -> random 1 phim
///   GET /movies/random/advanced -> random nhiều phim có lọc
///   GET /movies/filter     -> lọc + phân trang
///   GET /movies/:id        -> chi tiết phim theo id
///
/// Theo kiến trúc đã thống nhất: Service CHỈ gọi [ApiService] và parse JSON
/// bằng các factory `fromJson` của model. KHÔNG tự try/catch ở đây —
/// để [ApiException] bay lên cho `repositories/movie_repository.dart` xử lý,
/// giống cách Controller trong NestJS không tự bắt lỗi mà để tầng trên lo.
class MovieService {
  /// Nhận [ApiService] qua constructor (dependency injection) — giống
  /// NestJS `constructor(private readonly xxxService: XxxService) {}`.
  MovieService(this._api);

  final ApiService _api;

  /// Danh sách phim đang hiển thị (public), mới nhất trước.
  ///
  ///   GET /movies
  Future<List<Movie>> getAll() {
    return _api.getList<Movie>(
      '/movies',
      (raw) => Movie.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// Chi tiết phim theo id.
  ///
  ///   GET /movies/:id
  Future<Movie> getById(int id) {
    return _api.get<Movie>(
      '/movies/$id',
      (raw) => Movie.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// Chi tiết phim theo slug — gọi 1 lần sẽ tăng lượt xem ở server.
  ///
  ///   GET /movies/slug/:slug
  Future<Movie> getBySlug(String slug) {
    return _api.get<Movie>(
      '/movies/slug/$slug',
      (raw) => Movie.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// Trang xem phim: phim + danh sách tập + thể loại + phim liên quan.
  ///
  ///   GET /movies/detail/:slug
  Future<MovieDetailResult> getDetail(String slug) {
    return _api.get<MovieDetailResult>(
      '/movies/detail/$slug',
      (raw) => MovieDetailResult.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// Random nhanh — lấy đúng 1 phim ngẫu nhiên.
  ///
  ///   GET /movies/random
  Future<Movie> getRandomOne() {
    return _api.get<Movie>(
      '/movies/random',
      (raw) => Movie.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// Random nâng cao — lọc theo loại/trạng thái/thể loại rồi random trong
  /// nhóm thỏa điều kiện.
  ///
  /// Lưu ý khớp với `RandomMovieFilterDto` ở server:
  ///   - [genreIds] tối đa 5 phần tử, kết hợp AND (phim phải có ĐỦ các
  ///     thể loại được chọn).
  ///   - [limit] CHỈ nhận 5, 10 hoặc 15 (server validate bằng @IsIn).
  ///   - [sortBy] nhận 'view' | 'new' | 'like' | 'comment'.
  ///
  ///   GET /movies/random/advanced
  Future<List<Movie>> getRandomAdvanced({
    String? type,
    String? status,
    List<int>? genreIds,
    int limit = 10,
    String sortBy = 'view',
  }) {
    return _api.getList<Movie>(
      '/movies/random/advanced',
      (raw) => Movie.fromJson(raw as Map<String, dynamic>),
      query: {
        'type': ?type,
        'status': ?status,
        if (genreIds != null && genreIds.isNotEmpty)
          'genreIds': genreIds.join(','),
        'limit': limit,
        'sortBy': sortBy,
      },
    );
  }

  /// Lọc phim nhiều điều kiện + sắp xếp + phân trang.
  ///
  /// Khớp với `FilterMovieDto` ở server. [sortBy] nhận
  /// 'newest' | 'imdb' | 'rating' | 'views'.
  ///
  /// Server trả JSON dạng `{ data, total, page, limit, totalPages, hasMore }`
  /// — khác với [PageResult] đang mong field tên `items`. Vì vậy phải đổi
  /// tên field `data` -> `items` trước khi đưa vào `PageResult.fromJson`,
  /// thay vì sửa [PageResult] (PageResult còn dùng chung cho bình luận,
  /// nơi server trả đúng field `items`).
  ///
  ///   GET /movies/filter
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
  }) async {
    final raw = await _api.get<Map<String, dynamic>>(
      '/movies/filter',
      (raw) => raw as Map<String, dynamic>,
      query: {
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        'countryId': ?countryId,
        'country': ?country,
        'status': ?status,
        'type': ?type,
        if (genreIds != null && genreIds.isNotEmpty)
          'genreIds': genreIds.join(','),
        'releaseYear': ?releaseYear,
        'sortBy': sortBy,
        'page': page,
        'limit': limit,
      },
    );

    // Đổi tên field 'data' -> 'items' để PageResult.fromJson parse được.
    final normalized = <String, dynamic>{
      'items': raw['data'],
      'total': raw['total'],
      'page': raw['page'],
      'limit': raw['limit'],
    };

    return PageResult<Movie>.fromJson(
      normalized,
      (e) => Movie.fromJson(e as Map<String, dynamic>),
    );
  }
}
