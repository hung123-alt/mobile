import 'package:flutter/material.dart';
import 'login_page.dart';

/// Trang Đăng ký (mở sẵn tab Đăng ký).
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage(initialIsRegister: true);
  }
}
