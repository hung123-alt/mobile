
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

/// Trang thông báo lỗi 403 - Không có quyền truy cập.
class ForbiddenPage extends StatelessWidget {
  final String? message;

  const ForbiddenPage({
    super.key,
    this.message,
  });

  static const Color primaryColor =
      Color(0xFFFF4B5C);

  void _goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFFAFAFA);

    final cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    final textColor = isDark
        ? Colors.white
        : const Color(0xFF111827);

    final subtitleColor = isDark
        ? Colors.white70
        : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),

                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),

                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFE5E7EB),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.15 : 0.05,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ===== ICON CẢNH BÁO =====
                    Container(
                      width: 100,
                      height: 100,

                      decoration: BoxDecoration(
                        color: primaryColor.withValues(
                          alpha: 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.gpp_bad_rounded,
                        size: 58,
                        color: primaryColor,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ===== MÃ LỖI =====
                    const Text(
                      '403',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ===== TIÊU ĐỀ =====
                    Text(
                      'Không có quyền truy cập',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ===== NỘI DUNG =====
                    Text(
                      message ??
                          'Bạn không có quyền truy cập '
                              'vào trang này.\n'
                              'Vui lòng liên hệ quản trị viên '
                              'nếu bạn cho rằng đây là nhầm lẫn.',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 14,
                        color: subtitleColor,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ===== NÚT VỀ TRANG CHỦ =====
                    SizedBox(
                      width: double.infinity,
                      height: 50,

                      child: ElevatedButton.icon(
                        onPressed: () => _goHome(context),

                        icon: const Icon(
                          Icons.home_rounded,
                          size: 22,
                          color: Colors.white,
                        ),

                        label: const Text(
                          'Quay về trang chủ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,

                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
