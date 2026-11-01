import 'package:flutter/material.dart';

import 'navigation_shell.dart';

/// Thanh điều hướng dưới cùng (BottomNavigationBar) dùng chung toàn ứng dụng.
///
/// Có thể truyền trực tiếp [currentIndex] và [onTap] (như trong [NavigationShell]),
/// hoặc đặt độc lập ở bất kỳ trang nào (mặc định sẽ đồng bộ với [NavigationShell]).
class AppBottomBar extends StatelessWidget {
  final int? currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomBar({super.key, this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<int>(
      valueListenable: NavigationShell.tabIndexNotifier,
      builder: (context, notifierIndex, _) {
        final activeIndex = currentIndex ?? notifierIndex;

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            currentIndex: activeIndex,
            onTap: (index) {
              if (onTap != null) {
                onTap!(index);
              } else {
                NavigationShell.switchToTab(context, index);
              }
            },
            selectedItemColor: const Color(0xFFFF4B5C),
            unselectedItemColor: const Color(0xFF6B7280),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            items: const [
              BottomNavigationBarItem(
                label: 'Trang chủ',
                icon: Icon(Icons.home_outlined, size: 22),
                activeIcon: Icon(Icons.home_rounded, size: 22),
              ),
              BottomNavigationBarItem(
                label: 'Tìm kiếm',
                icon: Icon(Icons.search_rounded, size: 22),
                activeIcon: Icon(Icons.search_rounded, size: 24),
              ),
              BottomNavigationBarItem(
                label: 'Thể loại',
                icon: Icon(Icons.grid_view_rounded, size: 20),
                activeIcon: Icon(Icons.grid_view_rounded, size: 21),
              ),
              BottomNavigationBarItem(
                label: 'Yêu thích',
                icon: Icon(Icons.favorite_outline_rounded, size: 21),
                activeIcon: Icon(Icons.favorite_rounded, size: 21),
              ),
              BottomNavigationBarItem(
                label: 'Tài khoản',
                icon: Icon(Icons.person_outline_rounded, size: 22),
                activeIcon: Icon(Icons.person_rounded, size: 22),
              ),
            ],
          ),
        );
      },
    );
  }
}
