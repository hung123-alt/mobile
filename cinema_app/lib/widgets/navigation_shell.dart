import 'package:flutter/material.dart';

import '../assistant/assistant_manager.dart';
import '../assistant/assistant_orb.dart';
import '../assistant/assistant_panel.dart';
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
  double _orbX = 0;
  double _orbY = 0;
  bool _orbInit = false;

  @override
  void initState() {
    super.initState();
    _currentIndexSelected = widget.initialTab;
    NavigationShell.tabIndexNotifier.value = _currentIndexSelected;
    NavigationShell.tabIndexNotifier.addListener(_handleExternalTabChange);
    // Nạp cài đặt Lina/Seven của user hiện tại (bật/tắt + persona).
    AssistantManager.instance.loadForCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AssistantManager.instance.brain.attachContext(context);
    });
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (!_orbInit) {
            _orbInit = true;
            _orbX = constraints.maxWidth - 92;
            _orbY = constraints.maxHeight - 190;
          }
          return Stack(
            children: [
              IndexedStack(
                index: _currentIndexSelected,
                children: _tabs,
              ),
              // Orb Lina/Seven nổi ở góc, kéo thả được, bấm để mở panel chat.
              Positioned(
                left: _orbX.clamp(0, constraints.maxWidth - 84),
                top: _orbY.clamp(0, constraints.maxHeight - 100),
                child: Draggable(
                  feedback: AssistantOrb(
                    onTap: () {},
                  ),
                  childWhenDragging: const SizedBox(width: 76, height: 76),
                  onDragEnd: (details) {
                    setState(() {
                      _orbX = (details.offset.dx - 0)
                          .clamp(0, constraints.maxWidth - 84);
                      _orbY = (details.offset.dy - 90)
                          .clamp(0, constraints.maxHeight - 100);
                    });
                  },
                  child: AssistantOrb(
                    onTap: () {
                      AssistantManager.instance.brain.attachContext(context);
                      AssistantPanel.show(context);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _currentIndexSelected,
        onTap: _onItemTapped,
      ),
    );
  }
}
