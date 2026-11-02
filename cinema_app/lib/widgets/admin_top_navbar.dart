import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../providers/theme_provider.dart';
import '../routes/app_routes.dart';
import 'admin_bottom_bar.dart';

/// Thanh Navbar trên cùng dùng chung cho các trang Quản trị (Admin).
///
/// - Logo `PhimHay24h Admin` nằm chính giữa (`PhimHay` màu đậm/trắng, `24h Admin` phủ gradient đỏ-cam).
/// - Bên phải: chuông báo lỗi từ người dùng (badge đỏ = số báo lỗi `pending`)
///   + nút chuyển đổi chế độ Sáng / Tối (hoặc [trailing] tuỳ chỉnh).
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

            // Chuông báo lỗi + nút Sáng / Tối bên phải
            Align(
              alignment: Alignment.centerRight,
              child: trailing ??
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _AdminReportBellButton(),
                      ListenableBuilder(
                        listenable: ThemeProvider.instance,
                        builder: (context, _) {
                          final isDarkMode =
                              ThemeProvider.instance.isDarkMode;
                          return IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Sáng / Tối',
                            icon: Icon(
                              isDarkMode
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              color: isDark
                                  ? Colors.amber
                                  : const Color(0xFF374151),
                              size: 23,
                            ),
                            onPressed: () =>
                                ThemeProvider.instance.toggleTheme(),
                          );
                        },
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chuông báo lỗi của Admin: đếm realtime số báo lỗi `pending` trong
/// collection `error_reports`. Bấm vào sẽ nhảy sang tab Thông báo (index 5)
/// để admin xử lý ngay.
class _AdminReportBellButton extends StatelessWidget {
  const _AdminReportBellButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(CollectionNames.errorReports)
          .snapshots(),
      builder: (context, snapshot) {
        int pendingCount = 0;
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final status =
                (doc.data()['status'] ?? 'pending').toString().toLowerCase();
            if (status == 'pending' || status == 'moi' || status == 'new') {
              pendingCount++;
            }
          }
        }

        return IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: pendingCount > 0
              ? '$pendingCount báo lỗi mới cần xử lý'
              : 'Báo lỗi từ người dùng',
          onPressed: () => AdminBottomBar.switchToTab(context, 5),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                pendingCount > 0
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_rounded,
                color: pendingCount > 0
                    ? const Color(0xFFFF3B4E)
                    : (isDark ? Colors.white : const Color(0xFF374151)),
                size: 23,
              ),
              if (pendingCount > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B4E),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      pendingCount > 9 ? '9+' : '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
