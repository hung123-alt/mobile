// TODO: Tên các route (hằng số)
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String search = '/search';
  static const String category = '/category';
  static const String favorite = '/favorite';
  static const String profile = '/profile';
  static const String random = '/random';
  static const String forbidden = '/403';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  /// Chi tiết phim theo slug
  static String movieDetail(String slug) => '/movie/$slug';
}
