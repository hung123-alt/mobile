/// Hằng số toàn app.
class AppConstants {
  AppConstants._();

  // ===== API =====
  /// Base URL backend NestJS
  /// - Android emulator: dùng 10.0.2.2 thay vì localhost
  /// - Web / iOS simulator: dùng localhost
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  // ===== Phân trang =====
  static const int defaultPageSize = 12;
  static const int maxPageSize = 50;

  // ===== Điểm đánh giá =====
  static const int minRating = 1;
  static const int maxRating = 10;

  // ===== Bình luận =====
  static const int commentMaxLength = 2000;

  // ===== Key lưu trữ cục bộ =====
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUser = 'user_json';
}
