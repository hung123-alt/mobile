import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase với cấu hình theo platform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo theme sáng/tối
  await ThemeProvider.instance.initTheme();

  // Kiểm tra phiên đăng nhập đã lưu từ trước
  await AuthProvider.instance.checkAuthStatus();

  runApp(const CinemaApp());
}

class CinemaApp extends StatelessWidget {
  const CinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Nếu đã đăng nhập thì vào thẳng trang chủ, chưa thì mở trang đăng nhập
    final bool isAlreadyLoggedIn = AuthProvider.instance.isAuthenticated;

    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'PhimHay24h',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeProvider.instance.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFFFF4B5C),
            scaffoldBackgroundColor: const Color(0xFFFAFAFA),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF4B5C),
              primary: const Color(0xFFFF4B5C),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFFF4B5C),
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF4B5C),
              primary: const Color(0xFFFF4B5C),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          initialRoute: isAlreadyLoggedIn ? AppRoutes.home : AppRoutes.login,
          routes: AppRouter.routes,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}