import 'package:flutter/material.dart';

/// Bảng màu của app - tập trung để đổi theme dễ.
class AppColors {
  AppColors._();

  // Màu chủ đạt
  static const Color primary = Color(0xFFE50914);
  static const Color primaryDark = Color(0xFFB80710);
  static const Color primaryLight = Color(0xFFFF4D51);

  // Nền
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF262626);

  // Chữ
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textDisabled = Color(0xFF666666);

  // Trạng thái
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);

  // Sao đánh giá
  static const Color starFilled = Color(0xFFFFB400);
  static const Color starEmpty = Color(0xFF3A3A3A);

  // Phân loại phim
  static const Color typeMovieLe = Color(0xFF2196F3);
  static const Color typeMovieBo = Color(0xFF9C27B0);
  static const Color typeAnimation = Color(0xFF4CAF50);
  static const Color typeAnime = Color(0xFFFF9800);
}
