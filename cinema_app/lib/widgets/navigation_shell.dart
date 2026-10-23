import 'package:flutter/material.dart';

import '../pages/category_page.dart';
import '../pages/favorite_page.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../pages/search_page.dart';

/// Khung chính chứa BottomNavigationBar với 5 tab.
///
/// Lưu ý quan trọng: có 5 item nên BẮT BUỘC khai báo
/// `type: BottomNavigationBarType.fixed`. Nếu không, mặc định sẽ là
/// `shifting` (khi >= 4 item) -> nền lấy theo tab đang chọn,
/// chữ khó đọc.
class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndexSelected = 0;

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
    return Scaffold(
      body: _tabs[_currentIndexSelected],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndexSelected,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            label: 'Trang chủ',
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
          ),
          BottomNavigationBarItem(
            label: 'Tìm kiếm',
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            label: 'Thể loại',
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
          ),
          BottomNavigationBarItem(
            label: 'Yêu thích',
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
          ),
          BottomNavigationBarItem(
            label: 'Tài khoản',
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
          ),
        ],
      ),
    );
  }
}
