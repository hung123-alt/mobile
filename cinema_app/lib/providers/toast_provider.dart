import 'package:flutter/material.dart';

/// Provider thông báo toast dùng chung toàn app.
class ToastProvider extends ChangeNotifier {
  ToastProvider._();
  static final ToastProvider instance = ToastProvider._();

  void show(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red[700] : Colors.grey[900],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
