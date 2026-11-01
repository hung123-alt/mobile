
/// Quản lý toàn bộ đường dẫn (route) của ứng dụng PhimHay24h.
class AppRoutes {
  AppRoutes._();

  // ===== TRANG CHỦ =====
  static const String home = '/';

  // ===== ĐĂNG NHẬP / ĐĂNG KÝ =====
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // ===== CÁC TRANG NGƯỜI DÙNG =====
  static const String search = '/search';
  static const String category = '/category';
  static const String favorite = '/favorite';
  static const String profile = '/profile';
  static const String accountInfo = '/account-info';
  static const String watchHistory = '/watch-history';

  // ===== PHIM NGẪU NHIÊN =====
  static const String random = '/random';

  // ===== QUẢN TRỊ =====
  static const String adminDashboard = '/admin-dashboard';

  // ===== TRANG LỖI =====
  static const String forbidden = '/403';

  // ===== CHI TIẾT PHIM =====
  static String movieDetail(String slug) {
    return '/movie/$slug';
  }
}
