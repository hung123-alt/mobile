
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/widgets/app_bottom_bar.dart';

void main() {
  testWidgets(
    'Hiển thị thanh điều hướng và chuyển tab',
    (WidgetTester tester) async {
      int selectedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(
              child: Text('Trang kiểm thử'),
            ),
            bottomNavigationBar: AppBottomBar(
              currentIndex: 0,
              onTap: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      // Kiểm tra các tab được hiển thị
      expect(
        find.text('Trang chủ'),
        findsOneWidget,
      );

      expect(
        find.text('Thể loại'),
        findsOneWidget,
      );

      expect(
        find.text('Tìm kiếm'),
        findsOneWidget,
      );

      // Người dùng nhấn vào tab Thể loại
      await tester.tap(
        find.text('Thể loại'),
      );

      await tester.pump();

      // Tab Thể loại có index = 2
      expect(
        selectedIndex,
        2,
      );
    },
  );
}
