import 'package:flutter/material.dart';

import '../pages/category_page.dart';
import '../pages/favorite_page.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../pages/search_page.dart';

/// Khung chính chứa BottomNavigationBar với 5 tab (chuẩn Component 8 trong ảnh).
class NavigationShell extends StatefulWidget {
  final int initialTab;

  const NavigationShell({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  late int _currentIndexSelected;

  @override
  void initState() {
    super.initState();
    _currentIndexSelected = widget.initialTab;
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndexSelected = index;
    });
  }

  final List<Widget> _tabs = [
    const HomePage(),
    const SearchPage(),
    const CategoryPage(),
    const FavoritePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndexSelected,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
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
          currentIndex: _currentIndexSelected,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFFFF4B5C), // Màu chuẩn active từ ảnh
          unselectedItemColor: const Color(0xFF6B7280), // Màu chuẩn inactive từ ảnh
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
      ),
    );
  }
}
