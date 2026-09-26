import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/category_page.dart';
import 'pages/favorite_page.dart';
import 'pages/profile_page.dart';
/// Widget cha chứa Bottom Navigation Bar 5 tab.
/// Theo phong cách code của thầy: StatefulWidget giữ currentIndex,
/// Scaffold có body = _tabs[index] và bottomNavigationBar = BottomNavigationBar.
class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({super.key, required this.title});
  final String title;
  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}
class _BottomNavigationPageState extends State<BottomNavigationPage> {
  int _currentIndexSelected = 0;
  void _onItemTapped(int index) {
    setState(() {
      _currentIndexSelected = index;
    });
  }
  // 5 màn hình web phim
  final List<Widget> _tabs = [
    const HomePage(),
    const SearchPage(),
    const CategoryPage(),
    const FavoritePage(),
    const ProfilePage(),
  ];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      home: Scaffold(
        body: _tabs[_currentIndexSelected],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndexSelected,
          onTap: _onItemTapped,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Trang chu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Tim kiem',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'The loai',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Yeu thich',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Tai khoan',
            ),
          ],
        ),
      ),
    );
  }
}
