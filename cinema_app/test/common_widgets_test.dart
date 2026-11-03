/// 8e — Widget test: SearchInput / CustomButton / LoadingSpinner /
/// ConfirmDialog / Pagination / RatingStars (bien). Kiem thu giao dien mobile.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/widgets/confirm_dialog.dart';
import 'package:cinema_app/widgets/custom_button.dart';
import 'package:cinema_app/widgets/loading_spinner.dart';
import 'package:cinema_app/widgets/pagination.dart';
import 'package:cinema_app/widgets/rating_stars.dart';
import 'package:cinema_app/widgets/search_input.dart';

void main() {
  group('SearchInput (8e: o tim kiem SearchPage)', () {
    testWidgets('hien hint + icon tim kiem', (t) async {
      final c = TextEditingController();
      addTearDown(c.dispose);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(body: SearchInput(controller: c, hintText: 'Tim phim...')),
      ));
      expect(find.text('Tim phim...'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('go text hien nut xoa, bam xoa goi onChanged rong', (t) async {
      final c = TextEditingController();
      addTearDown(c.dispose);
      String? last;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchInput(controller: c, onChanged: (v) => last = v),
        ),
      ));
      await t.enterText(find.byType(TextField), 'Chinh Kich');
      await t.pump();
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
      await t.tap(find.byIcon(Icons.clear_rounded));
      await t.pump();
      expect(c.text, '');
      expect(last, '');
    });

    testWidgets('khong text -> khong co nut xoa', (t) async {
      final c = TextEditingController();
      addTearDown(c.dispose);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(body: SearchInput(controller: c)),
      ));
      expect(find.byIcon(Icons.clear_rounded), findsNothing);
    });
  });

  group('CustomButton (8e)', () {
    testWidgets('hien label va goi onPressed', (t) async {
      var tapped = false;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomButton(label: 'Dang nhap', onPressed: () => tapped = true),
        ),
      ));
      expect(find.text('Dang nhap'), findsOneWidget);
      await t.tap(find.text('Dang nhap'));
      await t.pump();
      expect(tapped, isTrue);
    });

    testWidgets('loading -> hien spinner, vo hieu nut', (t) async {
      var tapped = false;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomButton(
            label: 'Dang nhap',
            loading: true,
            onPressed: () => tapped = true,
          ),
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await t.tap(find.byType(ElevatedButton));
      await t.pump();
      expect(tapped, isFalse);
    });
  });

  group('LoadingSpinner (8e)', () {
    testWidgets('co spinner, co/khong message', (t) async {
      await t.pumpWidget(const MaterialApp(
        home: Scaffold(body: LoadingSpinner()),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await t.pumpWidget(const MaterialApp(
        home: Scaffold(body: LoadingSpinner(message: 'Dang tai...')),
      ));
      expect(find.text('Dang tai...'), findsOneWidget);
    });
  });

  group('ConfirmDialog (8e: xoa / dang xuat)', () {
    testWidgets('bam Dong y -> true', (t) async {
      bool? res;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (ctx) {
            return ElevatedButton(
              onPressed: () async {
                res = await ConfirmDialog.show(ctx,
                    title: 'Xoa phim', message: 'Chac chan?');
              },
              child: const Text('Mo'),
            );
          }),
        ),
      ));
      await t.tap(find.text('Mo'));
      await t.pumpAndSettle();
      expect(find.text('Xoa phim'), findsOneWidget);
      await t.tap(find.text('Đồng ý'));
      await t.pumpAndSettle();
      expect(res, isTrue);
    });

    testWidgets('bam Huy -> false', (t) async {
      bool? res;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (ctx) {
            return ElevatedButton(
              onPressed: () async {
                res = await ConfirmDialog.show(ctx,
                    title: 'Xoa phim', message: 'Chac chan?');
              },
              child: const Text('Mo'),
            );
          }),
        ),
      ));
      await t.tap(find.text('Mo'));
      await t.pumpAndSettle();
      await t.tap(find.text('Hủy'));
      await t.pumpAndSettle();
      expect(res, isFalse);
    });
  });

  group('Pagination (8e: Category/Search)', () {
    testWidgets('1 trang -> an (SizedBox.shrink)', (t) async {
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Pagination(currentPage: 1, totalPages: 1, onChanged: (_) {}),
        ),
      ));
      expect(find.text('1 / 1'), findsNothing);
    });

    testWidgets('hien "2 / 5", next/prev goi dung trang', (t) async {
      int? got;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Pagination(
              currentPage: 2, totalPages: 5, onChanged: (p) => got = p),
        ),
      ));
      expect(find.text('2 / 5'), findsOneWidget);
      await t.tap(find.byIcon(Icons.chevron_right_rounded));
      await t.pump();
      expect(got, 3);
      await t.tap(find.byIcon(Icons.chevron_left_rounded));
      await t.pump();
      expect(got, 1);
    });

    testWidgets('trang dau -> nut prev vo hieu', (t) async {
      int? got;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Pagination(
              currentPage: 1, totalPages: 5, onChanged: (p) => got = p),
        ),
      ));
      await t.tap(find.byIcon(Icons.chevron_left_rounded));
      await t.pump();
      expect(got, isNull);
    });
  });

  group('RatingStars bien (8e)', () {
    testWidgets('score am / >10 bi clamp, khong crash', (t) async {
      await t.pumpWidget(const MaterialApp(
        home: Scaffold(body: RatingStars(score: -5)),
      ));
      expect(find.byType(RatingStars), findsOneWidget);
      await t.pumpWidget(const MaterialApp(
        home: Scaffold(body: RatingStars(score: 99)),
      ));
      expect(find.byType(RatingStars), findsOneWidget);
    });

    testWidgets('readOnly khong co GestureDetector', (t) async {
      await t.pumpWidget(const MaterialApp(
        home: Scaffold(body: RatingStars(score: 8, readOnly: true)),
      ));
      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}
