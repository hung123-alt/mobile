import 'package:flutter/material.dart';

import 'core/firebase/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'pages/firebase_test_page.dart';

/// Hàm khởi động ứng dụng.
///
/// Vì cần chờ Firebase nạp xong trước khi vẽ giao diện, `main()` phải là
/// `async` và `runApp()` nằm SAU `await`.
Future<void> main() async {
  // Bắt buộc phải gọi trước khi dùng bất kỳ plugin nào (shared_preferences,
  // firebase, path_provider...). Nếu thiếu, app sẽ báo lỗi
  // "Binding has not yet been initialized".
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase 1 lần duy nhất cho toàn app.
  // Nếu lỗi (chưa có firebase_options.dart, hoặc sai cấu hình) thì vẫn
  // chạy được app với giao diện rỗng để bạn còn debug, thay vì trắng màn hình.
  try {
    await FirebaseService.instance.initialize();
  } catch (e) {
    debugPrint('Khởi tạo Firebase thất bại: $e');
  }

  runApp(const CinemaApp());
}

class CinemaApp extends StatelessWidget {
  const CinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhimHay24h',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const FirebaseTestPage(),
    );
  }
}
