import 'package:flutter/material.dart';

import '../providers/theme_provider.dart';
import 'navigation_shell.dart';

/// Thanh Navbar trên cùng dùng chung toàn ứng dụng (HomePage, SearchPage, CategoryPage, FavoritePage, ProfilePage...).
///
/// Hỗ trợ đặt trực tiếp trong `Column` hoặc gán vào `Scaffold.appBar` nhờ [PreferredSizeWidget].
/// - Logo `PhimHay24h` nằm chính giữa, chữ "24h" phủ gradient đỏ-cam.
/// - Không có Hamburger icon bên trái (chỉ hiện nút Back nếu trang được push lên và [showBackIfCanPop] = true, hoặc truyền [leading] tuỳ chỉnh).
/// - Bấm vào logo mặc định sẽ quay về tab Trang chủ.
/// - Bên phải mặc định là nút chuyển đổi chế độ Sáng / Tối (hoặc truyền [trailing] tuỳ chỉnh).
class AppTopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackIfCanPop;
  final VoidCallback? onLogoTap;
  final Widget? leading;
  final Widget? trailing;

  const AppTopNavbar({
    super.key,
    this.showBackIfCanPop = false,
    this.onLogoTap,
    this.leading,
    this.trailing,
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
            // Widget bên trái (ưu tiên leading tuỳ chỉnh, hoặc nút Back nếu trang được push)
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

            // Logo PhimHay24h căn chính giữa
            GestureDetector(
              onTap: onLogoTap ?? () => NavigationShell.goHome(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
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
                            colors: [Color(0xFFFF1E27), Color(0xFFFF6A00)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                          child: const Text(
                            '24h',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
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

            // Widget bên phải (ưu tiên trailing tuỳ chỉnh, mặc định là nút Sáng / Tối)
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
                          color: isDark ? Colors.amber : const Color(0xFF374151),
                          size: 22,
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
