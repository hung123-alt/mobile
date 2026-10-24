import 'package:flutter/material.dart';

import '../pages/category_page.dart';
import '../pages/favorite_page.dart';
import '../pages/login_page.dart';
import '../pages/profile_page.dart';
import '../pages/register_page.dart';
import '../pages/search_page.dart';
import '../widgets/navigation_shell.dart';
import 'app_routes.dart';

/// Bộ định tuyến chung của ứng dụng
class AppRouter {
  AppRouter._();

  static Map<String, WidgetBuilder> get routes => {
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.register: (context) => const RegisterPage(),
        AppRoutes.home: (context) => const NavigationShell(),
        AppRoutes.search: (context) => const SearchPage(),
        AppRoutes.category: (context) => const CategoryPage(),
        AppRoutes.favorite: (context) => const FavoritePage(),
        AppRoutes.profile: (context) => const ProfilePage(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        settings: settings,
        builder: builder,
      );
    }

    // Mặc định chuyển về Login
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => const LoginPage(),
    );
  }
}
