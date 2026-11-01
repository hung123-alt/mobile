import 'package:flutter/material.dart';

import '../pages/category_page.dart';
import '../pages/favorite_page.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../pages/search_page.dart';
import 'app_bottom_bar.dart';

/// Khung chính chứa 5 tab màn hình và sử dụng [AppBottomBar] dùng chung.
class NavigationShell extends StatefulWidget {
  final int initialTab;

  const NavigationShell({
    super.key,
    this.initialTab = 0,
  });

  /// Notifier điều khiển tab hiện tại từ bất kỳ trang con nào
  static final ValueNotifier<int> tabIndexNotifier = ValueNotifier<int>(0);

  /// Chuyển sang một tab bất kỳ theo [index] (và đóng các trang phụ được push lên nếu có)
  static void switchToTab(BuildContext context, int index) {
    tabIndexNotifier.value = index;
    if (Navigator.canPop(context)) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  /// Chuyển về tab Trang chủ (index = 0)
  static void goHome(BuildContext context) => switchToTab(context, 0);

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  late int _currentIndexSelected;

  @override
  void initState() {
    super.initState();
    _currentIndexSelected = widget.initialTab;
    NavigationShell.tabIndexNotifier.value = _currentIndexSelected;
    NavigationShell.tabIndexNotifier.addListener(_handleExternalTabChange);
  }

  @override
  void dispose() {
    NavigationShell.tabIndexNotifier.removeListener(_handleExternalTabChange);
    super.dispose();
  }

  void _handleExternalTabChange() {
    final target = NavigationShell.tabIndexNotifier.value;
    if (mounted && _currentIndexSelected != target) {
      setState(() {
        _currentIndexSelected = target;
      });
    }
  }

  void _onItemTapped(int index) {
    NavigationShell.tabIndexNotifier.value = index;
    setState(() {
      _currentIndexSelected = index;
    });
  }

  final List<Widget> _tabs = const [
    HomePage(),
    SearchPage(),
    CategoryPage(),
    FavoritePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndexSelected,
        children: _tabs,
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _currentIndexSelected,
        onTap: _onItemTapped,
      ),
    );
  }
}
