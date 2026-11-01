import 'package:flutter/material.dart';

import '../providers/theme_provider.dart';
import '../routes/app_routes.dart';

/// Thanh Navbar trên cùng dùng chung cho các trang Quản trị (Admin).
///
/// - Logo `PhimHay24h Admin` nằm chính giữa (`PhimHay` màu đậm/trắng, `24h Admin` phủ gradient đỏ-cam).
/// - Bên phải là nút chuyển đổi chế độ Sáng / Tối (hoặc [trailing] tuỳ chỉnh).
/// - Bấm vào logo có thể gọi [onLogoTap] hoặc mở hộp thoại chuyển nhanh về Trang chủ User.
class AdminTopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onLogoTap;
  final Widget? leading;
  final Widget? trailing;
  final bool showBackIfCanPop;

  const AdminTopNavbar({
    super.key,
    this.onLogoTap,
    this.leading,
    this.trailing,
    this.showBackIfCanPop = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = showBackIfCanPop && Navigator.canPop(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (leading != null)
              Align(
                alignment: Alignment.centerLeft,
                child: leading!,
              )
            else if (canPop)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

            // Logo PhimHay24h Admin căn chính giữa
            GestureDetector(
              onTap: onLogoTap ??
                  () {
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(
                        text: 'PhimHay',
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0B1021),
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFF2438), Color(0xFFFF5E3A)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                          child: const Text(
                            '24h Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Nút chuyển chế độ Sáng / Tối bên phải
            Align(
              alignment: Alignment.centerRight,
              child: trailing ??
                  ListenableBuilder(
                    listenable: ThemeProvider.instance,
                    builder: (context, _) {
                      final isDarkMode = ThemeProvider.instance.isDarkMode;
                      return IconButton(
                        icon: Icon(
                          isDarkMode
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color:
                              isDark ? Colors.amber : const Color(0xFF374151),
                          size: 23,
                        ),
                        onPressed: () => ThemeProvider.instance.toggleTheme(),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

