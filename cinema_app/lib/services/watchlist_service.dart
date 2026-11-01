import 'api_service.dart';
import '../models/watchlist_item_model.dart';

/// Service gọi API cho danh sách "Xem sau" (watchlist).
///
/// Endpoint lấy từ server/src/modules/watchlist/watchlist.controller.ts.
/// Tất cả route đều cần đăng nhập (@UseGuards(JwtAuthGuard) ở server) —
/// [ApiService] đã tự gắn header Authorization nếu đã setAccessToken(),
/// nên Service này không cần biết gì về token.
class WatchlistService {
  WatchlistService(this._api);

  final ApiService _api;

  /// Thêm phim vào danh sách xem sau.
  ///
  ///   POST /watchlist  body: { movieId }
  Future<void> add(int movieId) {
    return _api.postVoid('/watchlist', {'movieId': movieId});
  }

  /// Danh sách xem sau của chính mình.
  ///
  ///   GET /watchlist
  Future<List<WatchlistItem>> getMine() {
    return _api.getList<WatchlistItem>(
      '/watchlist',
      (raw) => WatchlistItem.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// Kiểm tra 1 phim đã có trong danh sách xem sau chưa.
  ///
  /// Server trả JSON dạng `{ inWatchlist: bool }` hoặc trực tiếp `bool`
  /// tùy cách WatchlistService.isInWatchlist() của NestJS trả về — xử lý
  /// cả 2 trường hợp để không vỡ khi server đổi định dạng nhỏ.
  ///
  ///   GET /watchlist/check/:movieId
  Future<bool> checkInWatchlist(int movieId) {
    return _api.get<bool>(
      '/watchlist/check/$movieId',
      (raw) {
        if (raw is bool) return raw;
        if (raw is Map<String, dynamic>) {
          return raw['inWatchlist'] as bool? ?? false;
        }
        return false;
      },
    );
  }

  /// Bỏ khỏi danh sách xem sau.
  ///
  ///   DELETE /watchlist/:movieId
  Future<void> remove(int movieId) {
    return _api.delete('/watchlist/$movieId');
  }
}
