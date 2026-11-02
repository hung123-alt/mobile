
class AppConstants {
  AppConstants._();

  // ===== API =====
  /// Base URL của Backend REST API 
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

  // ===== Quên mật khẩu - Deep Link (Phương án 1) =====
 
  static const String resetScheme = 'cinemahay24h';
  static const String resetHost = 'reset-password';
  static const String androidPackageName = 'com.example.cinema_app';
  static const String iosBundleId = 'com.example.cinemaApp';

  static const String resetContinueUrl =
      'https://cinema-app-b760e.firebaseapp.com/reset-password';
}
