import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/widgets/admin_bottom_bar.dart';

void main() {
  group('Kiểm thử thanh điều hướng quản trị (AdminBottomBar)', () {
    testWidgets(
      'Hiển thị đầy đủ 6 tab quản trị và xử lý chuyển tab',
      (WidgetTester tester) async {
        int tappedIndex = -1;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const Center(
                child: Text('Khu vực Quản trị'),
              ),
              bottomNavigationBar: AdminBottomBar(
                currentIndex: 0,
                onTap: (index) {
                  tappedIndex = index;
                },
              ),
            ),
          ),
        );

        expect(find.text('Tổng quan'), findsOneWidget);
        expect(find.text('Phim'), findsOneWidget);
        expect(find.text('Tài khoản'), findsOneWidget);
        expect(find.text('Bình luận'), findsOneWidget);
        expect(find.text('Thể loại'), findsOneWidget);
        expect(find.text('Thông báo'), findsOneWidget);

        await tester.tap(find.text('Tài khoản'));
        await tester.pump();
        expect(tappedIndex, 2);

        await tester.tap(find.text('Thông báo'));
        await tester.pump();
        expect(tappedIndex, 5);
      },
    );
  });
}

