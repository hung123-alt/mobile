
library;

class CollectionNames {
  CollectionNames._();


  static const String movies = 'movies';

  static const String users = 'users';

  /// Thể loại - server/src/modules/genres/genre.entity.ts
  static const String genres = 'genres';

  /// Quốc gia - server/src/modules/countries/countries.entity.ts
  static const String countries = 'countries';

  /// Tập phim - server/src/modules/episodes/episode.entity.ts
  static const String episodes = 'episodes';

  /// Bình luận - server/src/modules/comments/comment.entity.ts
  /// (Lưu ý: tên bảng là `comments` dù tên class là `CommentEntity`)
  static const String comments = 'comments';

  /// Đánh giá - server/src/modules/ratings/rating.entity.ts
  static const String ratings = 'ratings';

  /// Yêu thích - server/src/modules/favorites/favorite.entity.ts
  static const String favorites = 'favorites';

  /// Danh sách xem - server/src/modules/watchlist/watchlist.entity.ts
  static const String watchlist = 'watchlist';

  /// Lịch sử xem - server/src/modules/watch-history/watch-history.entity.ts
  static const String watchHistory = 'watch_history';

  /// Thông báo - server/src/modules/notifications/notification.entity.ts
  static const String notifications = 'notifications';

  /// Báo lỗi phim - server/src/modules/error-reports/error-report.entity.ts
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

  /// Lịch sử xem của 1 user: users/{uid}/watch_history
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

  /// Tên field chỉ dùng ở TRONG Firestore (tự sinh, không có trong MySQL).
  ///
  /// Giải thích: MySQL tự sinh `id` tăng dần (1, 2, 3...). Firestore thì
  /// Document ID là chuỗi ngẫu nhiên ("Xy7K2mPq..."). Model Dart đang khai báo
  /// `extends BaseEntity<int>` nên vẫn CẦN một field `id` kiểu int.
  ///
  /// Ta giải quyết bằng cách: **Document ID dùng slug/uid (dễ đọc),
  /// còn field `id` bên trong vẫn giữ kiểu int** để model không phải sửa.
  /// `docId` lưu Document ID để dùng lại khi cần update/delete.
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

  /// countries: dùng `slug` → `countries/viet-nam`
  static String country(String slug) => slug;

  /// users: dùng `uid` của Firebase Auth → `users/abc123XYZ`
  ///
  /// Đây là điểm khác biệt lớn nhất so với hệ thống cũ:
  /// bảng `users` cũ có `password_hash` + `reset_token`, giờ do
  /// Firebase Auth quản lý. Vì vậy collection `users` của ta chỉ chứa
  /// THÔNG TIN HIỂN THỊ (tên, avatar, vai trò) chứ không chứa mật khẩu.
  static String user(String uid) => uid;

  /// episodes: dùng `{movieId}_{tap}` → `episodes/12_5` (tập 5 của phim 12)
  ///
  /// Gộp 2 trường vào 1 Doc ID để truy vấn tập phim của 1 phim chỉ cần
  /// 1 lần đọc collection, không cần filter theo movieId.
  static String episode(String movieId, int episodeNumber) {
    return '${movieId}_$episodeNumber';
  }

  /// ratings: dùng `uid` → `ratings/abc123XYZ`
  ///
  /// Khớp với MySQL cũ vốn có KHÓA CHÍNH KÉP (user_id, movie_id).
  /// Với Firestore, dùng uid làm Doc ID là cách chặn 1 user đánh giá
  /// trùng lặp (ghi đè thay vì tạo bản mới).
  static String rating(String uid) => uid;

  /// watch_history: dùng `{movieId}` → `watch_history/12`
  ///
  /// 1 dòng lịch sử cho mỗi phim. Xem lại tập nào lưu ở field `episodeId`.
  static String watchHistory(String movieId) => movieId;

  /// favorites / watchlist: dùng `movieId` → `favorites/12`
  static String favorite(String movieId) => movieId;
}

/// Ghi chú về Firestore Security Rules (không nằm trong code nhưng cần biết)
///
/// Trước khi chạy thật, phải viết rules trong Firestore Console, nếu không
/// mọi lệnh ghi sẽ bị từ chối (PERMISSION_DENIED):
///
///   rules_version = '2';
///   service cloud.firestore {
///     match /databases/{database}/documents {
///       match /movies/{movieId} {
///         allow read: if true;                    // ai cũng xem được phim
///         allow write: if false;                  // chỉ admin qua SDK
///       }
///       match /users/{uid} {
///         allow read, write: if request.auth.uid == uid;  // chỉ chính chủ
///       }
///       match /comments/{commentId} {
///         allow read: if true;
///         allow write: if request.auth.uid == request.resource.data.userId;
///       }
///     }
///   }
///
/// Ngoài ra cần BẬT BILLING cho Firestore, nếu không mọi truy vấn trả về
/// lỗi "Missing or insufficient permissions" dù rules đã đúng.