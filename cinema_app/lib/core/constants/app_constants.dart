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

  // ===== Quên mật khẩu - Deep Link (Phương án 1) =====
  /// Custom scheme để app bắt link reset sau khi Firebase redirect.
  /// Phải khớp với <intent-filter> trong AndroidManifest và CFBundleURLTypes
  /// trong Info.plist. Mobile KHÔNG dùng cookie nên không cần lo CSRF như web.
  static const String resetScheme = 'cinemahay24h';
  static const String resetHost = 'reset-password';
  static const String androidPackageName = 'com.example.cinema_app';
  static const String iosBundleId = 'com.example.cinemaApp';

  /// Continue URL kèm trong ActionCodeSettings khi gửi email reset.
  /// PHẢI là `https` và nằm trong Authorized domains của Firebase
  /// (domain *.firebaseapp.com có sẵn) — custom-scheme sẽ bị từ chối
  /// với lỗi "Domain not whitelisted by project".
  static const String resetContinueUrl =
      'https://cinema-app-b760e.firebaseapp.com/reset-password';
}
