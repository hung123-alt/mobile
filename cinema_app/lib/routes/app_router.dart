
import 'package:flutter/material.dart';

// ===== CÁC TRANG XÁC THỰC =====
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/forgot_password_page.dart';

// ===== CÁC TRANG NGƯỜI DÙNG =====
import '../pages/search_page.dart';
import '../pages/category_page.dart';
import '../pages/favorite_page.dart';
import '../pages/profile_page.dart';
import '../pages/account_info_page.dart';
import '../pages/watch_history_page.dart';

// ===== TRANG PHIM NGẪU NHIÊN =====
import '../pages/random_page.dart';

// ===== TRANG ADMIN =====
import '../pages/admin_dashboard_page.dart';

// ===== TRANG LỖI =====
import '../pages/forbidden_page.dart';

// ===== NAVIGATION CHÍNH =====
import '../widgets/navigation_shell.dart';

// ===== KHAI BÁO ROUTE =====
import 'app_routes.dart';

/// Quản lý điều hướng của ứng dụng PhimHay24h.
class AppRouter {
  AppRouter._();

  // ===================================================
  // 1. DANH SÁCH ROUTE
  // ===================================================
  static Map<String, WidgetBuilder> get routes => {

        // ===== ĐĂNG NHẬP =====
        AppRoutes.login: (context) =>
            const LoginPage(),

        // ===== ĐĂNG KÝ =====
        AppRoutes.register: (context) =>
            const RegisterPage(),

        // ===== QUÊN MẬT KHẨU =====
        AppRoutes.forgotPassword: (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments;

          final initialEmail =
              args is String ? args : null;

          return ForgotPasswordPage(
            initialEmail: initialEmail,
          );
        },

        // ===== TRANG CHỦ =====
        AppRoutes.home: (context) =>
            const NavigationShell(),

        // ===== TÌM KIẾM =====
        AppRoutes.search: (context) =>
            const SearchPage(),

        // ===== THỂ LOẠI =====
        AppRoutes.category: (context) =>
            const CategoryPage(),

        // ===== YÊU THÍCH =====
        AppRoutes.favorite: (context) =>
            const FavoritePage(),

        // ===== CÁ NHÂN =====
        AppRoutes.profile: (context) =>
            const ProfilePage(),

        // ===== THÔNG TIN TÀI KHOẢN =====
        AppRoutes.accountInfo: (context) =>
            const AccountInfoPage(),

        // ===== LỊCH SỬ XEM PHIM =====
        AppRoutes.watchHistory: (context) =>
            const WatchHistoryPage(),

        // ===== PHIM NGẪU NHIÊN =====
        AppRoutes.random: (context) =>
            const RandomPage(),

        // ===== ADMIN DASHBOARD =====
        AppRoutes.adminDashboard: (context) =>
            const AdminDashboardPage(),

        // ===== LỖI 403 =====
        AppRoutes.forbidden: (context) =>
            const ForbiddenPage(),
      };

  // ===================================================
  // 2. XỬ LÝ ĐIỀU HƯỚNG
  // ===================================================
  static Route<dynamic>? onGenerateRoute(
    RouteSettings settings,
  ) {
    final builder = routes[settings.name];

    // Nếu route tồn tại thì mở trang tương ứng.
    if (builder != null) {
      return MaterialPageRoute(
        settings: settings,
        builder: builder,
      );
    }

    // Nếu route không tồn tại, hiển thị trang lỗi.
    // Không tự động chuyển sang LoginPage.
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Không tìm thấy trang',
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 70,
                  color: Color(0xFFFF4B5C),
                ),

                const SizedBox(height: 20),

                const Text(
                  '404 - Trang không tồn tại',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Không tìm thấy đường dẫn: '
                  '${settings.name ?? "Không xác định"}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Quay về trang chủ',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFFF4B5C),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
