
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/widgets/rating_stars.dart';
import 'package:cinema_app/widgets/rating_modal.dart';

void main() {
  group('Kiểm thử đánh giá phim', () {
    testWidgets(
      'Hiển thị đúng 5 ngôi sao',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RatingStars(
                score: 8,
                readOnly: true,
              ),
            ),
          ),
        );

        expect(
          find.byIcon(Icons.star_border_rounded),
          findsNWidgets(5),
        );
      },
    );

    testWidgets(
      'Cho phép chọn nửa sao và nguyên sao',
      (WidgetTester tester) async {
        int? selectedScore;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RatingStars(
                score: 0,
                readOnly: false,
                size: 40,
                onChanged: (score) {
                  selectedScore = score;
                },
              ),
            ),
          ),
        );

        final stars =
            find.byIcon(Icons.star_border_rounded);

        // Chọn nửa trái của ngôi sao thứ ba:
        // tương đương 5/10 điểm.
        final thirdStar = tester.getRect(
          stars.at(2),
        );

        await tester.tapAt(
          Offset(
            thirdStar.left + 4,
            thirdStar.center.dy,
          ),
        );

        expect(selectedScore, 5);

        // Chọn nửa phải của ngôi sao thứ ba:
        // tương đương 6/10 điểm.
        await tester.tapAt(
          Offset(
            thirdStar.right - 4,
            thirdStar.center.dy,
          ),
        );

        expect(selectedScore, 6);
      },
    );

    testWidgets(
      'Modal gửi đúng điểm và nhận xét',
      (WidgetTester tester) async {
        int? savedScore;
        String? savedContent;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return RatingModal(
                            movieTitle: 'Phim kiểm thử',
                            onSubmit: (
                              score,
                              content,
                            ) async {
                              savedScore = score;
                              savedContent = content;
                            },
                          );
                        },
                      );
                    },
                    child: const Text('Mở đánh giá'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Mở đánh giá'));
        await tester.pumpAndSettle();

        expect(
          find.text('Đánh giá phim'),
          findsOneWidget,
        );

        final firstStar = tester.getRect(
          find.byIcon(
            Icons.star_border_rounded,
          ).first,
        );

        // Chọn 1/10 điểm
        await tester.tapAt(
          Offset(
            firstStar.left + 4,
            firstStar.center.dy,
          ),
        );

        await tester.enterText(
          find.byType(TextField),
          'Phim rất hay',
        );

        await tester.ensureVisible(
          find.text('Gửi đánh giá'),
        );

        await tester.tap(
          find.text('Gửi đánh giá'),
        );

        await tester.pumpAndSettle();

        expect(savedScore, 1);
        expect(savedContent, 'Phim rất hay');
      },
    );
  });
}
