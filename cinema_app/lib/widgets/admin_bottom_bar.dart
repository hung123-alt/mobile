import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

/// Thanh điều hướng dưới cùng (BottomNavigationBar) tái sử dụng cho khu vực Admin.
///
/// Gồm 6 mục theo thiết kế:
/// 0: Tổng quan
/// 1: Phim
/// 2: Tài khoản
/// 3: Bình luận
/// 4: Thể loại
/// 5: Thông báo
class AdminBottomBar extends StatelessWidget {
  static final ValueNotifier<int> tabIndexNotifier = ValueNotifier<int>(0);

  final int? currentIndex;
  final ValueChanged<int>? onTap;

  const AdminBottomBar({
    super.key,
    this.currentIndex,
    this.onTap,
  });

  static void switchToTab(BuildContext context, int index) {
    tabIndexNotifier.value = index;
    if (ModalRoute.of(context)?.settings.name != AppRoutes.adminDashboard) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.adminDashboard,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<int>(
      valueListenable: tabIndexNotifier,
      builder: (context, notifierIndex, _) {
        final activeIndex = currentIndex ?? notifierIndex;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 0,
            currentIndex: activeIndex,
            onTap: (index) {
              if (onTap != null) {
                onTap!(index);
              } else {
                switchToTab(context, index);
              }
            },
            selectedItemColor: const Color(0xFFFF3B4E),
            unselectedItemColor:
                isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
            selectedFontSize: 10.5,
            unselectedFontSize: 10.5,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            items: const [
              BottomNavigationBarItem(
                label: 'Tổng quan',
                icon: Icon(Icons.home_outlined, size: 22),
                activeIcon: Icon(Icons.home_rounded, size: 23),
              ),
              BottomNavigationBarItem(
                label: 'Phim',
                icon: Icon(Icons.slideshow_outlined, size: 22),
                activeIcon: Icon(Icons.slideshow_rounded, size: 23),
              ),
              BottomNavigationBarItem(
                label: 'Tài khoản',
                icon: Icon(Icons.person_outline_rounded, size: 22),
                activeIcon: Icon(Icons.person_rounded, size: 23),
              ),
              BottomNavigationBarItem(
                label: 'Bình luận',
                icon: Icon(Icons.sms_outlined, size: 21),
                activeIcon: Icon(Icons.sms_rounded, size: 22),
              ),
              BottomNavigationBarItem(
                label: 'Thể loại',
                icon: Icon(Icons.grid_view_outlined, size: 21),
                activeIcon: Icon(Icons.grid_view_rounded, size: 22),
              ),
              BottomNavigationBarItem(
                label: 'Thông báo',
                icon: Icon(Icons.notifications_none_rounded, size: 22),
                activeIcon: Icon(Icons.notifications_rounded, size: 23),
              ),
            ],
          ),
        );
      },
    );
  }
}

