library;

class CollectionNames {
  CollectionNames._();


  static const String movies = 'movies';

  static const String users = 'users';

  /// Thể loại phim (danh mục genres)
  static const String genres = 'genres';

  /// Quốc gia (danh mục countries)
  static const String countries = 'countries';

  /// Tập phim (collection episodes, lọc theo movieId)
  static const String episodes = 'episodes';

  /// Bình luận (collection comments / sub-collection movies/{slug}/comments)
  static const String comments = 'comments';

  /// Đánh giá (sub-collection movies/{slug}/ratings)
  static const String ratings = 'ratings';

  /// Yêu thích (sub-collection users/{uid}/favorites)
  static const String favorites = 'favorites';

  /// Danh sách xem sau (sub-collection users/{uid}/watchlist)
  static const String watchlist = 'watchlist';

  /// Lịch sử xem (top-level watch_history, docId = {uid}_{movieId})
  static const String watchHistory = 'watch_history';

  /// Thông báo (sub-collection users/{uid}/notifications)
  static const String notifications = 'notifications';

  /// Báo lỗi phim (top-level error_reports)
  static const String errorReports = 'error_reports';

  // ============================================================
  // SUB-COLLECTION (dùng khi dữ liệu luôn thuộc về 1 bản ghi cha)
  // ============================================================

  /// Tập phim của 1 phim: movies/{movieId}/episodes
  static String movieEpisodes(String movieId) => '$movies/$movieId/$episodes';

  /// Đánh giá của 1 phim: movies/{movieId}/ratings
  static String movieRatings(String movieId) => '$movies/$movieId/$ratings';

  /// Bình luận của 1 phim: movies/{movieId}/comments
  static String movieComments(String movieId) => '$movies/$movieId/$comments';

  /// Yêu thích của 1 user: users/{uid}/favorites
  static String userFavorites(String uid) => '$users/$uid/$favorites';

  /// Danh sách xem của 1 user: users/{uid}/watchlist
  static String userWatchlist(String uid) => '$users/$uid/$watchlist';

  /// Lịch sử xem — CANONICAL hiện tại là top-level `watch_history`
  /// với docId = `{userIdInt}_{movieId}` (VD `12_45`), code trong
  /// `WatchHistoryProvider.recordWatch` đang dùng cách này.
  /// Helper sub-collection dưới đây giữ lại cho tương lai, hiện chưa dùng.
  static String userWatchHistory(String uid) => '$users/$uid/$watchHistory';

  /// Thông báo của 1 user: users/{uid}/notifications
  static String userNotifications(String uid) => '$users/$uid/$notifications';
}

/// Tên field dùng trong truy vấn (where/orderBy).
///
/// Tách riêng khỏi [CollectionNames] vì đây là tầng "truy vấn",
/// còn CollectionNames là tầng "vị trí dữ liệu".
class FieldNames {
  FieldNames._();

  // ===== movies =====
  static const String id = 'id';
  static const String title = 'title';
  static const String name = 'name';
  static const String slug = 'slug';
  static const String description = 'description';
  static const String posterUrl = 'posterUrl';
  static const String bannerUrl = 'bannerUrl';
  static const String type = 'type';
  static const String status = 'status';
  static const String releaseYear = 'releaseYear';
  static const String totalEpisodes = 'totalEpisodes';
  static const String viewCount = 'viewCount';
  static const String avgRating = 'avgRating';
  static const String ratingCount = 'ratingCount';
  static const String isFeatured = 'isFeatured';
  static const String isVisible = 'isVisible';
  static const String scheduleDate = 'scheduleDate';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';

  // ===== genres / countries =====
  static const String genreSlug = 'genreSlug';

  // ===== episodes =====
  static const String movieId = 'movieId';
  static const String episodeNumber = 'episodeNumber';
  static const String embedUrl = 'embedUrl';
  static const String serverName = 'serverName';
  static const String skipIntroSeconds = 'skipIntroSeconds';
  static const String durationSeconds = 'durationSeconds';

  // ===== comments =====
  static const String userId = 'userId';
  static const String parentId = 'parentId';
  static const String content = 'content';
  static const String isHidden = 'isHidden';

  // ===== ratings =====
  static const String score = 'score';

  // ===== watch_history =====
  static const String episodeId = 'episodeId';
  static const String progressSeconds = 'progressSeconds';

  // ===== notifications =====
  static const String notificationType = 'type';
  static const String notificationTitle = 'title';
  static const String isRead = 'isRead';
  static const String linkUrl = 'linkUrl';

  /// Field phụ lưu Document ID để dùng lại khi update/delete.
  /// Firestore Document ID luôn là chuỗi (ví dụ slug hoặc uid).
  /// Các model Dart vẫn giữ field `id` kiểu int để tương thích
  /// với Backend REST API, còn `docId` là định danh Firestore.
  static const String docId = '__docId';
}

/// Quy ước về Document ID cho từng collection.
///
/// Firestore bắt buộc Document ID là chuỗi. Ta chọn ID sao cho CÓ Ý NGHĨA
/// thay vì để Firestore tự sinh, để sau này debug dễ hơn.
class DocIdStrategy {
  DocIdStrategy._();

  /// movies: dùng `slug` → `movies/dang-ky-hoc-thuat-siec`
  ///
  /// Vì URL chi tiết phim đã cần slug rồi (AppRoutes.movieDetail(slug)),
  /// dùng slug làm Doc ID là 1 chức năng gộp 2 việc.
  static String movie(String slug) => slug;

  /// genres: dùng `slug` → `genres/hanh-dong`
  static String genre(String slug) => slug;


  static String country(String slug) => slug;

  /// users: dùng `uid` của Firebase Auth → `users/abc123XYZ`
  ///
  /// Mật khẩu do Firebase Auth quản lý (đã hash + salt).
  /// Collection `users` chỉ chứa THÔNG TIN HIỂN THỊ
  /// (tên, avatar, vai trò) — KHÔNG bao giờ lưu mật khẩu.
  static String user(String uid) => uid;

  /// episodes: dùng `{movieId}_{tap}` → `episodes/12_5` (tập 5 của phim 12)
  ///
  /// Gộp 2 trường vào 1 Doc ID để truy vấn tập phim của 1 phim chỉ cần
  /// 1 lần đọc collection, không cần filter theo movieId.
  static String episode(String movieId, int episodeNumber) {
    return '${movieId}_$episodeNumber';
  }

  /// ratings: docId = Firebase Auth `uid` → `ratings/{uid}`
  /// trong sub-collection `movies/{slug}/ratings`.
  /// Mỗi user chỉ có 1 doc đánh giá / phim → ghi đè khi chấm lại,
  /// không tạo bản trùng.
  static String rating(String uid) => uid;

  /// watch_history top-level: docId = `{uidInt}_{movieId}` (ví dụ `12_45`).
  /// 1 doc / phim / user. Tập đang xem lưu ở field `episodeId`.
  static String watchHistory(String uidAndMovie) => uidAndMovie;

  /// favorites / watchlist trong sub-collection user:
  /// `users/{uid}/favorites/{movieId}` → docId = movieId dạng chuỗi.
  static String favorite(String movieId) => movieId;
}

/// Ghi chú deploy: file rules thật nằm ở `cinema_app/firestore.rules`.
/// Copy nội dung file đó dán vào Firebase Console → Firestore → Rules,
/// hoặc chạy `firebase deploy --only firestore:rules` (xem `firebase.json`).
/// Không sửa rules mẫu ở đây — sửa file `firestore.rules` để khỏi lệch.