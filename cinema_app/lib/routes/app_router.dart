
import 'package:flutter/material.dart';

import '../pages/account_info_page.dart';
import '../pages/admin_dashboard_page.dart';
import '../pages/category_page.dart';
import '../pages/favorite_page.dart';
import '../pages/forbidden_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/login_page.dart';
import '../pages/profile_page.dart';
import '../pages/random_page.dart';
import '../pages/register_page.dart';
import '../pages/reset_password_page.dart';
import '../pages/search_page.dart';
import '../pages/watch_history_page.dart';
import '../widgets/navigation_shell.dart';

import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Map<String, WidgetBuilder> get routes => {
        // Đăng nhập
        AppRoutes.login: (context) => const LoginPage(),

        // Đăng ký
        AppRoutes.register: (context) => const RegisterPage(),

        // Quên mật khẩu
        AppRoutes.forgotPassword: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final initialEmail = args is String ? args : null;

          return ForgotPasswordPage(
            initialEmail: initialEmail,
          );
        },

        // Đặt lại mật khẩu - giữ chức năng của nhóm
        AppRoutes.resetPassword: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          String? oobCode;

          if (args is String) {
            oobCode = args;
          } else if (args is Map) {
            final raw = args['oobCode'];
            if (raw is String) {
              oobCode = raw;
            }
          }

          return ResetPasswordPage(
            oobCode: oobCode,
          );
        },

        // Trang chủ
        AppRoutes.home: (context) => const NavigationShell(),

        // Tìm kiếm
        AppRoutes.search: (context) => const SearchPage(),

        // Thể loại
        AppRoutes.category: (context) => const CategoryPage(),

        // Yêu thích
        AppRoutes.favorite: (context) => const FavoritePage(),

        // Cá nhân
        AppRoutes.profile: (context) => const ProfilePage(),

        // Thông tin tài khoản
        AppRoutes.accountInfo: (context) => const AccountInfoPage(),

        // Lịch sử xem
        AppRoutes.watchHistory: (context) => const WatchHistoryPage(),

        // Random phim - chức năng của bạn
        AppRoutes.random: (context) => const RandomPage(),

        // Admin
        AppRoutes.adminDashboard: (context) =>
            const AdminDashboardPage(),

        // Trang lỗi 403
        AppRoutes.forbidden: (context) => const ForbiddenPage(),
      };

  static Route<dynamic>? onGenerateRoute(
    RouteSettings settings,
  ) {
    final builder = routes[settings.name];

    if (builder != null) {
      return MaterialPageRoute(
        settings: settings,
        builder: builder,
      );
    }

    // Trang không tồn tại
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Không tìm thấy trang'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 70,
                color: Color(0xFFFF4B5C),
              ),
              const SizedBox(height: 20),
              const Text(
                '404 - Trang không tồn tại',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (route) => false,
                  );
                },
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
